#!/usr/bin/env python3
"""Draws the README's waybar: an animated hero, one strip per widget, and the
widget table in the README.

    python3 docs/bar/build.py

Reads the real bar (packages/waybar/.config/waybar/config.jsonc for the
module order, style.css for the colors), widgets.py for what each module
shows, and story.py for the hero's timeline. Writes:

- Pictures/bar/hero.svg: the animated hero (pure CSS animation, so GitHub
  plays it in an <img>; reduced motion gets a still with the drawer open).
- Pictures/bar/widgets/<module>.svg: each widget cycling through its states.
- The table between the `bar-widgets` markers in README.md.

The glyphs come from a Nerd Font subset embedded in each SVG, so the icons
are the same ones waybar draws. BAR_FONT picks the font file; the default is
JetBrains Mono Nerd Font Propo (OFL). Needs fontTools.
"""

import base64
import io
import json
import math
import os
import re
import sys
from pathlib import Path

import logging

from fontTools import subset
from fontTools.ttLib import TTFont

logging.getLogger("fontTools.subset").setLevel(logging.ERROR)

sys.dont_write_bytecode = True  # no __pycache__ next to widgets.py and story.py

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))

from story import BEATS, DICTATED, LOOP, MOVE, ZOOM  # noqa: E402
from widgets import WIDGETS, Widget  # noqa: E402

WAYBAR = ROOT / "packages/waybar/.config/waybar"
OUT = ROOT / "Pictures/bar"
README = ROOT / "README.md"
FONT_PATH = Path(os.environ.get("BAR_FONT", "/usr/share/fonts/TTF/JetBrainsMonoNerdFontPropo-Regular.ttf"))
FONT_BOLD = Path(os.environ.get("BAR_FONT_BOLD", str(FONT_PATH).replace("-Regular", "-Bold")))

# The hero's canvas and the bar inside it. The real bar is 24px tall with an
# 18px font; this keeps that ratio at a size a README can show.
W, H = 1200, 600
FS = 15
BAR_H = 28
BAR_X, BAR_Y, BAR_W = 8, H - BAR_H - 8, W - 16
BAR_CY = BAR_Y + BAR_H / 2
PAD = 6
ZOOM_TY = H - 64  # where the bar's middle sits on screen while zoomed
STILL = 19.8  # the moment shown with reduced motion
T = LOOP

# Nord, as the desktop around the bar.
BG0, BG1 = "#14171c", "#0d0f12"
WIN, WIN_LINE, WIN_BAR = "#1d2025", "#353a42", "#262a30"
FG, DIM, FAINT = "#c5c8c6", "#7c838e", "#4c566a"
FROST, GO, CAUTION, STOP, VIOLET, ORANGE = "#88c0d0", "#a3be8c", "#ebcb8b", "#bf616a", "#b48ead", "#d08770"
PANEL, PANEL_LINE, TILE, TILE_LINE = "#25282c", "#41464e", "#2c2f34", "#363a40"


# ------------------------------------------------------------------ inputs

def load_jsonc(path: Path):
    """JSON with // comments and trailing commas."""
    out, i, s = [], 0, path.read_text(encoding="utf-8")
    in_str = False
    while i < len(s):
        c = s[i]
        if in_str:
            out.append(c)
            if c == "\\":
                out.append(s[i + 1])
                i += 1
            elif c == '"':
                in_str = False
        elif c == '"':
            in_str = True
            out.append(c)
        elif s.startswith("//", i):
            i = s.find("\n", i)
            if i < 0:
                break
            continue
        elif s.startswith("/*", i):
            i = s.find("*/", i) + 2
            continue
        else:
            out.append(c)
        i += 1
    text = re.sub(r",(\s*[}\]])", r"\1", "".join(out))
    data = json.loads(text)
    return data[0] if isinstance(data, list) else data


class Css:
    """Just enough of style.css to color modules the way waybar does."""

    def __init__(self, path: Path):
        text = re.sub(r"/\*.*?\*/", "", path.read_text(encoding="utf-8"), flags=re.S)
        self.rules = []
        for sel, body in re.findall(r"([^{}]+)\{([^}]*)\}", text):
            decls = {}
            for d in body.split(";"):
                if ":" in d:
                    k, v = d.split(":", 1)
                    decls[k.strip()] = v.strip()
            for s in sel.split(","):
                self.rules.append((s.strip(), decls))

    def get(self, selector: str, prop: str):
        found = None
        for s, d in self.rules:
            if s == selector and prop in d:
                found = d[prop]
        return found

    def color(self, css_id: str, cls: str | None) -> str:
        c = self.get(f"#{css_id}.{cls}", "color") if cls else None
        return c or self.get(f"#{css_id}", "color") or self.get("window#waybar", "color") or FG


