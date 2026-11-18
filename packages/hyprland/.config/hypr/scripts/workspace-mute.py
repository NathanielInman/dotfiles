#!/usr/bin/env python3
"""Mute every app whose window sits on a muted workspace.

Agents launch games on a background workspace (10 by default) to take
screenshots and spawn things, and each launch plays the title music at full
volume. This daemon mutes the PipeWire stream of any window on a muted
workspace and unmutes it again when the window moves to another workspace.

    workspace-mute.py daemon        run the watcher (workspace-mute.service)
    workspace-mute.py toggle [WS]   mute or unmute WS (default: the focused one)
    workspace-mute.py status        list the muted workspaces

The muted set lives in ~/.local/state/workspace-mute/workspaces, one
workspace id or name per line; with no file it is "10". `toggle` rewrites
the file and sends SIGHUP so the daemon applies it at once.

A stream belongs to a window when the stream's process owns the window, or
when an ancestor running the same executable does (Chrome plays audio from a
child process of the one that owns its windows). A stream with no window yet
is left alone until its window maps.

WirePlumber remembers each app's mute and restores it on the app's next
launch. So a game that quits while muted on workspace 10 would open muted on
workspace 1 next time. The daemon records the apps it muted and unmutes
them when they show up on an unmuted workspace; it never touches a mute you
set yourself.
"""

import glob
import json
import os
import queue
import signal
import socket
import subprocess
import sys
import threading
import time

STATE_DIR = os.path.join(
    os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state")),
    "workspace-mute",
)
WORKSPACES_FILE = os.path.join(STATE_DIR, "workspaces")
APPS_FILE = os.path.join(STATE_DIR, "muted-apps.json")
DEFAULT_WORKSPACES = ["10"]
WINDOW_EVENTS = {"openwindow", "closewindow", "movewindow", "movewindowv2"}
SETTLE = 0.05  # seconds to gather a burst of events before acting


def log(msg):
    print(msg, flush=True)


# ---------------------------------------------------------------- state files

def read_workspaces():
    try:
        with open(WORKSPACES_FILE) as f:
            return [line.strip() for line in f if line.strip()]
    except FileNotFoundError:
        return list(DEFAULT_WORKSPACES)


def write_workspaces(names):
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(WORKSPACES_FILE, "w") as f:
        f.write("".join(n + "\n" for n in names))


def read_apps():
    try:
        with open(APPS_FILE) as f:
            return set(json.load(f))
    except (FileNotFoundError, ValueError):
        return set()


def write_apps(apps):
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(APPS_FILE, "w") as f:
        json.dump(sorted(apps), f)


# ------------------------------------------------------------------ Hyprland

def hypr_dir():
    """The newest Hyprland instance's socket dir. systemd services do not get
    HYPRLAND_INSTANCE_SIGNATURE, so find it on disk when it is missing."""
    runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if sig and os.path.exists(os.path.join(runtime, "hypr", sig, ".socket.sock")):
        return os.path.join(runtime, "hypr", sig)
    dirs = [d for d in glob.glob(os.path.join(runtime, "hypr", "*"))
            if os.path.exists(os.path.join(d, ".socket2.sock"))]
    if not dirs:
        raise RuntimeError("no Hyprland instance found")
    return max(dirs, key=os.path.getmtime)


def hypr_query(cmd):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(os.path.join(hypr_dir(), ".socket.sock"))
        s.sendall(f"j/{cmd}".encode())
        chunks = []
        while chunk := s.recv(65536):
            chunks.append(chunk)
    return json.loads(b"".join(chunks))


def window_workspaces():
    """pid -> set of workspace keys (id and name) its windows sit on."""
    out = {}
    for c in hypr_query("clients"):
        ws = c.get("workspace") or {}
        keys = out.setdefault(c["pid"], [])
        keys.append({str(ws.get("id")), str(ws.get("name"))})
    return out


def watch_hyprland(events):
    while True:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(os.path.join(hypr_dir(), ".socket2.sock"))
                events.put("hyprland connected")
                buf = b""
                while chunk := s.recv(4096):
                    buf += chunk
                    *lines, buf = buf.split(b"\n")
                    for line in lines:
                        if line.split(b">>", 1)[0].decode() in WINDOW_EVENTS:
                            events.put("window")
        except (OSError, RuntimeError) as e:
            log(f"hyprland socket: {e}; retrying")
        time.sleep(2)


# ------------------------------------------------------------------ PipeWire

def pactl_list(kind):
    out = subprocess.run(["pactl", "-f", "json", "list", kind],
                         capture_output=True, text=True, check=True).stdout
    return json.loads(out or "[]")


