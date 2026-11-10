"""The panels the bar opens: Roundhouse's drawer and Switchyard's board,
drawn the way their own READMEs draw them (roundhouse/docs/assets/hero.py
and switchyard/docs/assets/hero.py), so the tour shows the real interfaces.

Each panel is drawn once in its own coordinates (the apps' size), then
scaled and placed above the module that opened it, and sprung open and shut
at the times the story gives. `hotspot()` says where a click on part of a
panel lands on screen, so story.py can click "board:storefront".
"""

import math
import random
from dataclasses import dataclass

from svgkit import (
    CAUTION, DARK, DIM, FG, FROST, GO, IDLE, PANEL, PANEL_LINE, STOP, TILE, TILE_LINE,
    Svg, at, fit, visible_points, width,
)

PULSE_CSS = (
    ".pulse { animation: pulse 1.4s ease-in-out infinite; }\n"
    "@keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: .35; } }\n"
    "@media (prefers-reduced-motion: reduce) { .pulse { animation: none !important; } }"
)

# The apps' own panel sizes.
DRAWER_W, DRAWER_H = 520, 516
BOARD_W, BOARD_H = 640, 352


@dataclass
class Place:
    """Where a panel sits on screen: its top-left, its scale, and the point
    it springs out of (the module that opened it)."""
    x: float
    y: float
    scale: float
    origin: tuple[float, float]

    def screen(self, lx: float, ly: float) -> tuple[float, float]:
        return (self.x + lx * self.scale, self.y + ly * self.scale)


def place(anchor_x: float, bar_y: float, screen_w: float, w: float, h: float, scale: float) -> Place:
    sw, sh = w * scale, h * scale
    x = min(max(anchor_x - sw / 2, 8), screen_w - 8 - sw)
    return Place(x, bar_y - 10 - sh, scale, (anchor_x, bar_y))


def spring(svg: Svg, opens: list[tuple[float, float]], p: Place, still: float) -> None:
    """Opens a group that springs out of the anchor for each (open, close)."""
    pts = [(0.0, "translateY(18px) scale(.05)")]
    for o, c in opens:
        pts += [
            (o, "translateY(18px) scale(.05)"), (o + 0.1, "translateY(8px) scale(.55)"),
            (o + 0.2, "translateY(2px) scale(.92)"), (o + 0.3, "translateY(-1px) scale(1.03)"),
            (o + 0.45, "translateY(0px) scale(.99)"), (o + 0.6, "translateY(0px) scale(1)"),
            (c, "translateY(0px) scale(1)"), (c + 0.3, "translateY(14px) scale(.4)"),
            (c + 0.31, "translateY(18px) scale(.05)"),
        ]
    move = svg.keyframes("transform", pts)
    show = svg.keyframes("opacity", visible_points([(o, c + 0.28) for o, c in opens], fade=0.12, loop=svg.loop))
    ox, oy = p.origin
    on = 1 if at(opens, still) else 0
    svg.add(f'<g class="a" style="animation-name:{move},{show};transform-origin:{ox:.1f}px {oy:.1f}px" opacity="{on}">')
    svg.add(f'<g transform="translate({p.x:.1f},{p.y:.1f}) scale({p.scale})">')


def end_spring(svg: Svg) -> None:
    svg.add("</g></g>")


def shown_during(svg: Svg, spans, still: float, fade=0.18):
    name = svg.keyframes("opacity", visible_points(spans, fade=fade, loop=svg.loop))
    svg.add(f'<g class="a" style="animation-name:{name}" opacity="{1 if at(spans, still) else 0}">')


def walk(n, base, amp, pull=0.12, lo=2, hi=98, seed=7):
    rnd = random.Random(seed)
    v, out = base, []
    for _ in range(n):
        v += (rnd.random() - 0.5) * amp + (base - v) * pull
        v = min(hi, max(lo, v))
        out.append(v)
    return out