def css_id(module: str) -> str:
    if module.startswith("hyprland/"):
        return module.split("/", 1)[1]
    return module.replace("/", "-")


CONFIG = load_jsonc(WAYBAR / "config.jsonc")
CSS = Css(WAYBAR / "style.css")
BAR_BG = CSS.get("window#waybar", "background") or "#282A2E"
SEP = "#4c566a"
HOVER = CSS.get("#workspaces button:hover", "background") or "#373B41"
ACTIVE_LINE = "#81a1c1"


# Waybar draws these from an emoji font; the Nerd Font has its own versions.
SUBST = {"\u23f3": "\U000f051f", "\u23fa": "\U000f044a"}


def shown(s: str) -> str:
    return "".join(SUBST.get(c, c) for c in s)


class Font:
    def __init__(self, path: Path):
        self.path = path
        f = TTFont(path)
        self.cmap = f.getBestCmap()
        self.hmtx = f["hmtx"].metrics
        self.upm = f["head"].unitsPerEm
        self.missing = set()

    def width(self, s: str, size: float) -> float:
        w = 0.0
        for ch in shown(s):
            g = self.cmap.get(ord(ch))
            if g is None:
                self.missing.add(ch)
                w += 0.6 * self.upm
            else:
                w += self.hmtx[g][0]
        return w * size / self.upm


REG = Font(FONT_PATH)
BOLD = Font(FONT_BOLD) if FONT_BOLD.exists() else REG


def subset_font(font: Font, chars: set[str]) -> str:
    opts = subset.Options()
    opts.flavor = "woff"
    opts.hinting = False
    opts.desubroutinize = True
    opts.name_IDs = [0, 1, 2, 3, 4, 5, 6, 13, 14]  # keep the copyright and license
    opts.notdef_outline = True
    s = subset.Subsetter(opts)
    s.populate(unicodes=sorted({ord(c) for c in chars if ord(c) in font.cmap}))
    f = TTFont(font.path)
    s.subset(f)
    buf = io.BytesIO()
    f.flavor = "woff"
    f.save(buf)
    return base64.b64encode(buf.getvalue()).decode()


# ------------------------------------------------------------------ drawing

def esc(s: str) -> str:
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def pct(t: float) -> str:
    return f"{max(0.0, min(100.0, t / T * 100)):.3f}%"


class Svg:
    def __init__(self, loop: float):
        self.loop = loop
        self.body: list[str] = []
        self.css: list[str] = []
        self.chars = {"bar": set(), "bold": set()}
        self.n = 0

    def add(self, s: str):
        self.body.append(s)

    def text(self, x, y, s, size=FS, fill=FG, weight=400, anchor="start", extra=""):
        s = shown(s)
        self.chars["bold" if weight >= 600 else "bar"].update(s)
        fam = "barb" if weight >= 600 else "bar"
        self.add(
            f'<text x="{x:.1f}" y="{y:.1f}" font-family="{fam}" font-size="{size}" fill="{fill}" '
            f'text-anchor="{anchor}"{extra}>{esc(s)}</text>'
        )

    def keyframes(self, prop: str, points: list[tuple[float, str]]) -> str:
        """Linear keyframes through (seconds, value) points; returns the name."""
        self.n += 1
        name = f"k{self.n}"
        pts = sorted(points, key=lambda p: p[0])
        if pts[0][0] > 0:
            pts.insert(0, (0.0, pts[0][1]))
        if pts[-1][0] < self.loop:
            pts.append((self.loop, pts[-1][1]))
        frames, last = [], -1.0
        for t, v in pts:
            t = max(t, last + 0.0005)  # strictly increasing
            last = t
            frames.append(f"{max(0.0, min(100.0, t / self.loop * 100)):.3f}% {{ {prop}: {v}; }}")
        self.css.append(f"@keyframes {name} {{ {' '.join(frames)} }}")
        return name

    def render(self, width, height, label, scale=1.0) -> str:
        fonts = []
        for fam, key, font in (("bar", "bar", REG), ("barb", "bold", BOLD)):
            if self.chars[key]:
                data = subset_font(font, self.chars[key] | {" "})
                fonts.append(f'@font-face {{ font-family: "{fam}"; src: url(data:font/woff;base64,{data}) format("woff"); }}')
        style = "\n".join(
            fonts
            + ['text { white-space: pre; font-variant-ligatures: none; font-feature-settings: "liga" 0, "calt" 0; }']
            + [f".a {{ animation-duration: {self.loop}s; animation-iteration-count: infinite; animation-timing-function: linear; }}"]
            + self.css
            + ["@media (prefers-reduced-motion: reduce) { .a { animation: none !important; } }"]
        )
        return (
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width * scale:.0f}" '
            f'height="{height * scale:.0f}" xml:space="preserve" role="img" aria-label="{esc(label)}">\n'
            "<!-- Generated by docs/bar/build.py. Glyphs: JetBrains Mono Nerd Font (SIL OFL 1.1). -->\n"
            f"<style>\n{style}\n</style>\n" + "\n".join(self.body) + "\n</svg>\n"
        )


