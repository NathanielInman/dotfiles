#!/usr/bin/env python3
"""Renders moments of the hero (or a widget strip) to PNG with headless
Chrome, to check a change without watching the whole loop.

    python3 docs/bar/preview.py 2.5 8 19.8          # hero at those seconds
    python3 docs/bar/preview.py --svg Pictures/bar/widgets/pomodoro.svg 0 2

PNGs go to /tmp/bar-preview, or --out DIR.
"""

import argparse
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def chrome() -> str:
    for name in ("google-chrome-stable", "google-chrome", "chromium", "chromium-browser"):
        if shutil.which(name):
            return name
    raise SystemExit("preview.py needs Chrome or Chromium on PATH")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("times", nargs="+", type=float, help="seconds into the loop")
    ap.add_argument("--svg", default="Pictures/bar/hero.svg")
    ap.add_argument("--scale", type=float, default=1.0)
    ap.add_argument("--out", default="/tmp/bar-preview")
    args = ap.parse_args()
    src = (ROOT / args.svg).read_text(encoding="utf-8")
    head = src.split(">", 1)[0]
    w = float(head.split('width="')[1].split('"')[0])
    h = float(head.split('height="')[1].split('"')[0])
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    stem = Path(args.svg).stem
    # Chrome's lock socket must fit a short Unix socket path, so its profile
    # lives directly under /tmp.
    # Chrome keeps its sockets in TMPDIR and its profile lock in the profile;
    # both need short paths, so neither follows a long TMPDIR.
    env = {k: v for k, v in os.environ.items() if k != "TMPDIR"}
    with tempfile.TemporaryDirectory(dir="/tmp") as tmp:
        for t in args.times:
            # Freeze every animation at t seconds.
            frozen = src.replace(
                "</style>",
                f".a {{ animation-delay: -{t}s !important; animation-play-state: paused !important; }}\n</style>",
                1,
            )
            svg = Path(tmp) / f"{stem}-{t}.svg"
            svg.write_text(frozen, encoding="utf-8")
            png = out / f"{stem}-{t:05.1f}.png"
            # A fresh profile per frame: a reused one makes Chrome try to
            # restore the last session and hang.
            profile = tempfile.mkdtemp(prefix="bp-", dir="/tmp")
            subprocess.run(
                [chrome(), "--headless=new", "--disable-gpu", "--hide-scrollbars",
                 f"--user-data-dir={profile}",
                 f"--force-device-scale-factor={args.scale}", f"--window-size={int(w)},{int(h)}",
                 "--virtual-time-budget=3000", f"--screenshot={png}", svg.as_uri()],
                check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=env,
            )
            shutil.rmtree(profile, ignore_errors=True)
            print(png)


if __name__ == "__main__":
    main()
