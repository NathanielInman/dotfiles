#!/usr/bin/env python3
"""Switch Hyprland workspaces when Slack or Discord tray icons are left-clicked.

Waybar's tray module calls org.kde.StatusNotifierItem.Activate without an
xdg_activation_v1 token, which native-Wayland Electron ignores (emitting no
Hyprland event at all). Monitoring Activate method calls on the session bus
lets Slack and Discord stay in the native tray -- keeping their unread dots
and right-click menus -- while left-clicking them jumps DP-2 to their
workspace.
"""

import glob
import json
import os
import socket
import subprocess
import time

# Lowercased StatusNotifierItem Id prefix -> Hyprland workspace id
TARGETS = {
    "slack": 2,
    "discord": 3,
}


def log(msg):
    print(msg, flush=True)


def hypr_dir():
    runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if sig and os.path.exists(os.path.join(runtime, "hypr", sig, ".socket.sock")):
        return os.path.join(runtime, "hypr", sig)
    dirs = [
        d for d in glob.glob(os.path.join(runtime, "hypr", "*"))
        if os.path.exists(os.path.join(d, ".socket.sock"))
    ]
    if not dirs:
        raise RuntimeError("no Hyprland instance found")
    return max(dirs, key=os.path.getmtime)


def focus_workspace(ws):
    cmd = f"dispatch hl.dsp.focus({{ workspace = {ws} }})"
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(os.path.join(hypr_dir(), ".socket.sock"))
        s.sendall(cmd.encode())
        resp = s.recv(4096).decode("utf-8", "replace").strip()
    if resp != "ok":
        log(f"hyprland dispatch ({cmd}): {resp}")


def sni_id(destination, path, cache):
    key = (destination, path)
    if key in cache:
        return cache[key]
    try:
        out = subprocess.run(
            [
                "busctl", "--user", "get-property",
                destination, path,
                "org.kde.StatusNotifierItem", "Id",
            ],
            capture_output=True, text=True, timeout=2, check=True,
        ).stdout.strip()
        # Format: s "Slack_status_icon_1"
        if out.startswith('s "') and out.endswith('"'):
            val = out[3:-1]
            cache[key] = val
            return val
    except (subprocess.SubprocessError, OSError):
        pass
    return None


def main():
    match = "type='method_call',interface='org.kde.StatusNotifierItem',member='Activate'"
    cache = {}
    while True:
        proc = None
        try:
            proc = subprocess.Popen(
                ["busctl", "--user", "monitor", "--json=short", "--match", match],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
            )
            log("watching StatusNotifierItem.Activate")
            for line in proc.stdout:
                line = line.strip()
                if not line.startswith("{"):
                    continue
                try:
                    msg = json.loads(line)
                except json.JSONDecodeError:
                    continue
                dest = msg.get("destination")
                obj_path = msg.get("path")
                if not dest or not obj_path:
                    continue
                item_id = sni_id(dest, obj_path, cache)
                if not item_id:
                    continue
                low = item_id.lower()
                for prefix, ws in TARGETS.items():
                    if low.startswith(prefix):
                        log(f"activate {item_id} -> workspace {ws}")
                        try:
                            focus_workspace(ws)
                        except (OSError, RuntimeError) as e:
                            log(f"focus_workspace({ws}): {e}")
                        break
            proc.wait()
        except OSError as e:
            log(f"busctl monitor: {e}")
        finally:
            if proc and proc.poll() is None:
                proc.terminate()
        cache.clear()
        time.sleep(2)


if __name__ == "__main__":
    main()