def visible_points(intervals, fade=0.07, loop=T):
    """Opacity points for an element visible during the given intervals."""
    ivs = sorted(intervals)
    merged = []
    for a, b in ivs:
        if merged and a <= merged[-1][1] + 1e-6:
            merged[-1][1] = max(merged[-1][1], b)
        else:
            merged.append([a, b])
    pts = []
    on0 = any(a <= 0 for a, _ in merged)
    pts.append((0.0, "1" if on0 else "0"))
    for a, b in merged:
        if a > 0:
            pts += [(a, "0"), (a + fade, "1")]
        if b < loop:
            pts += [(b, "1"), (b + fade, "0")]
    return pts


def at(intervals, t):
    return any(a <= t < b for a, b in intervals)


# ------------------------------------------------------------------ the bar

class Mod:
    def __init__(self, name: str, widget: Widget):
        self.name = name
        self.w = widget
        self.css = css_id(name)
        self.border = name != "tray"

    def state_width(self, state: str) -> float:
        w = self.w
        if w.kind == "workspaces":
            return sum(REG.width(self.ws_icon(n), FS) + 2 * PAD for n, _ in w.items) + 1
        if w.kind == "window":
            return REG.width(w.items[0], FS) + 2 * PAD + 1
        if w.kind == "tray":
            return sum(REG.width(g, FS) for g, _ in w.items) + 8 * (len(w.items) - 1) + 2 * PAD
        frames = w.states[state].frames
        widest = max(REG.width(f, FS) for f in frames)
        return 0.0 if widest == 0 else widest + 2 * PAD + (1 if self.border else 0)

    def ws_icon(self, n: str) -> str:
        return CONFIG.get("hyprland/workspaces", {}).get("format-icons", {}).get(n, n)


def modules():
    left = CONFIG.get("modules-left", []) + CONFIG.get("modules-center", [])
    right = CONFIG.get("modules-right", [])
    missing = [m for m in left + right if m not in WIDGETS]
    if missing:
        sys.exit(
            "build.py: these modules are in config.jsonc but not in docs/bar/widgets.py:\n  "
            + "\n  ".join(missing)
            + "\nAdd an entry for each (name, what it does, its states), then run again."
        )
    return [Mod(m, WIDGETS[m]) for m in left], [Mod(m, WIDGETS[m]) for m in right]


LEFT, RIGHT = modules()
ALL = {m.name: m for m in LEFT + RIGHT}

# Each module's states over the loop.
CHANGES: dict[str, list[tuple[float, str]]] = {m: [(0.0, ALL[m].w.default)] for m in ALL}
for b in BEATS:
    for m, s in b.set.items():
        if m not in ALL:
            sys.exit(f"story.py: beat at {b.t}s sets {m}, which is not in the bar")
        if s not in ALL[m].w.states:
            sys.exit(f"story.py: beat at {b.t}s sets {m} to {s!r}; widgets.py has {list(ALL[m].w.states)}")
        CHANGES[m].append((b.t, s))
for m, ch in CHANGES.items():
    ch.sort()
    if ALL[m].w.states and ch[-1][1] != ALL[m].w.default:
        sys.exit(f"story.py: {m} ends the loop as {ch[-1][1]!r}; set it back to {ALL[m].w.default!r}")


def state_at(m: str, t: float) -> str:
    s = CHANGES[m][0][1]
    for when, st in CHANGES[m]:
        if when <= t + 1e-9:
            s = st
    return s


def segments(m: str):
    ch = CHANGES[m]
    out = []
    for i, (a, s) in enumerate(ch):
        b = ch[i + 1][0] if i + 1 < len(ch) else T
        if b > a:
            out.append((a, b, s))
    return out


def layout(t: float) -> dict[str, tuple[float, float]]:
    pos = {}
    x = BAR_X
    for m in LEFT:
        w = m.state_width(state_at(m.name, t))
        pos[m.name] = (x, w)
        x += w
    x = BAR_X + BAR_W
    for m in reversed(RIGHT):
        w = m.state_width(state_at(m.name, t))
        x -= w
        pos[m.name] = (x, w)
    return pos


TIMES = sorted({0.0} | {t for ch in CHANGES.values() for t, _ in ch})


def center(m: str, t: float) -> float:
    x, w = layout(t)[m]
    return x + w / 2