def stream_pid(stream, clients):
    """The process behind a stream. Pulse clients (Godot, Chrome) put their
    pid on the stream; native PipeWire clients (mpv) only put it on their
    client object."""
    for props in (stream.get("properties", {}),
                  clients.get(str(stream.get("client")), {})):
        for key in ("application.process.id", "pipewire.sec.pid"):
            try:
                pid = int(props.get(key, 0))
            except (TypeError, ValueError):
                pid = 0
            if pid > 1:
                return pid
    return 0


def set_mute(index, mute):
    subprocess.run(["pactl", "set-sink-input-mute", str(index), "1" if mute else "0"],
                   capture_output=True)


def watch_pulse(events):
    while True:
        try:
            p = subprocess.Popen(["pactl", "subscribe"], stdout=subprocess.PIPE, text=True)
            events.put("pulse connected")
            for line in p.stdout:
                if "sink-input" in line and ("'new'" in line or "'remove'" in line):
                    events.put("stream")
            p.wait()
        except OSError as e:
            log(f"pactl subscribe: {e}")
        time.sleep(2)


# -------------------------------------------------------------- the decision

def proc_exe(pid):
    try:
        return os.readlink(f"/proc/{pid}/exe")
    except OSError:
        return None


def proc_ppid(pid):
    try:
        with open(f"/proc/{pid}/stat") as f:
            return int(f.read().rsplit(")", 1)[1].split()[1])
    except (OSError, ValueError, IndexError):
        return 0


def owner_windows(pid, windows):
    """Workspace key sets of the windows that own a stream from `pid`, or None."""
    exe = proc_exe(pid)
    while pid > 1:
        if pid in windows:
            return windows[pid]
        pid = proc_ppid(pid)
        if exe is None or proc_exe(pid) != exe:
            return None
    return None


class Muter:
    def __init__(self):
        self.ours = set()          # stream indices this daemon muted
        self.apps = read_apps()    # app names whose restored mute is ours

    def reconcile(self):
        muted_ws = set(read_workspaces())
        windows = window_workspaces()
        streams = pactl_list("sink-inputs")
        clients = {str(c["index"]): c.get("properties", {}) for c in pactl_list("clients")}
        live = {s["index"] for s in streams}
        self.ours &= live
        apps_before = set(self.apps)

        for s in streams:
            app = s.get("properties", {}).get("application.name", "?")
            pid = stream_pid(s, clients)
            spots = owner_windows(pid, windows) if pid else None
            if spots is None:
                continue
            # A process with windows on several workspaces is muted only when
            # every one of them is on a muted workspace.
            wants_mute = all(keys & muted_ws for keys in spots)
            idx, muted = s["index"], s.get("mute", False)
            if wants_mute and not muted:
                set_mute(idx, True)
                self.ours.add(idx)
                self.apps.add(app)
                log(f"muted {app} (pid {pid}, stream {idx})")
            elif wants_mute:
                self.ours.add(idx)
            elif muted and (idx in self.ours or app in self.apps):
                set_mute(idx, False)
                self.ours.discard(idx)
                self.apps.discard(app)
                log(f"unmuted {app} (pid {pid}, stream {idx})")

        if self.apps != apps_before:
            write_apps(self.apps)


def daemon():
    events = queue.Queue()
    signal.signal(signal.SIGHUP, lambda *_: events.put("config"))
    threading.Thread(target=watch_hyprland, args=(events,), daemon=True).start()
    threading.Thread(target=watch_pulse, args=(events,), daemon=True).start()
    muter = Muter()
    log(f"muting workspaces: {', '.join(read_workspaces()) or 'none'}")
    while True:
        events.get()
        time.sleep(SETTLE)
        while not events.empty():
            events.get_nowait()
        try:
            muter.reconcile()
        except Exception as e:  # keep watching through a compositor/PipeWire restart
            log(f"reconcile failed: {e}")


# ----------------------------------------------------------------------- CLI

def notify(title, body):
    subprocess.run(["notify-send", "-a", "workspace-mute", "-u", "low",
                    "-i", "audio-volume-muted", title, body], capture_output=True)


def toggle(ws):
    if ws is None:
        ws = str(hypr_query("activeworkspace")["id"])
    names = read_workspaces()
    if ws in names:
        names.remove(ws)
        msg = f"Workspace {ws} plays sound again"
    else:
        names.append(ws)
        msg = f"Workspace {ws} is muted"
    write_workspaces(names)
    subprocess.run(["systemctl", "--user", "kill", "--kill-whom=main", "-s", "HUP",
                    "workspace-mute.service"],
                   capture_output=True)
    notify(msg, "Muted: " + (", ".join(names) or "none"))
    print(msg)


def main(argv):
    cmd = argv[1] if len(argv) > 1 else "status"
    if cmd == "daemon":
        daemon()
    elif cmd == "toggle":
        toggle(argv[2] if len(argv) > 2 else None)
    elif cmd == "status":
        print("muted workspaces: " + (", ".join(read_workspaces()) or "none"))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