def spark(svg: Svg, x, y, w, h, values, vmax, color=FROST):
    n = len(values)
    pts = [(x + i / (n - 1) * w, y + h - values[i] / vmax * (h - 2)) for i in range(n)]
    line = " ".join(f"{a:.1f},{b:.1f}" for a, b in pts)
    area = f"M{x},{y + h} L" + " L".join(f"{a:.1f},{b:.1f}" for a, b in pts) + f" L{x + w},{y + h} Z"
    svg.add(f'<path d="{area}" fill="{color}" fill-opacity=".14"/>')
    svg.add(f'<polyline points="{line}" fill="none" stroke="{color}" stroke-width="1.6" stroke-linejoin="round"/>')
    ex, ey = pts[-1]
    svg.add(f'<circle cx="{ex - 1:.1f}" cy="{ey:.1f}" r="2.6" fill="{color}"/>')


# ------------------------------------------------------------ Roundhouse

def drawer(svg: Svg, p: Place, opens, still, yard_phase_color=CAUTION):
    """Roundhouse's drawer while the lamp is red: memory is stalling and
    Switchyard holds android. Layout follows Roundhouse's hero."""
    w = DRAWER_W
    spring(svg, opens, p, still)
    svg.add(f'<rect width="{w}" height="{DRAWER_H}" rx="16" fill="{PANEL}" stroke="{PANEL_LINE}" filter="url(#shadow)"/>')
    # Header: the lamp, the host, the verdict chip.
    svg.add(f'<circle cx="24" cy="30" r="5" fill="{STOP}"/>')
    svg.text(40, 34, "FROSTYARCH", 15, FG, 700, extra=' letter-spacing="1.5"')
    svg.text(40, 53, "up 15h 11m · linux 7.2.14", 12, DIM)
    svg.add(f'<rect x="{w - 104}" y="20" width="88" height="24" rx="12" fill="{STOP}" fill-opacity=".16"/>')
    svg.text(w - 60, 36, "needs you", 12, STOP, 700, "middle")
    # Tabs, ending in the link to Switchyard's board.
    svg.add(f'<rect x="16" y="68" width="{w - 32}" height="34" rx="9" fill="{TILE}"/>')
    svg.add(f'<rect x="19" y="71" width="160" height="28" rx="7" fill="{FROST}"/>')
    svg.text(99, 90, "Machine", 13, DARK, 700, "middle")
    svg.text(260, 90, "Storage", 13, DIM, 700, "middle")
    svg.add(f'<circle cx="370" cy="85.5" r="3" fill="{yard_phase_color}"/>')
    svg.text(421, 90, "Switchyard", 13, DIM, 400, "middle")
    svg.text(474, 90, "↗", 13, DIM, 400, "middle")
    # Why the lamp is red, and what Switchyard is doing about it.
    svg.add(f'<rect x="16" y="112" width="{w - 32}" height="32" rx="10" fill="{STOP}" fill-opacity=".1" stroke="{STOP}" stroke-opacity=".4"/>')
    svg.text(28, 133, "everything is stalling on memory (22% of the last 10 s)", 12.5, FG)
    svg.add(f'<rect x="16" y="152" width="{w - 32}" height="32" rx="10" fill="{TILE}" stroke="{TILE_LINE}"/>')
    held = "Switchyard is holding android: Roundhouse says everything is stalling on memory"
    svg.text(28, 173, fit(held, 12.5, w - 56), 12.5, FG)
    # The tiles, as on the Machine tab.
    tw = (w - 40) / 2
    tiles = [
        (16, 192, "CPU · RYZEN 7 9800X3D", "71 / 95°C", GO, "64", "% · 5.2 GHz", walk(40, 62, 18, seed=3), None),
        (24 + tw, 192, "GPU · RTX 3080", "41 / 95°C", GO, "8", "% · 2.1 G / 10 G", walk(40, 10, 10, seed=5), None),
        (16, 292, "MEMORY", "SWAP 2.4 G", DIM, "58G", "/ 60 G", [30 + i * 1.6 + (i % 3) for i in range(40)], None),
        (24 + tw, 292, "PRESSURE", "SOME · 10 S", DIM, "22.4", "mem · cpu 1.8 · io 0.3", None, "memory is stalling"),
    ]
    for x, y, label, aside, aside_color, value, unit, values, note in tiles:
        svg.add(f'<rect x="{x:.1f}" y="{y}" width="{tw:.1f}" height="92" rx="10" fill="{TILE}" stroke="{TILE_LINE}"/>')
        # Letter spacing adds a pixel per character to both labels.
        room = tw - 34 - width(aside, 10.5, 700) - len(aside)
        label = fit(label, 10.5, room - len(label), 700)
        svg.text(x + 12, y + 20, label, 10.5, DIM, 700, extra=' letter-spacing="1"')
        svg.text(x + tw - 12, y + 20, aside, 10.5, aside_color, 700, "end", ' letter-spacing="1"')
        svg.text(x + 12, y + 50, value, 25, STOP if note else FG, 700)
        svg.text(x + 16 + width(value, 25, 700), y + 50, unit, 11.5, DIM)
        if values:
            spark(svg, x + 12, y + 58, tw - 24, 26, values, 100, FROST)
        if note:
            svg.text(x + 12, y + 74, note, 11.5, STOP)
    # Memory by app: the build's scope is what is eating it.
    svg.add(f'<rect x="16" y="392" width="{w - 32}" height="108" rx="10" fill="{TILE}" stroke="{TILE_LINE}"/>')
    svg.text(28, 412, "MEMORY BY APP", 10.5, DIM, 700, extra=' letter-spacing="1"')
    svg.text(w - 28, 412, "NOT BY PID", 10.5, DIM, 700, "end", ' letter-spacing="1"')
    for i, (name, detail, right, frac, color) in enumerate([
        ("storefront", "lowprio scope", "14.1 G / 16 G", 0.88, CAUTION),
        ("Chrome", "40 procs", "7.6 G", 0.13, FROST),
        ("T3Code", "14 procs", "1.5 G", 0.03, FROST),
    ]):
        y = 436 + i * 24
        svg.text(28, y, name, 12.5, FG)
        svg.text(36 + width(name, 12.5), y, detail, 12.5, DIM)
        svg.text(w - 28, y, right, 12.5, DIM, anchor="end")
        svg.add(f'<rect x="28" y="{y + 6}" width="{w - 56}" height="3" rx="1.5" fill="{TILE_LINE}"/>')
        svg.add(f'<rect x="28" y="{y + 6}" width="{max(4, (w - 56) * frac):.1f}" height="3" rx="1.5" fill="{color}"/>')
    end_spring(svg)