# ------------------------------------------------------------------ camera

def ease(u: float) -> float:
    return u * u * (3 - 2 * u)


def cam_target(zoom: float, focus: str | None, t: float):
    if focus is None or zoom <= 1.0:
        return (1.0, W / 2, BAR_CY)
    half = W / (2 * zoom)
    fx = min(max(center(focus, t), BAR_X + half), BAR_X + BAR_W - half)
    return (zoom, fx, ZOOM_TY)


CAM_MOVES = [(0.0, (1.0, W / 2, BAR_CY))]
for b in BEATS:
    if b.camera:
        CAM_MOVES.append((b.t, cam_target(b.camera[0], b.camera[1], b.t + MOVE)))


def cam_at(t: float):
    cur = CAM_MOVES[0][1]
    for start, target in CAM_MOVES[1:]:
        if t < start:
            break
        u = min(1.0, (t - start) / MOVE)
        k = ease(u)
        cur = tuple(c + (g - c) * k for c, g in zip(cur, target))
        if u < 1.0:
            return cur
    return cur


def cam_transform(c) -> tuple[float, float, float]:
    z, fx, ty = c
    return (W / 2 - fx * z, ty - BAR_CY * z, z)


def to_screen(x: float, y: float, t: float):
    tx, ty, z = cam_transform(cam_at(t))
    return (x * z + tx, y * z + ty)


# ------------------------------------------------------------------ pieces

def draw_module_states(svg: Svg, m: Mod, x0: float, y0: float, timeline=None, loop=T, still=STILL, border=True):
    """The module's text for each state (and frame), shown when it is active.
    Coordinates are relative to the module's left edge."""
    w = m.w
    base_y = y0 + BAR_H / 2 + FS * 0.36
    segs = timeline if timeline is not None else segments(m.name)
    for state, st in w.states.items():
        mine = [(a, b) for a, b, s in segs if s == state]
        if not mine or not any(f for f in st.frames):
            continue
        color = CSS.color(m.css, st.cls)
        width = m.state_width(state)
        for i, frame in enumerate(st.frames):
            if len(st.frames) == 1:
                ivs = mine
            else:
                ivs = []
                for a, b in mine:
                    k = 0
                    while a + k * st.every < b:
                        if k % len(st.frames) == i:
                            ivs.append((a + k * st.every, min(b, a + (k + 1) * st.every)))
                        k += 1
            if not ivs:
                continue
            static = len(segs) == 1 and len(st.frames) == 1
            if static:
                svg.add("<g>")
            else:
                name = svg.keyframes("opacity", visible_points(ivs, loop=loop))
                svg.add(f'<g class="a" style="animation-name:{name}" opacity="{1 if at(ivs, still) else 0}">')
            svg.text(x0 + PAD, base_y, frame, FS, color)
            if border and m.border:
                svg.add(f'<rect x="{x0 + width - 1:.1f}" y="{y0}" width="1" height="{BAR_H}" fill="{SEP}"/>')
            svg.add("</g>")


def draw_bar(svg: Svg, clicks: list[tuple[float, str]]):
    svg.add(f'<rect x="{BAR_X}" y="{BAR_Y}" width="{BAR_W}" height="{BAR_H}" rx="6" fill="{BAR_BG}"/>')
    base_y = BAR_Y + BAR_H / 2 + FS * 0.36
    for m in LEFT + RIGHT:
        xs = [(t, layout(t)[m.name][0]) for t in TIMES]
        moving = len({round(x, 2) for _, x in xs}) > 1
        x_still = layout(STILL)[m.name][0]
        if moving:
            pts = []
            for i, (t, x) in enumerate(xs):
                if i:
                    pts.append((t, f"translate({xs[i - 1][1]:.1f}px, 0px)"))
                pts.append((t + (0.08 if i else 0), f"translate({x:.1f}px, 0px)"))
            name = svg.keyframes("transform", pts)
            svg.add(f'<g class="a" style="animation-name:{name}" transform="translate({x_still:.1f} 0)">')
        else:
            svg.add(f'<g transform="translate({xs[0][1]:.1f} 0)">')
        # Hover highlight around each click on this module.
        for t, target in clicks:
            if target == m.name:
                w = layout(t - 0.01)[m.name][1]
                name = svg.keyframes("opacity", visible_points([(t - 0.4, t + 0.45)], fade=0.12))
                svg.add(f'<rect class="a" style="animation-name:{name}" opacity="0" x="0" y="{BAR_Y}" width="{w:.1f}" height="{BAR_H}" fill="{HOVER}"/>')
        kind = m.w.kind
        if kind == "workspaces":
            x = 0.0
            for n, active in m.w.items:
                icon = m.ws_icon(n)
                bw = REG.width(icon, FS) + 2 * PAD
                svg.text(x + PAD, base_y, icon, FS, FG)
                if active:
                    svg.add(f'<rect x="{x:.1f}" y="{BAR_Y + BAR_H - 3}" width="{bw:.1f}" height="3" fill="{ACTIVE_LINE}"/>')
                x += bw
            svg.add(f'<rect x="{x:.1f}" y="{BAR_Y}" width="1" height="{BAR_H}" fill="{SEP}"/>')
        elif kind == "window":
            title = m.w.items[0]
            svg.text(PAD, base_y, title, FS, CSS.color("window", None))
            svg.add(f'<rect x="{REG.width(title, FS) + 2 * PAD:.1f}" y="{BAR_Y}" width="1" height="{BAR_H}" fill="{SEP}"/>')
        elif kind == "tray":
            x = PAD
            for g, color in m.w.items:
                svg.text(x, base_y, g, FS, color)
                x += REG.width(g, FS) + 8
        else:
            draw_module_states(svg, m, 0.0, BAR_Y)
        svg.add("</g>")


