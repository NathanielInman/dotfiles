#!/usr/bin/env python3

# Keeps the G9 dark after an Idle until real input arrives.
#
# The G9 runs in PBP with two DisplayPort inputs (DP-1 left, DP-2 right).
# Some time after dpms off it drops both links on the way into standby;
# Hyprland removes both monitors, adds a FALLBACK output, then re-adds
# whichever inputs relink. Re-added monitors come up with dpms on, so one
# or both halves light back up with nobody at the desk.
#
# Monitor state alone can't tell that apart from a real wake, so this runs a
# private hypridle (ext-idle-notify, 1s timeout) as the input signal:
#   - while idle, any lit monitor is a spurious wake: turn it back off
#   - a resume is real input and ends the guard, EXCEPT the one Hyprland
#     fakes within a few ms of a monitor add/remove; that one is ignored
#     unless idle fails to come back shortly after (someone really is there)
# It fails open: if hypridle or the event socket goes away, the guard exits
# and the screens behave as they would without it.

import json
import os
import select
import signal
import socket
import subprocess
import sys
import time

RUNTIME = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
PIDFILE = f"{RUNTIME}/idle-dpms-guard.pid"
CONF = f"{RUNTIME}/idle-dpms-guard.hypridle.conf"
HOTPLUG_WINDOW = 2.0   # a resume this soon after a monitor add/remove is suspect
IDLE_CONFIRM = 5.0     # a suspect resume must be followed by idle within this
MAX_FORCES = 30
MAX_HOURS = 16

state = {"idle": False, "resume": None, "hotplug": 0.0}


def on_idle(*_):
    state["idle"] = True
    state["resume"] = None


def on_resume(*_):
    state["idle"] = False
    state["resume"] = time.monotonic()


def hyprctl(*args):
    try:
        return subprocess.run(["hyprctl", *args], capture_output=True,
                              text=True, timeout=5).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def lit_monitors():
    try:
        mons = json.loads(hyprctl("monitors", "-j") or "[]")
    except ValueError:
        return []
    return [m["name"] for m in mons if m.get("dpmsStatus")]


def dpms_off(name):
    # Legacy keyword form first, then the lua-config (Hyprland 0.55+) form
    if hyprctl("dispatch", "dpms", "off", name) != "ok":
        hyprctl("dispatch", f'hl.dsp.dpms({{ action = "off", monitor = "{name}" }})')


def replace_previous():
    # Single instance: a new Idle replaces the previous guard. Verify the
    # stale pid is actually us before killing, in case the pid got recycled.
    try:
        old = int(open(PIDFILE).read())
        if b"idle-dpms-guard" in open(f"/proc/{old}/cmdline", "rb").read():
            os.kill(old, signal.SIGTERM)
    except (OSError, ValueError):
        pass
    with open(PIDFILE, "w") as f:
        f.write(str(os.getpid()))


def main():
    replace_previous()
    signal.signal(signal.SIGUSR1, on_idle)
    signal.signal(signal.SIGUSR2, on_resume)
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))

    pid = os.getpid()
    with open(CONF, "w") as f:
        f.write(f"""general {{
    ignore_dbus_inhibit = true
    ignore_systemd_inhibit = true
    inhibit_sleep = 0
}}
listener {{
    timeout = 1
    on-timeout = kill -USR1 {pid}
    on-resume = kill -USR2 {pid}
}}
""")
    idler = subprocess.Popen(["hypridle", "--config", CONF],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    events = socket.socket(socket.AF_UNIX)
    try:
        events.connect(f"{RUNTIME}/hypr/{sig}/.socket2.sock")
        buf = b""
        forces = 0
        deadline = time.monotonic() + MAX_HOURS * 3600
        while forces < MAX_FORCES and time.monotonic() < deadline:
            if idler.poll() is not None:
                return
            ready, _, _ = select.select([events], [], [], 0.5)
            now = time.monotonic()
            if ready:
                chunk = events.recv(65536)
                if not chunk:
                    return  # compositor gone
                buf += chunk
                *lines, buf = buf.split(b"\n")
                if any(l.startswith((b"monitoradded", b"monitorremoved")) for l in lines):
                    state["hotplug"] = now

            resume = state["resume"]
            if resume is not None:
                if resume - state["hotplug"] > HOTPLUG_WINDOW:
                    return  # real input
                if now - resume > IDLE_CONFIRM:
                    return  # faked resume, but nobody went idle again: someone's here
                continue

            # Only act once the links have settled and input is still idle
            # Grace beat so a real wake's dpms on can't beat its resume here
            if state["idle"] and now - state["hotplug"] > 1.0:
                lit = lit_monitors()
                if lit:
                    time.sleep(0.5)
                for name in lit:
                    if not state["idle"]:
                        break
                    dpms_off(name)
                    forces += 1
    finally:
        idler.terminate()
        events.close()
        try:
            if open(PIDFILE).read() == str(pid):
                os.remove(PIDFILE)
        except OSError:
            pass


if __name__ == "__main__":
    main()