DRAWER_SPOTS = {"switchyard": (421, 85)}


# ------------------------------------------------------------ Switchyard

TW, TH = (BOARD_W - 24 - 3 * 10) / 4, 96
GX = [12 + i * (TW + 10) for i in range(4)]
GY = [96, 202]
BOARD_SPOTS = {"storefront": (GX[0] + TW / 2, GY[0] + TH / 2), "android": (GX[0] + TW / 2, GY[1] + TH / 2)}


def tile_frame(svg: Svg, x, y, letter, border=None, tint=None):
    svg.add(f'<rect x="{x:.1f}" y="{y}" width="{TW:.1f}" height="{TH}" rx="10" fill="{tint or TILE}" stroke="{border or TILE_LINE}"/>')
    svg.add(f'<rect x="{x + TW - 24:.1f}" y="{y + 10}" width="16" height="16" rx="4" fill="{CAUTION}"/>')
    svg.text(x + TW - 16, y + 22, letter, 11, DARK, 700, "middle")


def tile_text(svg: Svg, x, y, name, desc, status, color, dot, hollow=False, pulse=False):
    if hollow:
        svg.add(f'<circle cx="{x + 16:.1f}" cy="{y + 18}" r="4.5" fill="none" stroke="{dot}" stroke-width="2"/>')
    else:
        cls = ' class="pulse"' if pulse else ""
        svg.add(f'<circle{cls} cx="{x + 16:.1f}" cy="{y + 18}" r="5" fill="{dot}"/>')
    svg.text(x + 28, y + 23, name, 13, FG, 700)
    svg.text(x + 12, y + 46, desc, 12, DIM)
    svg.text(x + 12, y + 66, fit(status, 12, TW - 24), 12, color)