def code_line(svg: Svg, x, y, parts):
    for s, color in parts:
        svg.text(x, y, s, 13, color)
        x += REG.width(s, 13)


def draw_desktop(svg: Svg, typing: tuple[float, float] | None):
    svg.add(f'<rect width="{W}" height="{H}" fill="url(#bg)"/>')
    svg.add(f'<rect width="{W}" height="{H}" fill="url(#haze)"/>')
    # The editor, where dictation lands.
    ex, ey, ew, eh = 36, 30, 700, 488
    svg.add(f'<rect x="{ex}" y="{ey}" width="{ew}" height="{eh}" rx="10" fill="{WIN}" stroke="{WIN_LINE}"/>')
    svg.add(f'<path d="M{ex},{ey + 10} a10,10 0 0 1 10,-10 h{ew - 20} a10,10 0 0 1 10,10 v18 h-{ew} Z" fill="{WIN_BAR}"/>')
    svg.text(ex + 14, ey + 19, "src/retry.ts", 12, DIM)
    K, S, N, F, C = VIOLET, GO, ORANGE, FROST, FAINT
    lines = [
        [("import", K), (" { sleep } ", FG), ("from", K), (' "./time"', S), (";", FG)],
        [],
        [("export async function", K), (" retry", F), ("<T>(", FG)],
        [("  run: () => Promise<T>,", FG)],
        [("  tries = ", FG), ("5", N), (",", FG)],
        [("): Promise<T> {", FG)],
        None,  # dictation lands here
        [("  for", K), (" (let i = ", FG), ("0", N), ("; ; i++) {", FG)],
        [("    try", K), (" {", FG)],
        [("      return await", K), (" run();", FG)],
        [("    } ", FG), ("catch", K), (" (err) {", FG)],
        [("      if", K), (" (i + ", FG), ("1", N), (" >= tries) ", FG), ("throw", K), (" err;", FG)],
        [("      await", K), (" sleep(", FG), ("2", N), (" ** i * ", FG), ("250", N), (");", FG)],
        [("    }", FG)],
        [("  }", FG)],
        [("}", FG)],
    ]
    y = ey + 58
    for i, parts in enumerate(lines):
        svg.text(ex + 22, y, f"{i + 1:>2}", 13, C)
        if parts is None:
            if typing:
                t0, t1 = typing
                full = REG.width("  " + DICTATED, 13)
                svg.add('<clipPath id="typed"><rect class="a" style="animation-name:'
                        + svg.keyframes("width", [(0, "0px"), (t0, "0px"), (t1, f"{full:.0f}px"), (T - 2.4, f"{full:.0f}px"), (T - 2.2, "0px")])
                        + f'" x="{ex + 56}" y="{y - 14}" width="{full if t1 <= STILL else 0:.0f}" height="20"/></clipPath>')
                svg.add('<g clip-path="url(#typed)">')
                svg.text(ex + 56, y, "  " + DICTATED, 13, DIM)
                svg.add("</g>")
        elif parts:
            code_line(svg, ex + 56, y, parts)
        y += 24
    # A terminal beside it.
    tx, ty, tw, th = 760, 70, 400, 300
    svg.add(f'<rect x="{tx}" y="{ty}" width="{tw}" height="{th}" rx="10" fill="{WIN}" stroke="{WIN_LINE}"/>')
    svg.add(f'<path d="M{tx},{ty + 10} a10,10 0 0 1 10,-10 h{tw - 20} a10,10 0 0 1 10,10 v18 h-{tw} Z" fill="{WIN_BAR}"/>')
    svg.text(tx + 14, ty + 19, "kitty", 12, DIM)
    rows = [
        [("~/Sites/ledger", F), (" main ", VIOLET), ("❯", GO), (" pnpm test retry", FG)],
        [(" ✓ ", GO), ("retries five times", DIM)],
        [(" ✓ ", GO), ("backs off 250, 500, 1000 ms", DIM)],
        [(" ✓ ", GO), ("rethrows the last error", DIM)],
        [],
        [("Tests  ", DIM), ("3 passed", GO), (" (3)", DIM)],
        [],
        [("~/Sites/ledger", F), (" main ", VIOLET), ("❯", GO)],
    ]
    y = ty + 54
    for parts in rows:
        code_line(svg, tx + 16, y, parts)
        y += 24


