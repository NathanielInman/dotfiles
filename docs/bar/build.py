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

import json
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # no __pycache__ next to widgets.py and story.py

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))

import scenes  # noqa: E402
from story import BEATS, DICTATED, LOOP, MOVE, ZOOM  # noqa: E402
from svgkit import (  # noqa: E402
    BG0, BG1, BOLD, DIM, FAINT, FG, FROST, GO, ORANGE, REG, VIOLET, WIN, WIN_BAR, WIN_LINE,
    Svg, at, esc, visible_points,
)
from widgets import WIDGETS, Widget  # noqa: E402

WAYBAR = ROOT / "packages/waybar/.config/waybar"
OUT = ROOT / "Pictures/bar"
README = ROOT / "README.md"

# The hero's canvas and the bar inside it. The real bar is 24px tall with an
# 18px font; this keeps that ratio at a size a README can show.
W, H = 1200, 600
FS = 15
BAR_H = 28
BAR_X, BAR_Y, BAR_W = 8, H - BAR_H - 8, W - 16
BAR_CY = BAR_Y + BAR_H / 2
PAD = 6
ZOOM_TY = H - 64  # where the bar's middle sits on screen while zoomed
STILL = 22.6  # the moment shown with reduced motion: Roundhouse's drawer
T = LOOP

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


DRAWER_SCALE, BOARD_SCALE = 0.95, 1.0


def pair(opens: list[tuple[float, str]], closes: list[float]):
    """(open time, anchor module, close time) for each opening."""
    out = []
    for t, anchor in sorted(opens):
        c = min((x for x in closes if x > t), default=T - 0.5)
        out.append((t, anchor, c))
    return out


class Panels:
    """When each panel is open, where, and where clicks on it land."""

    def __init__(self, scenes: dict[str, list[float]]):
        get = lambda k: scenes.get(k, [])  # noqa: E731
        self.board = pair([(t, "custom/switchyard") for t in get("board-open")] + [(t, "custom/roundhouse") for t in get("handoff")],
                          get("board-close"))
        self.drawer = pair([(t, "custom/roundhouse") for t in get("drawer-open")], get("drawer-close") + get("handoff"))

    def where(self, kind: str, t_open: float, anchor: str) -> scenes.Place:
        w, h, k = (scenes.BOARD_W, scenes.BOARD_H, BOARD_SCALE) if kind == "board" else (scenes.DRAWER_W, scenes.DRAWER_H, DRAWER_SCALE)
        return scenes.place(center(anchor, t_open), BAR_Y, W, w, h, k)

    def hotspot(self, target: str, t: float):
        kind, part = target.split(":", 1)
        spots = scenes.BOARD_SPOTS if kind == "board" else scenes.DRAWER_SPOTS
        for o, anchor, c in getattr(self, kind):
            if o <= t <= c:
                return self.where(kind, o, anchor).screen(*spots[part])
        sys.exit(f"story.py: a click on {target} at {t}s, when that panel is not open")


def draw_panels(svg: Svg, panels: Panels, scene_times: dict[str, list[float]]):
    first = lambda k, d: (scene_times.get(k) or [d])[0]  # noqa: E731
    times = scenes.BoardTimes(
        storefront_build=first("storefront-build", T),
        android_queue=first("android-queue", T),
        android_held=first("android-held", T),
        storefront_done=first("storefront-done", T),
        android_build=first("android-build", T),
        end=T,
    )
    lamp: dict[str, list[tuple[float, float]]] = {}
    for a, b, st in segments("custom/roundhouse"):
        lamp.setdefault(st, []).append((a, b))
    for o, anchor, c in panels.drawer:
        yard = CSS.color("custom-switchyard", WIDGETS["custom/switchyard"].states[state_at("custom/switchyard", o)].cls)
        scenes.drawer(svg, panels.where("drawer", o, anchor), [(o, c)], STILL, yard)
    for o, anchor, c in panels.board:
        scenes.board(svg, panels.where("board", o, anchor), [(o, c)], STILL, times, lamp)


def draw_caption(svg: Svg, captions):
    """Zoomed in, a title card in the dimmed space above the bar; zoomed out,
    a small pill at the top so the desktop stays visible."""
    for i, (t, name, words) in enumerate(captions):
        end = captions[i + 1][0] if i + 1 < len(captions) else T
        end = min(end, t + 4.2)
        # A caption leaves when the camera moves on, so a title card never
        # outlives its zoom.
        moves = [s for s, _ in CAM_MOVES[1:] if s > t + 0.5]
        if moves:
            end = min(end, moves[0] + 0.2)
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
    svg.css.append(scenes.PULSE_CSS)
    clicks_mod, clicks_all, captions, times = [], [], [], {}
    for b in BEATS:
        if b.scene:
            times.setdefault(b.scene, []).append(b.t)
    panels = Panels(times)
    for b in BEATS:
        if isinstance(b.click, str) and ":" in b.click:
            x, y = panels.hotspot(b.click, b.t)
            clicks_all.append((b.t, to_screen(x, y, b.t)))
        elif isinstance(b.click, str):
            clicks_mod.append((b.t, b.click))
            x, w = layout(b.t - 0.01)[b.click]
            clicks_all.append((b.t, to_screen(x + w / 2, BAR_CY, b.t)))
        elif b.click:
            clicks_all.append((b.t, b.click))
        if b.caption:
            captions.append((b.t, *b.caption))
    one = lambda k: (times.get(k) or [None])[0]  # noqa: E731

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
    typing = (one("type"), one("type") + 1.4) if one("type") is not None else None
    draw_desktop(svg, typing)
    # The desktop dims as the camera closes in on the bar.
    dim = svg.keyframes("opacity", [(t, f"{0.72 * (cam_at(t)[0] - 1) / (ZOOM - 1):.3f}") for t in samples])
    svg.add(f'<rect class="a" style="animation-name:{dim}" opacity="0" x="-{W}" y="-{H}" width="{3 * W}" height="{2 * H + BAR_Y - 6}" fill="{BG1}"/>')
    draw_bar(svg, clicks_mod)
    draw_panels(svg, panels, times)
    svg.add("</g>")

    # The room lights up with the key lights.
    if one("lights-on") is not None:
        on, off = one("lights-on"), one("lights-off") or T - 1
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
             "dictation types a comment into the editor. The Switchyard board opens from its signal and starts a storefront build, "
             "android queues behind it, the Roundhouse lamp turns red and its drawer explains that memory is stalling, its link "
             "swaps back to the board where storefront finishes and android starts, the key lights warm the room, and the clock "
             "switches time zones.")
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