def progress(svg: Svg, x, y, w, frac_from, frac_to, t0, t1, color, still):
    svg.add(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="4" rx="2" fill="{TILE_LINE}"/>')
    k = svg.keyframes("transform", [(0, f"scaleX({frac_from})"), (t0, f"scaleX({frac_from})"), (t1, f"scaleX({frac_to})")])
    u = min(1.0, max(0.0, (still - t0) / (t1 - t0))) if t1 > t0 else 1.0
    base = frac_from + (frac_to - frac_from) * u
    svg.add(f'<rect class="a" style="animation-name:{k};transform-box:fill-box;transform-origin:left center" '
            f'transform="translate({x:.1f},0) scale({base:.3f},1) translate({-x:.1f},0)" '
            f'x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="4" rx="2" fill="{color}"/>')


@dataclass
class BoardTimes:
    """When things happen on the board, in loop seconds."""
    storefront_build: float
    android_queue: float
    android_held: float
    storefront_done: float
    android_build: float
    end: float


def board(svg: Svg, p: Place, opens, still, t: BoardTimes, lamp: dict[str, list[tuple[float, float]]]):
    """Switchyard's board: storefront builds on the main line, android queues
    behind it, Roundhouse holds android, then it starts. Layout follows
    Switchyard's hero. `lamp` gives the Roundhouse lamp's state intervals for
    the dot on the board's Roundhouse link."""
    w = BOARD_W
    spring(svg, opens, p, still)
    svg.add(f'<rect width="{w}" height="{BOARD_H}" rx="16" fill="{PANEL}" stroke="{PANEL_LINE}" filter="url(#shadow)"/>')
    # Tabs, then the link to Roundhouse dotted with its lamp, then the filter.
    svg.add(f'<rect x="12" y="13" width="108" height="28" rx="7" fill="#33373d"/>')
    svg.text(24, 32, "Projects", 13, FG)
    svg.text(96, 32, "8", 13, DIM)
    x = 136
    for label, n in [("Deploys", "4"), ("Desk", "1"), ("Shelf", "")]:
        svg.text(x, 32, label, 13, DIM)
        x += width(label, 13)
        if n:
            svg.text(x + 6, 32, n, 13, DIM)
            x += 6 + width(n, 13)
        x += 18
    for state, color in [("calm", GO), ("heads-up", CAUTION), ("act", STOP)]:
        spans = lamp.get(state, [])
        if spans:
            shown_during(svg, spans, still, fade=0.1)
            svg.add(f'<circle cx="{x + 3:.1f}" cy="27.5" r="3" fill="{color}"/>')
            svg.add("</g>")
    svg.text(x + 12, 32, "Roundhouse ↗", 13, DIM)
    svg.add(f'<rect x="{w - 128}" y="13" width="116" height="28" rx="8" fill="none" stroke="{PANEL_LINE}"/>')
    svg.text(w - 114, 32, "/  to filter", 13, DIM)

    # The main line strip.
    strips = [
        ((0.0, t.storefront_build), PANEL_LINE, IDLE, "Main line free", "12 GB cap"),
        ((t.storefront_build, t.android_queue), CAUTION, CAUTION, "Main line: storefront · next build", "3.1 of 12 GB"),
        ((t.android_queue, t.android_held), CAUTION, CAUTION, "Main line: storefront · next build", "3.1 of 12 GB · android waiting"),
        ((t.android_held, t.android_build), CAUTION, CAUTION, "Main line: storefront · next build", "android held by Roundhouse"),
        ((t.android_build, t.end), CAUTION, CAUTION, "Main line: android · assembleDebug", "5.8 of 12 GB"),
    ]
    for (a, b), line, dot, left, right in strips:
        shown_during(svg, [(a, b)], still)
        tint = f' fill="{CAUTION}" fill-opacity=".07"' if line == CAUTION else ' fill="none"'
        svg.add(f'<rect x="12" y="52" width="{w - 24}" height="32" rx="8"{tint} stroke="{line}" stroke-opacity=".5"/>')
        cls = ' class="pulse"' if dot == CAUTION else ""
        svg.add(f'<circle{cls} cx="28" cy="68" r="5" fill="{dot}"/>')
        svg.text(42, 73, left, 13, FG if dot == CAUTION else DIM)
        svg.text(w - 24, 73, right, 12.5, DIM, anchor="end")
        svg.add("</g>")

    # storefront: idle, building on the main line, then ok.
    x, y = GX[0], GY[0]
    shown_during(svg, [(0.0, t.storefront_build)], still)
    tile_frame(svg, x, y, "s")
    tile_text(svg, x, y, "storefront", "next build", "idle · ok 2h ago", DIM, IDLE)
    svg.add("</g>")
    shown_during(svg, [(t.storefront_build, t.storefront_done)], still)
    tile_frame(svg, x, y, "s", "#5c5440")
    tile_text(svg, x, y, "storefront", "next build", "build 2/2 · 0:48", CAUTION, CAUTION, pulse=True)
    progress(svg, x + 12, y + 78, TW - 24, 0.05, 1.0, t.storefront_build, t.storefront_done, CAUTION, still)
    svg.add("</g>")
    shown_during(svg, [(t.storefront_done, t.end)], still)
    tile_frame(svg, x, y, "s")
    tile_text(svg, x, y, "storefront", "next build", "ok · 2m 14s", GO, GO)
    svg.add("</g>")

    # The rest of the top row, as in Switchyard's hero.
    x, y = GX[1], GY[0]
    tile_frame(svg, x, y, "a")
    tile_text(svg, x, y, "ledger-api", "compose up", "idle · ok 1h ago", DIM, IDLE)
    x = GX[2]
    tile_frame(svg, x, y, "d", "#3f5b63")
    tile_text(svg, x, y, "api-gateway", "localhost:8080", "running · 1.2 G", FROST, FROST)
    pts = [(x + 12 + i * (TW - 24) / 19, y + 88 - (6 + 5 * math.sin(i * 0.7) + i * 0.25)) for i in range(20)]
    svg.add(f'<polyline points="{" ".join(f"{a:.1f},{b:.1f}" for a, b in pts)}" fill="none" stroke="{FROST}" stroke-width="1.4"/>')
    x = GX[3]
    tile_frame(svg, x, y, "f")
    tile_text(svg, x, y, "e2e-suite", "playwright", "ok · 1m 52s", GO, GO)

    # android: idle, queued behind storefront, held by Roundhouse, building.
    x, y = GX[0], GY[1]
    shown_during(svg, [(0.0, t.android_queue)], still)
    tile_frame(svg, x, y, "g")
    tile_text(svg, x, y, "android", "APK → emulator", "idle · ok 1d ago", DIM, IDLE)
    svg.add("</g>")
    shown_during(svg, [(t.android_queue, t.android_held)], still)
    tile_frame(svg, x, y, "g")
    tile_text(svg, x, y, "android", "APK → emulator", "queued · heavy", CAUTION, CAUTION, hollow=True)
    svg.add("</g>")
    shown_during(svg, [(t.android_held, t.android_build)], still)
    tile_frame(svg, x, y, "g", STOP, "#33292c")
    tile_text(svg, x, y, "android", "APK → emulator", "held: Roundhouse says act", STOP, STOP, hollow=True)
    svg.add("</g>")
    shown_during(svg, [(t.android_build, t.end)], still)
    tile_frame(svg, x, y, "g", "#5c5440")
    tile_text(svg, x, y, "android", "APK → emulator", "build 1/2 · 0:06", CAUTION, CAUTION, pulse=True)
    progress(svg, x + 12, y + 78, TW - 24, 0.0, 0.5, t.android_build, t.end, CAUTION, still)
    svg.add("</g>")
    for i, (name, desc, status, letter) in enumerate([
        ("docs-site", "hugo server", "idle · ok 2h ago", "h"),
        ("migrations", "staging db", "idle · ok 1d ago", "j"),
        ("load-test", "k6 · 500 users", "idle · 3d ago", "k"),
    ]):
        x, y = GX[i + 1], GY[1]
        tile_frame(svg, x, y, letter)
        tile_text(svg, x, y, name, desc, status, DIM, IDLE)

    svg.text(12, 330, "Recent", 12.5, DIM)
    cx = 72.0
    for chip in ["rotate wallpaper", "deploy staging", "tokei"]:
        cw = width(chip, 12) + 22
        svg.add(f'<rect x="{cx:.1f}" y="314" width="{cw:.1f}" height="24" rx="12" fill="none" stroke="{PANEL_LINE}"/>')
        svg.text(cx + cw / 2, 330, chip, 12, FG, anchor="middle")
        cx += cw + 8
    end_spring(svg)


# ------------------------------------------------------------ swaync

TOAST_W, TOAST_H = 360, 84
TOAST_DEFS = (
    '<linearGradient id="toastbg" x1="0" y1="0" x2="1" y2="0">'
    '<stop offset="0" stop-color="#445161"/><stop offset=".6" stop-color="#3b4252"/></linearGradient>'
)


def toast(svg: Svg, x: float, y: float, appear: float, dismiss: float, still: float):
    """A swaync notification card, as packages/swaync/.config/swaync/style.css
    draws the normal urgency: a frost accent on the left, the summary in
    frost, the body in snow."""
    move = svg.keyframes("transform", [
        (0.0, "translateX(48px)"), (appear, "translateX(48px)"), (appear + 0.25, "translateX(0px)"),
        (dismiss, "translateX(0px)"), (dismiss + 0.3, "translateX(64px)"),
    ])
    show = svg.keyframes("opacity", visible_points([(appear, dismiss + 0.15)], fade=0.2, loop=svg.loop))
    on = 1 if appear <= still < dismiss else 0
    svg.add(f'<g class="a" style="animation-name:{move},{show}" opacity="{on}">')
    svg.add(f'<g transform="translate({x:.1f},{y:.1f})">')
    svg.add(f'<rect width="{TOAST_W}" height="{TOAST_H}" rx="6" fill="url(#toastbg)" stroke="#5e81ac" filter="url(#shadow)"/>')
    svg.add(f'<path d="M6,0 h-2 a4,4 0 0 0 -4,4 v{TOAST_H - 8} a4,4 0 0 0 4,4 h2 Z" fill="{FROST}"/>')
    svg.add(f'<rect x="4" y="0" width="4" height="{TOAST_H}" fill="{FROST}"/>')
    # The app's icon.
    svg.add(f'<rect x="18" y="14" width="56" height="56" rx="12" fill="#2e3440"/>')
    svg.text(46, 54, "\uf198", 30, "#e01e5a", 400, "middle")
    svg.text(88, 34, "Slack \u00b7 #deploys", 14, FROST, 700)
    svg.text(88, 56, "storefront 4.2 is on staging", 13.5, "#d8dee9")
    svg.text(TOAST_W - 44, 34, "now", 12, "#5e81ac", 400, "end")
    svg.add(f'<rect x="{TOAST_W - 32}" y="14" width="20" height="20" rx="4" fill="#434c5e"/>')
    svg.text(TOAST_W - 22, 29, "\u00d7", 14, "#d8dee9", 400, "middle")
    svg.add("</g></g>")