def draw_drawer(svg: Svg, t_open: float, t_close: float):
    """Roundhouse's drawer over the lamp, with the reason it is red."""
    lamp_x = center("custom/roundhouse", t_open)
    dw, dh = 440, 214
    dx = min(max(lamp_x - dw / 2, BAR_X + 8), BAR_X + BAR_W - dw - 8)
    dy = BAR_Y - 10 - dh
    spring = svg.keyframes("transform", [
        (0, "translateY(18px) scale(.05)"), (t_open, "translateY(18px) scale(.05)"),
        (t_open + 0.1, "translateY(8px) scale(.55)"), (t_open + 0.2, "translateY(2px) scale(.92)"),
        (t_open + 0.3, "translateY(-1px) scale(1.03)"), (t_open + 0.45, "translateY(0px) scale(.99)"),
        (t_open + 0.6, "translateY(0px) scale(1)"), (t_close, "translateY(0px) scale(1)"),
        (t_close + 0.3, "translateY(14px) scale(.4)"),
    ])
    show = svg.keyframes("opacity", visible_points([(t_open, t_close + 0.25)], fade=0.12))
    still = 1 if t_open <= STILL < t_close else 0
    svg.add(f'<g class="a" style="animation-name:{spring},{show};transform-origin:{lamp_x:.1f}px {BAR_Y}px" opacity="{still}">')
    svg.add(f'<g transform="translate({dx:.1f},{dy:.1f})">')
    svg.add(f'<rect width="{dw}" height="{dh}" rx="14" fill="{PANEL}" stroke="{PANEL_LINE}" filter="url(#shadow)"/>')
    svg.add(f'<circle cx="22" cy="26" r="5" fill="{STOP}"/>')
    svg.text(36, 31, "FROSTYARCH", 14, FG, 700, extra=' letter-spacing="1.5"')
    svg.add(f'<rect x="{dw - 98}" y="15" width="82" height="22" rx="11" fill="{STOP}" fill-opacity=".16"/>')
    svg.text(dw - 57, 30, "needs you", 12, STOP, 700, "middle")
    svg.add(f'<rect x="14" y="48" width="{dw - 28}" height="28" rx="8" fill="{TILE}"/>')
    svg.add(f'<rect x="17" y="51" width="128" height="22" rx="6" fill="{FROST}"/>')
    svg.text(81, 66.5, "Machine", 12, "#1d2024", 700, "middle")
    svg.text(210, 66.5, "Storage", 12, DIM, 700, "middle")
    svg.add(f'<circle cx="{dw - 132}" cy="62" r="2.6" fill="{FROST}"/>')
    svg.text(dw - 122, 66.5, "Switchyard ↗", 12, DIM)
    svg.add(f'<rect x="14" y="86" width="{dw - 28}" height="30" rx="8" fill="{STOP}" fill-opacity=".1" stroke="{STOP}" stroke-opacity=".4"/>')
    svg.text(26, 106, "everything is stalling on memory (22% of the last 10 s)", 12, FG)
    svg.add(f'<rect x="14" y="124" width="{dw - 28}" height="30" rx="8" fill="{TILE}" stroke="{TILE_LINE}"/>')
    svg.text(26, 144, "Switchyard is holding android: Roundhouse says ev…", 12, FG)
    tw = (dw - 36) / 2
    for i, (label, aside, aside_color, value) in enumerate([
        ("CPU", "71 / 95°C", GO, "64%"),
        ("MEMORY", "SWAP 2 G", DIM, "58G / 60 G"),
    ]):
        x = 14 + i * (tw + 8)
        svg.add(f'<rect x="{x:.1f}" y="162" width="{tw:.1f}" height="40" rx="8" fill="{TILE}" stroke="{TILE_LINE}"/>')
        svg.text(x + 10, 178, label, 10, DIM, 700, extra=' letter-spacing="1"')
        svg.text(x + tw - 10, 178, aside, 10, aside_color, 700, "end")
        svg.text(x + 10, 195, value, 13, FG, 700)
    svg.add("</g></g>")


def draw_caption(svg: Svg, captions):
    """Zoomed in, a title card in the dimmed space above the bar; zoomed out,
    a small pill at the top so the desktop stays visible."""
    for i, (t, name, words) in enumerate(captions):
        end = captions[i + 1][0] if i + 1 < len(captions) else T
        end = min(end, t + 4.2)
        vis = svg.keyframes("opacity", visible_points([(t, end)], fade=0.25))
        svg.add(f'<g class="a" style="animation-name:{vis}" opacity="{1 if t <= STILL < end else 0}">')
        z = cam_at(t + 0.3)[0]
        if z > 1.9:
            bar_top = ZOOM_TY - BAR_H * z / 2
            cy = bar_top / 2 + 10
            svg.text(W / 2, cy - 8, name, 34, FROST, 700, "middle")
            svg.text(W / 2, cy + 30, words, 20, FG, 400, "middle")
        else:
            label = f"{name}  "
            width = BOLD.width(label, 15) + REG.width(words, 15) + 36
            x0 = (W - width) / 2
            svg.add(f'<rect x="{x0:.1f}" y="18" width="{width:.1f}" height="36" rx="18" fill="#101216" fill-opacity=".86" stroke="#3b4048"/>')
            svg.text(x0 + 18, 41, label, 15, FROST, 700)
            svg.text(x0 + 18 + BOLD.width(label, 15), 41, words, 15, FG)
        svg.add("</g>")


def hero() -> str:
    svg = Svg(T)
    clicks_mod, clicks_all, captions, scenes = [], [], [], {}
    for b in BEATS:
        if isinstance(b.click, str):
            clicks_mod.append((b.t, b.click))
            x, w = layout(b.t - 0.01)[b.click]
            clicks_all.append((b.t, to_screen(x + w / 2, BAR_CY, b.t)))
        elif b.click:
            clicks_all.append((b.t, b.click))
        if b.caption:
            captions.append((b.t, *b.caption))
        if b.scene:
            scenes[b.scene] = b.t

    svg.add('<defs>'
            f'<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{BG0}"/><stop offset="1" stop-color="{BG1}"/></linearGradient>'
            '<radialGradient id="haze" cx=".85" cy=".1" r=".7"><stop offset="0" stop-color="#88c0d0" stop-opacity=".08"/><stop offset="1" stop-color="#88c0d0" stop-opacity="0"/></radialGradient>'
            '<radialGradient id="warm" cx=".5" cy=".2" r=".9"><stop offset="0" stop-color="#ffd8a8" stop-opacity=".13"/><stop offset="1" stop-color="#ffd8a8" stop-opacity=".02"/></radialGradient>'
            '<filter id="shadow" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="10" stdDeviation="14" flood-color="#000" flood-opacity=".5"/></filter>'
            "</defs>")

    # Behind everything, for the edges the zoomed desktop does not cover.
    svg.add(f'<rect width="{W}" height="{H}" fill="{BG1}"/>')
    # Everything the camera moves.
    pts = []
    samples = sorted({0.0, T} | {s + MOVE * k / 10 for s, _ in CAM_MOVES[1:] for k in range(11)})
    for t in samples:
        tx, ty, z = cam_transform(cam_at(t))
        pts.append((t, f"translate({tx:.2f}px, {ty:.2f}px) scale({z:.4f})"))
    cam = svg.keyframes("transform", pts)
    svg.add(f'<g class="a" style="animation-name:{cam};transform-origin:0 0">')
    typing = (scenes["type"], scenes["type"] + 1.4) if "type" in scenes else None
    draw_desktop(svg, typing)
    # The desktop dims as the camera closes in on the bar.
    dim = svg.keyframes("opacity", [(t, f"{0.72 * (cam_at(t)[0] - 1) / (ZOOM - 1):.3f}") for t in samples])
    svg.add(f'<rect class="a" style="animation-name:{dim}" opacity="0" x="-{W}" y="-{H}" width="{3 * W}" height="{2 * H + BAR_Y - 6}" fill="{BG1}"/>')
    draw_bar(svg, clicks_mod)
    if "drawer-open" in scenes:
        draw_drawer(svg, scenes["drawer-open"], scenes.get("drawer-close", T - 1))
    svg.add("</g>")

    # The room lights up with the key lights.
    if "lights-on" in scenes:
        on, off = scenes["lights-on"], scenes.get("lights-off", T - 1)
        name = svg.keyframes("opacity", visible_points([(on, off)], fade=0.5))
        svg.add(f'<rect class="a" style="animation-name:{name}" opacity="0" width="{W}" height="{H}" fill="url(#warm)"/>')

    draw_caption(svg, captions)

    # The cursor and its clicks, in screen space.
    rest = (W * 0.66, H * 0.42)
    cpts = [(0.0, rest)]
    for t, p in clicks_all:
        cpts += [(t - 0.5, p), (t + 0.3, p)]
    cpts.append((T - 0.6, rest))
    name = svg.keyframes("transform", [(t, f"translate({x:.1f}px, {y:.1f}px)") for t, (x, y) in cpts])
    for i, (t, (x, y)) in enumerate(clicks_all):
        rip = svg.keyframes("transform", [(0, "scale(.3)"), (t, "scale(.3)"), (t + 0.45, "scale(1.7)"), (t + 0.46, "scale(.3)")])
        op = svg.keyframes("opacity", [(0, "0"), (t - 0.01, "0"), (t, ".9"), (t + 0.45, "0")])
        svg.add(f'<circle class="a" style="animation-name:{rip},{op};transform-box:fill-box;transform-origin:center" opacity="0" cx="{x:.1f}" cy="{y:.1f}" r="16" fill="none" stroke="{FROST}" stroke-width="2.5"/>')
    sx, sy = next((p for t, p in reversed(cpts) if t <= STILL), rest)
    svg.add(f'<g class="a" style="animation-name:{name}" transform="translate({sx:.1f} {sy:.1f})">'
            '<path d="M0,0 L0,22 L6,17 L10,26 L14,24 L10,15 L18,15 Z" fill="#eceff4" stroke="#1d2024" stroke-width="1.4" stroke-linejoin="round"/></g>')

    label = ("A Hyprland desktop with a waybar along the bottom. The view zooms into the bar and visits its widgets: "
             "a pomodoro timer starts, do not disturb turns on and the song title hides itself, a meeting recorder lights up, "
             "dictation types a comment into the editor, a build turns the Switchyard signal amber, the Roundhouse lamp turns red "
             "and its drawer explains that memory is stalling, the key lights warm the room, and the clock switches time zones.")
    return svg.render(W, H, label)


# ------------------------------------------------------------------ strips

STRIP_STEP = 1.6


def strip(m: Mod):
    states = [s for s, st in m.w.states.items() if any(st.frames)]
    if not states:
        return None
    loop = STRIP_STEP * len(states) if len(states) > 1 else T
    timeline = [(i * STRIP_STEP, (i + 1) * STRIP_STEP, s) for i, s in enumerate(states)] if len(states) > 1 else [(0.0, loop, states[0])]
    width = max(m.state_width(s) for s in states) - 1 + 2 * PAD
    height = BAR_H + 8
    svg = Svg(loop)
    svg.add(f'<rect width="{width:.1f}" height="{height}" rx="7" fill="{BAR_BG}"/>')
    draw_module_states(svg, m, PAD, 4, timeline=timeline, loop=loop, still=0.0, border=False)
    return svg.render(round(width, 1), height, f"{m.w.name}: " + ", ".join(states), scale=1.5)


def write_table():
    rows = ["| | Widget | What it does |", "|---|---|---|"]
    for m in RIGHT:
        if m.w.kind != "custom":
            continue
        slug = m.name.split("/")[-1]
        rows.append(
            f'| <img src="Pictures/bar/widgets/{slug}.svg" height="36" alt="{esc(m.w.name)}"> '
            f"| [{m.w.name}]({m.w.source}) | {m.w.what} |"
        )
    text = README.read_text(encoding="utf-8")
    start, end = "<!-- bar-widgets:start -->", "<!-- bar-widgets:end -->"
    if start not in text or end not in text:
        print(f"README.md has no {start} / {end} markers; skipped the table")
        return
    a, b = text.index(start) + len(start), text.index(end)
    README.write_text(text[:a] + "\n" + "\n".join(rows) + "\n" + text[b:], encoding="utf-8")


def main():
    (OUT / "widgets").mkdir(parents=True, exist_ok=True)
    (OUT / "hero.svg").write_text(hero(), encoding="utf-8")
    keep = set()
    for m in RIGHT:
        if m.w.kind != "custom":
            continue
        s = strip(m)
        if s:
            slug = m.name.split("/")[-1]
            keep.add(f"{slug}.svg")
            (OUT / "widgets" / f"{slug}.svg").write_text(s, encoding="utf-8")
    for old in (OUT / "widgets").glob("*.svg"):
        if old.name not in keep:
            old.unlink()
    write_table()
    size = (OUT / "hero.svg").stat().st_size // 1024
    print(f"wrote Pictures/bar/hero.svg ({size} KB) and {len(keep)} widget strips")
    missing = REG.missing | BOLD.missing
    if missing:
        print("glyphs the font does not have: " + " ".join(f"U+{ord(c):04X}" for c in sorted(missing)))


if __name__ == "__main__":
    main()
