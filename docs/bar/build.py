#!/usr/bin/env python3
"""Draws the README's waybar: an animated hero, one strip per widget, and the
widget table in the README.

    python3 docs/bar/build.py

Reads the real bar (packages/waybar/.config/waybar/config.jsonc for the
pills, the module order and the window rewrites, style.css for the colors
and the padding), widgets.py for what each module shows, story.py for the
hero's timeline, and each app's own README hero for its panel (apps.py).
Writes:

- Pictures/bar/hero.svg: the animated hero (pure CSS animation, so GitHub
  plays it in an <img>; reduced motion gets a still with a drawer open).
- Pictures/bar/widgets/<module>.svg: each widget cycling through its states.
- The table between the `bar-widgets` markers in README.md.

The glyphs come from a Nerd Font subset embedded in each SVG, so the icons
are the same ones waybar draws. BAR_FONT picks the font file; the default is
JetBrains Mono Nerd Font Propo (OFL). Needs fontTools, and the apps checked
out beside dot-files (see apps.py).
"""

import json
import re
import sys
from dataclasses import dataclass, replace
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

T = LOOP
STILL = 5.0  # the moment shown with reduced motion: Roundhouse's drawer


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
    """Just enough of style.css to color and pad modules the way waybar does."""

    def __init__(self, path: Path):
        text = re.sub(r"/\*.*?\*/", "", path.read_text(encoding="utf-8"), flags=re.S)
        # @define-color names resolve wherever a value uses them
        self.defines = dict(re.findall(r"@define-color\s+([\w-]+)\s+([^;]+);", text))
        text = re.sub(r"@define-color[^;]*;", "", text)
        # @keyframes blocks nest braces; they only matter by name
        text = re.sub(r"@keyframes[^{]*\{(?:[^{}]*\{[^}]*\})*[^}]*\}", "", text)
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
        if found and found.startswith("@"):
            found = self.defines.get(found[1:], found)
        return found

    def color(self, css_id: str, cls: str | None) -> str:
        for c in reversed((cls or "").split()):
            found = self.get(f"#{css_id}.{c}", "color")
            if found:
                return found
        return self.get(f"#{css_id}", "color") or self.get("window#waybar", "color") or FG

    def animated(self, css_id: str, cls: str | None) -> bool:
        return any(self.get(f"#{css_id}.{c}", "animation") for c in (cls or "").split())

    def pad(self, selector: str) -> tuple[float, float]:
        """(left, right) padding in px from a `padding` (and `padding-left`)."""
        p = self.get(selector, "padding")
        left = right = 0.0
        if p:
            v = [float(x.rstrip("px")) for x in p.split()]
            top_, right_, bottom_, left_ = {1: v * 4, 2: v + v, 3: v + [v[1]], 4: v}[len(v)]
            left, right = left_, right_
        pl = self.get(selector, "padding-left")
        if pl is not None:
            left = float(pl.rstrip("px"))
        return left, right


def css_id(module: str) -> str:
    if module.startswith("hyprland/"):
        return module.split("/", 1)[1]
    # waybar leaves a "#name" suffix out of the CSS id (it becomes a class)
    return module.split("#", 1)[0].replace("/", "-")


CONFIG = load_jsonc(WAYBAR / "config.jsonc")
CSS = Css(WAYBAR / "style.css")

# The hero's canvas: a desktop at the bar's real size, so the bar's font
# and padding are waybar's own and the camera zooms in to read it.
W, H = 1792, 1008
FS = float(CSS.get("*", "font-size").rstrip("px"))
BAR_H = CONFIG.get("height", 34)
BAR_X = CONFIG.get("margin-left", 6)
BAR_W = W - BAR_X - CONFIG.get("margin-right", 6)
BAR_Y = H - CONFIG.get("margin-bottom", 6) - BAR_H
BAR_CY = BAR_Y + BAR_H / 2
BASE_Y = BAR_CY + FS * 0.36
SPACING = CONFIG.get("spacing", 0)
S = W / 1200  # captions and the cursor read at the size the old 1200 px hero had

PILL = CSS.get("#workspaces", "background")
PILL_LINE = CSS.get("#workspaces", "border").split(" ", 2)[2]
HOVER = CSS.get("#pulseaudio:hover", "background")
WS_HOVER = CSS.get("#workspaces button:hover", "background")
WS_ACTIVE = CSS.get("#workspaces button.active", "background")
BRIGHT = CSS.defines["bright"]
ART = CONFIG["image#tannoy-art"]["size"]
ART_PAD = CSS.pad("#image.tannoy-art image")[0]
TRAY_GAP = CONFIG.get("tray", {}).get("spacing", 8)


# ------------------------------------------------------------------ the bar

def rewrite_title(title: str) -> str:
    """hyprland/window's rewrite rules, applied as waybar does (all that match)."""
    for pat, rep in CONFIG.get("hyprland/window", {}).get("rewrite", {}).items():
        m = re.fullmatch(pat, title)
        if m:
            title = m.expand(rep.replace("$", "\\"))
    return title


def window_glyph(cls: str) -> str:
    ws = CONFIG.get("hyprland/workspaces", {})
    for key, rep in ws.get("window-rewrite", {}).items():
        m = re.fullmatch(r"class<(.*)>", key)
        if m and re.fullmatch(m.group(1), cls):
            return rep
    return ws.get("window-rewrite-default", "")


class Mod:
    def __init__(self, name: str, widget: Widget):
        self.name = name
        self.w = widget
        self.css = css_id(name)
        self.drawer: str | None = None  # the drawer group that hides it

    def lpad(self, state: str) -> float:
        st = self.w.states.get(state)
        left = CSS.pad(f"#{self.css}")[0]
        for c in (st.cls or "").split() if st else []:
            if CSS.get(f"#{self.css}.{c}", "padding-left") is not None:
                left = CSS.pad(f"#{self.css}.{c}")[0]
        return left

    def text_width(self, state: str) -> float:
        st = self.w.states[state]
        widest = max(REG.width(f, FS) for f in st.frames)
        return 0.0 if widest == 0 else widest + REG.width(st.tail, FS)

    def width(self, t: float) -> float:
        if self.drawer and state_at(self.drawer, t) != "open":
            return 0.0
        k = self.w.kind
        if k == "workspaces":
            l, r = CSS.pad("#workspaces")
            return l + r + sum(ws_button(n, wins)[1] for n, wins, _ in self.w.items)
        if k == "window":
            l, r = CSS.pad("#window")
            return l + r + REG.width(rewrite_title(self.w.items[0]), FS)
        if k == "tray":
            l, r = CSS.pad("#tray")
            return l + r + sum(REG.width(g, FS) for g, _ in self.w.items) + TRAY_GAP * (len(self.w.items) - 1)
        if k == "image":
            other = self.w.items[0]
            return ART_PAD + ART if ALL[other].w.states[state_at(other, t)].art else 0.0
        state = state_at(self.name, t)
        tw = self.text_width(state)
        if tw == 0:
            return 0.0
        return self.lpad(state) + tw + CSS.pad(f"#{self.css}")[1]


def ws_button(n: str, wins: list[str]) -> tuple[str, float]:
    """A workspace button's label after window-rewrite, and its width with
    its padding and margin."""
    label = "".join(window_glyph(c) for c in wins)
    pl, pr = CSS.pad("#workspaces button")
    return label, 1 + pl + REG.width(n + label, FS) + pr + 1


@dataclass
class Entry:
    """One top-level item of the bar: a pill of modules."""
    name: str
    mods: list[str]
    pad: tuple[float, float]  # the group's own padding inside its border


DRAWERS: dict[str, list[str]] = {}  # drawer group -> the modules it hides


def expand(name: str) -> list[str]:
    g = CONFIG.get(name, {})
    members = g.get("modules", [])
    if "drawer" not in g:
        return [m for n in members for m in (expand(n) if n.startswith("group/") else [n])]
    # The first module is the drawer's handle; the rest slide out beside it.
    DRAWERS[name] = members[1:]
    lead, rest = members[0], members[1:]
    return rest + [lead] if not g["drawer"].get("transition-left-to-right", True) else [lead] + rest


def entries(names: list[str]) -> list[Entry]:
    out = []
    for n in names:
        if n.startswith("group/"):
            out.append(Entry(n, expand(n), CSS.pad(f"#{n.split('/', 1)[1]}")))
        else:
            out.append(Entry(n, [n], (0.0, 0.0)))
    return out


LEFT = entries(CONFIG.get("modules-left", []) + CONFIG.get("modules-center", []))
RIGHT = entries(CONFIG.get("modules-right", []))
missing = [m for e in LEFT + RIGHT for m in e.mods if m not in WIDGETS]
if missing:
    sys.exit(
        "build.py: these modules are in config.jsonc but not in docs/bar/widgets.py:\n  "
        + "\n  ".join(missing)
        + "\nAdd an entry for each (name, what it does, its states), then run again."
    )
ALL = {m: Mod(m, WIDGETS[m]) for e in LEFT + RIGHT for m in e.mods}
for g, hidden in DRAWERS.items():
    for m in hidden:
        ALL[m].drawer = g

# Each module's (and drawer's) states over the loop.
CHANGES: dict[str, list[tuple[float, str]]] = {m: [(0.0, ALL[m].w.default)] for m in ALL}
CHANGES.update({g: [(0.0, "closed")] for g in DRAWERS})
for b in BEATS:
    for m, s in b.set.items():
        if m in DRAWERS:
            if s not in ("open", "closed"):
                sys.exit(f"story.py: beat at {b.t}s sets {m} to {s!r}; a drawer is 'open' or 'closed'")
        elif m not in ALL:
            sys.exit(f"story.py: beat at {b.t}s sets {m}, which is not in the bar")
        elif s not in ALL[m].w.states:
            sys.exit(f"story.py: beat at {b.t}s sets {m} to {s!r}; widgets.py has {list(ALL[m].w.states)}")
        CHANGES[m].append((b.t, s))
for m, ch in CHANGES.items():
    ch.sort(key=lambda c: c[0])
    default = "closed" if m in DRAWERS else ALL[m].w.default
    if (m in DRAWERS or ALL[m].w.states) and ch[-1][1] != default:
        sys.exit(f"story.py: {m} ends the loop as {ch[-1][1]!r}; set it back to {default!r}")


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


def entry_width(e: Entry, t: float) -> tuple[float, list[float]]:
    ws = [ALL[m].width(t) for m in e.mods]
    if not any(ws):
        return 0.0, ws
    return 1 + e.pad[0] + sum(ws) + e.pad[1] + 1, ws


def layout(t: float):
    """Where everything is at time t: {module: (x, w)}, {entry: (x, w)}."""
    mods, pills = {}, {}

    def place(e: Entry, x: float, ew: float, ws: list[float]):
        pills[e.name] = (x, ew)
        mx = x + 1 + e.pad[0]
        for m, w in zip(e.mods, ws):
            mods[m] = (mx, w)
            mx += w

    x = BAR_X
    for e in LEFT:
        ew, ws = entry_width(e, t)
        place(e, x, ew, ws)
        if ew:
            x += ew + SPACING
    x = BAR_X + BAR_W
    for e in reversed(RIGHT):
        ew, ws = entry_width(e, t)
        if ew:
            x -= ew
        place(e, x, ew, ws)
        if ew:
            x -= SPACING
    return mods, pills


TIMES = sorted({0.0} | {t for ch in CHANGES.values() for t, _ in ch})


def center(m: str, t: float) -> float:
    x, w = layout(t)[0][m]
    return x + w / 2


def overlap_check():
    for t in TIMES:
        _, pills = layout(t)
        left_end = max(x + w for e, (x, w) in pills.items() if any(e == le.name for le in LEFT) and w)
        right_start = min(x for e, (x, w) in pills.items() if any(e == re_.name for re_ in RIGHT) and w)
        if right_start - left_end < 24:
            sys.exit(f"build.py: at {t}s the bar's right side runs into its left side; shorten a state's text")


# ------------------------------------------------------------------ camera

def ease(u: float) -> float:
    return u * u * (3 - 2 * u)


def clamp_cam(z: float, tx: float, ty: float):
    """Keeps the view inside the desktop."""
    return (z, min(0.0, max(W - W * z, tx)), min(0.0, max(H - H * z, ty)))


def frame_box(x0, y0, x1, y1, top=96, bottom=12, side=80):
    """The camera that fits a box under the caption, its bottom near the
    screen's bottom edge."""
    z = min(W / (x1 - x0 + 2 * side), (H - top - bottom) / (y1 - y0), 2.2)
    z = max(1.0, z)
    tx = W / 2 - (x0 + x1) / 2 * z
    ty = H - bottom - y1 * z
    if y0 * z + ty < top:
        ty = top - y0 * z
    return clamp_cam(z, tx, ty)


def cam_target(spec, t: float, panels: "Panels"):
    if isinstance(spec, str) and spec.startswith("panel:"):
        o = panels.opening(spec.split(":", 1)[1], t)
        p = panels.place(o)
        w, h = o.size()
        return frame_box(p.x, p.bottom - h, p.x + w, BAR_Y + BAR_H)
    zoom, focus = spec
    if focus is None or zoom <= 1.0:
        return (1.0, 0.0, 0.0)
    return clamp_cam(zoom, W / 2 - center(focus, t) * zoom, H / 2 - BAR_CY * zoom)


class Camera:
    def __init__(self, panels: "Panels"):
        self.moves = [(0.0, (1.0, 0.0, 0.0))]
        self.on_bar = [(0.0, False)]  # zoomed in on a module, not framing a panel
        for b in BEATS:
            if b.camera:
                self.moves.append((b.t, cam_target(b.camera, b.t + MOVE, panels)))
                self.on_bar.append((b.t, isinstance(b.camera, tuple) and b.camera[1] is not None and b.camera[0] > 1))

    def bar_zoom(self, t: float) -> bool:
        return [on for when, on in self.on_bar if when <= t][-1]

    def at(self, t: float):
        cur = self.moves[0][1]
        for start, target in self.moves[1:]:
            if t < start:
                break
            u = min(1.0, (t - start) / MOVE)
            k = ease(u)
            cur = tuple(c + (g - c) * k for c, g in zip(cur, target))
            if u < 1.0:
                return cur
        return cur

    def to_screen(self, x: float, y: float, t: float):
        z, tx, ty = self.at(t)
        return (x * z + tx, y * z + ty)


# ------------------------------------------------------------------ panels

class Panels:
    """Every opening of every panel, from the story's open/look/close beats."""

    def __init__(self):
        self.openings: list[scenes.Opening] = []
        now: dict[str, scenes.Opening] = {}
        for b in BEATS:
            closes = [b.close] if isinstance(b.close, str) else (b.close or [])
            for name in closes:
                if name not in now:
                    sys.exit(f"story.py: beat at {b.t}s closes {name}, which is not open")
                now.pop(name).t_close = b.t
            if b.open:
                name, key = b.open
                if name not in scenes.ANCHORS:
                    sys.exit(f"story.py: beat at {b.t}s opens {name}; scenes.ANCHORS has {list(scenes.ANCHORS)}")
                scenes.look(name, key)
                now[name] = scenes.Opening(name, b.via or scenes.ANCHORS[name], b.t, T, [(b.t, key)])
                self.openings.append(now[name])
            if b.look:
                name, key = b.look
                if name not in now:
                    sys.exit(f"story.py: beat at {b.t}s changes {name}'s look, but it is not open")
                scenes.look(name, key)
                now[name].looks.append((b.t, key))
        if now:
            sys.exit(f"story.py: {', '.join(now)} still open at the end of the loop; close it")

    def opening(self, name: str, t: float) -> scenes.Opening:
        """The opening of `name` that is open at t, or the next one."""
        for o in self.openings:
            if o.panel == name and o.t_close >= t - MOVE:
                return o
        sys.exit(f"story.py: the camera frames {name} at {t}s, but it does not open after that")

    def place(self, o: scenes.Opening) -> scenes.Place:
        w, h = o.size()
        if o.anchor is None:
            return scenes.place_window(W, BAR_Y - 70 - h, w, h)
        return scenes.place_above(center(o.anchor, o.t_open), BAR_Y, W, w)

    def hotspot(self, target: str, t: float):
        name, spot = target.split(":", 1)
        for o in self.openings:
            if o.panel == name and o.t_open <= t <= o.t_close:
                key = o.look_at(t - 0.01)
                lk = scenes.look(name, key)
                if spot not in lk.spots:
                    sys.exit(f"story.py: a click on {target} at {t}s; the {key!r} look has {list(lk.spots)}")
                return self.place(o).screen(lk, *lk.spots[spot])
        sys.exit(f"story.py: a click on {target} at {t}s, when that panel is not open")

    def draw(self, svg: Svg):
        for o in self.openings:
            scenes.panel(svg, o, self.place(o), STILL)


# ------------------------------------------------------------------ pieces

def draw_module_states(svg: Svg, m: Mod, x0: float, y0: float, timeline=None, loop=T, still=STILL, art_w=0.0):
    """The module's text for each state (and frame), shown when it is active.
    Coordinates are relative to the module's left edge; `art_w` moves the
    text of states with a cover past it (the strips draw the cover inline)."""
    w = m.w
    base_y = y0 + BAR_H / 2 + FS * 0.36
    segs = timeline if timeline is not None else segments(m.name)
    for state, st in w.states.items():
        mine = [(a, b) for a, b, s in segs if s == state]
        if not mine or not any(f for f in st.frames):
            continue
        color = CSS.color(m.css, st.cls)
        pulse = ' class="pulse"' if CSS.animated(m.css, st.cls) else ""
        lp = m.lpad(state) + (art_w if st.art else 0.0)
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
            svg.text(x0 + lp, base_y, frame, FS, color, extra=pulse)
            if st.tail:
                svg.text(x0 + lp + REG.width(frame, FS), base_y, st.tail, FS, CSS.color(m.css, None))
            svg.add("</g>")


def draw_cover(svg: Svg, m: Mod, x0: float, y0: float, timeline=None, loop=T, still=STILL):
    """The image module: the followed module's cover, state by state."""
    other = ALL[m.w.items[0]]
    segs = timeline if timeline is not None else segments(other.name)
    for art in sorted({other.w.states[s].art for _, _, s in segs} - {None}):
        ivs = [(a, b) for a, b, s in segs if other.w.states[s].art == art]
        name = svg.keyframes("opacity", visible_points(ivs, fade=0.12, loop=loop))
        svg.add(f'<g class="a" style="animation-name:{name}" opacity="{1 if at(ivs, still) else 0}">')
        svg.add(f'<use href="#{art}" x="{x0 + ART_PAD:.1f}" y="{y0 + (BAR_H - ART) / 2:.1f}" width="{ART}" height="{ART}"/>')
        svg.add("</g>")


def geometry_rects(svg: Svg, boxes: list[tuple[float, float, float]], y: float, h: float, rx: float, fill: str, stroke=None):
    """A rect that snaps between (t, x, w) geometries: one per distinct box,
    shown while it applies."""
    spans: dict[tuple[float, float], list[tuple[float, float]]] = {}
    for i, (t, x, w) in enumerate(boxes):
        end = boxes[i + 1][0] if i + 1 < len(boxes) else T
        if w and end > t:
            spans.setdefault((round(x, 1), round(w, 1)), []).append((t, end))
    line = f' stroke="{stroke}"' if stroke else ""
    for (x, w), ivs in spans.items():
        if len(spans) == 1 and ivs == [(0.0, T)]:
            svg.add(f'<rect x="{x + .5:.1f}" y="{y + .5:.1f}" width="{w - 1:.1f}" height="{h - 1:.1f}" rx="{rx}" fill="{fill}"{line}/>')
            continue
        name = svg.keyframes("opacity", visible_points(ivs, fade=0.06, loop=T))
        svg.add(f'<rect class="a" style="animation-name:{name}" opacity="{1 if at(ivs, STILL) else 0}" '
                f'x="{x + .5:.1f}" y="{y + .5:.1f}" width="{w - 1:.1f}" height="{h - 1:.1f}" rx="{rx}" fill="{fill}"{line}/>')


def draw_bar(svg: Svg, touches: list[tuple[float, str]]):
    lays = [(t, layout(t)) for t in TIMES]
    # The pills.
    for e in LEFT + RIGHT:
        boxes = [(t, *lay[1][e.name]) for t, lay in lays]
        geometry_rects(svg, boxes, BAR_Y, BAR_H, 10, PILL, PILL_LINE)
    # The modules, each moving as the pills around it grow and shrink.
    for m in ALL.values():
        xs = [(t, lay[0][m.name][0]) for t, lay in lays]
        x_still = layout(STILL)[0][m.name][0]
        if len({round(x, 2) for _, x in xs}) > 1:
            pts = []
            for i, (t, x) in enumerate(xs):
                if i:
                    pts.append((t, f"translate({xs[i - 1][1]:.1f}px, 0px)"))
                pts.append((t + (0.06 if i else 0), f"translate({x:.1f}px, 0px)"))
            name = svg.keyframes("transform", pts)
            svg.add(f'<g class="a" style="animation-name:{name}" transform="translate({x_still:.1f} 0)">')
        else:
            svg.add(f'<g transform="translate({xs[0][1]:.1f} 0)">')
        # A drawer's modules show only while it is open.
        if m.drawer:
            ivs = [(a, b) for a, b, s in segments(m.drawer) if s == "open"]
            name = svg.keyframes("opacity", visible_points(ivs, fade=0.2, loop=T))
            svg.add(f'<g class="a" style="animation-name:{name}" opacity="{1 if at(ivs, STILL) else 0}">')
        # Hover feedback around each click or hover on this module.
        for t, target in touches:
            if target == m.name:
                w = layout(t - 0.01)[0][m.name][1] or layout(t + 0.3)[0][m.name][1]
                name = svg.keyframes("opacity", visible_points([(t - 0.4, t + 0.45)], fade=0.12))
                svg.add(f'<rect class="a" style="animation-name:{name}" opacity="0" x="0" y="{BAR_Y + 4}" '
                        f'width="{w:.1f}" height="{BAR_H - 8}" rx="7" fill="{HOVER}"/>')
        kind = m.w.kind
        if kind == "workspaces":
            x = CSS.pad("#workspaces")[0]
            pl = CSS.pad("#workspaces button")[0]
            for n, wins, active in m.w.items:
                label, bw = ws_button(n, wins)
                if active:
                    svg.add(f'<rect x="{x + 1:.1f}" y="{BAR_Y + 5}" width="{bw - 2:.1f}" height="{BAR_H - 10}" rx="7" fill="{WS_ACTIVE}"/>')
                color = BRIGHT if active else FG
                svg.text(x + 1 + pl, BASE_Y, n, FS, color, extra=' fill-opacity=".55"')
                svg.text(x + 1 + pl + REG.width(n, FS), BASE_Y, label, FS, color)
                x += bw
        elif kind == "window":
            svg.text(CSS.pad("#window")[0], BASE_Y, rewrite_title(m.w.items[0]), FS, CSS.color("window", None))
        elif kind == "tray":
            x = CSS.pad("#tray")[0]
            for g, color in m.w.items:
                svg.text(x, BASE_Y, g, FS, color)
                x += REG.width(g, FS) + TRAY_GAP
        elif kind == "image":
            draw_cover(svg, m, 0.0, BAR_Y)
        else:
            draw_module_states(svg, m, 0.0, BAR_Y)
        if m.drawer:
            svg.add("</g>")
        svg.add("</g>")


def code_line(svg: Svg, x, y, parts, size):
    for s, color in parts:
        svg.text(x, y, s, size, color)
        x += REG.width(s, size)


def window(svg: Svg, x, y, w, h, title):
    svg.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="{WIN}" stroke="{WIN_LINE}"/>')
    svg.add(f'<path d="M{x},{y + 12} a12,12 0 0 1 12,-12 h{w - 24} a12,12 0 0 1 12,12 v22 h-{w} Z" fill="{WIN_BAR}"/>')
    svg.text(x + 18, y + 24, title, 15, DIM)


def draw_desktop(svg: Svg, typing: tuple[float, float] | None):
    svg.add(f'<rect width="{W}" height="{H}" fill="url(#bg)"/>')
    svg.add(f'<rect width="{W}" height="{H}" fill="url(#haze)"/>')
    # The editor, where dictation lands.
    fs, lh = 19, 35
    ex, ey, ew, eh = 52, 46, 1060, 860
    window(svg, ex, ey, ew, eh, "~/Sites/ledger/src/retry.ts")
    K, Sg, N, F, C = VIOLET, GO, ORANGE, FROST, FAINT
    lines = [
        [("import", K), (" { sleep } ", FG), ("from", K), (' "./time"', Sg), (";", FG)],
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
    y = ey + 84
    for i, parts in enumerate(lines):
        svg.text(ex + 28, y, f"{i + 1:>2}", fs, C)
        if parts is None:
            if typing:
                t0, t1 = typing
                full = REG.width("  " + DICTATED, fs)
                svg.add('<clipPath id="typed"><rect class="a" style="animation-name:'
                        + svg.keyframes("width", [(0, "0px"), (t0, "0px"), (t1, f"{full:.0f}px"), (T - 2.4, f"{full:.0f}px"), (T - 2.2, "0px")])
                        + f'" x="{ex + 78}" y="{y - 20}" width="{full if t1 <= STILL else 0:.0f}" height="30"/></clipPath>')
                svg.add('<g clip-path="url(#typed)">')
                svg.text(ex + 78, y, "  " + DICTATED, fs, DIM)
                svg.add("</g>")
        elif parts:
            code_line(svg, ex + 78, y, parts, fs)
        y += lh
    # A terminal beside it.
    tx, ty, tw, th = 1144, 100, 600, 420
    window(svg, tx, ty, tw, th, "kitty")
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
    y = ty + 76
    for parts in rows:
        code_line(svg, tx + 22, y, parts, 18)
        y += 34


def draw_caption(svg: Svg, captions, cam: Camera):
    """Zoomed in on a module, a title card in the dimmed space above the
    bar; otherwise a pill at the top, over the desktop or above a panel."""
    for i, (t, name, words) in enumerate(captions):
        end = captions[i + 1][0] if i + 1 < len(captions) else T
        end = min(end, t + 4.2)
        # A caption leaves when the camera moves on, so a title card never
        # outlives its zoom.
        moves = [s for s, _ in cam.moves[1:] if s > t + 0.5]
        if moves:
            end = min(end, moves[0] + 0.2)
        vis = svg.keyframes("opacity", visible_points([(t, end)], fade=0.25))
        svg.add(f'<g class="a" style="animation-name:{vis}" opacity="{1 if t <= STILL < end else 0}">')
        z, _, ty = cam.at(t + MOVE)
        if cam.bar_zoom(t + 0.01):
            bar_top = BAR_Y * z + ty
            cy = bar_top / 2 + 10
            svg.text(W / 2, cy - 10 * S, name, 34 * S, FROST, 700, "middle")
            svg.text(W / 2, cy + 30 * S, words, 20 * S, FG, 400, "middle")
        else:
            fs = 15 * S
            label = f"{name}  "
            width = BOLD.width(label, fs) + REG.width(words, fs) + 36 * S
            x0 = (W - width) / 2
            svg.add(f'<rect x="{x0:.1f}" y="{18 * S:.1f}" width="{width:.1f}" height="{36 * S:.1f}" rx="{18 * S:.1f}" '
                    f'fill="#101216" fill-opacity=".88" stroke="#3b4048"/>')
            svg.text(x0 + 18 * S, 41 * S, label, fs, FROST, 700)
            svg.text(x0 + 18 * S + BOLD.width(label, fs), 41 * S, words, fs, FG)
        svg.add("</g>")


ALT = (
    "A Hyprland desktop under a floating waybar of frosted pills: workspaces with a glyph per open window, the window "
    "title, Tannoy's cover and song, a pill of lamps, the audio pill, the desk pill and the Timetable clock. A build "
    "turns the Roundhouse lamp red; its drawer says memory is stalling, and its link opens the Switchyard board, where "
    "android is held until storefront finishes, the lamp calms and android starts. The Tannoy player slides out of the "
    "cover, and picking Chrome swaps the bar to a podcast. An agent asks for a secret: broker's request window waits "
    "for a YubiKey touch while the Signal Box lamp turns to an amber key, then the Signal Box panel lists every live "
    "grant and Revoke all dims the lamp. The volume switches to the headset and the mouse battery runs low. Logbook's "
    "lamp turns frost when Chrome takes the mic; its drawer records the meeting on air, with do not disturb hiding the "
    "song, marks a moment, and stops, and the transcript is made and ready to copy; dictation types a comment into the "
    "editor. The desk drawer slides the key lights and the power menu out of its arrow, and the key lights warm the "
    "room. The Timetable clock names the next meeting, its drawer starts a focus block, then the clock turns amber and "
    "red to join. The VPN connects, a swaync notification arrives, and do not disturb silences it and hides the song."
)


def hero() -> str:
    svg = Svg(T)
    svg.css.append(scenes.css())
    overlap_check()
    panels = Panels()
    cam = Camera(panels)
    touches, clicks, captions, times = [], [], [], {}
    for b in BEATS:
        if b.scene:
            times.setdefault(b.scene, []).append(b.t)
        for target, ripple in ((b.click, True), (b.hover, False)):
            if target is None:
                continue
            if target == "outside":
                p = (W * 0.3, H * 0.3)
            elif isinstance(target, str) and target in ALL:
                touches.append((b.t, target))
                x, w = layout(b.t - 0.01)[0][target]
                if not w:
                    sys.exit(f"story.py: a click on {target} at {b.t}s, when it is not in the bar")
                p = cam.to_screen(x + w / 2, BAR_CY, b.t)
            elif isinstance(target, str) and ":" in target:
                p = cam.to_screen(*panels.hotspot(target, b.t), b.t)
            elif isinstance(target, str):
                sys.exit(f"story.py: beat at {b.t}s clicks {target}, which is not a module, a panel spot or 'outside'")
            else:
                p = target
            clicks.append((b.t, p, ripple))
        if b.caption:
            captions.append((b.t, *b.caption))
    one = lambda k: (times.get(k) or [None])[0]  # noqa: E731

    svg.add('<defs>'
            f'<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{BG0}"/><stop offset="1" stop-color="{BG1}"/></linearGradient>'
            '<radialGradient id="haze" cx=".85" cy=".1" r=".7"><stop offset="0" stop-color="#88c0d0" stop-opacity=".08"/><stop offset="1" stop-color="#88c0d0" stop-opacity="0"/></radialGradient>'
            '<radialGradient id="warm" cx=".5" cy=".2" r=".9"><stop offset="0" stop-color="#ffd8a8" stop-opacity=".13"/><stop offset="1" stop-color="#ffd8a8" stop-opacity=".02"/></radialGradient>'
            '<filter id="shadow" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="10" stdDeviation="14" flood-color="#000" flood-opacity=".5"/></filter>'
            + scenes.TOAST_DEFS + scenes.defs()
            + "</defs>")

    # Behind everything, for the edges the zoomed desktop does not cover.
    svg.add(f'<rect width="{W}" height="{H}" fill="{BG1}"/>')
    # Everything the camera moves.
    samples = sorted({0.0, T} | {s + MOVE * k / 10 for s, _ in cam.moves[1:] for k in range(11)})
    pts = []
    for t in samples:
        z, tx, ty = cam.at(t)
        pts.append((t, f"translate({tx:.2f}px, {ty:.2f}px) scale({z:.4f})"))
    move = svg.keyframes("transform", pts)
    svg.add(f'<g class="a" style="animation-name:{move};transform-origin:0 0">')
    typing = (one("type"), one("type") + 1.4) if one("type") is not None else None
    draw_desktop(svg, typing)
    # The desktop dims as the camera closes in.
    dim = svg.keyframes("opacity", [(t, f"{min(0.72, 0.72 * (cam.at(t)[0] - 1) / (ZOOM - 1)):.3f}") for t in samples])
    svg.add(f'<rect class="a" style="animation-name:{dim}" opacity="0" x="-{W}" y="-{H}" width="{3 * W}" height="{2 * H + BAR_Y - 6}" fill="{BG1}"/>')
    draw_bar(svg, touches)
    panels.draw(svg)
    # swaync's notification, top right as its config puts it.
    if one("toast") is not None:
        gone = one("toast-dismiss") or one("toast") + 6
        scenes.toast(svg, W - 14 - scenes.TOAST_W, 14, one("toast"), gone, STILL)
    svg.add("</g>")

    # The room lights up with the key lights.
    if one("lights-on") is not None:
        on, off = one("lights-on"), one("lights-off") or T - 1
        name = svg.keyframes("opacity", visible_points([(on, off)], fade=0.5))
        svg.add(f'<rect class="a" style="animation-name:{name}" opacity="0" width="{W}" height="{H}" fill="url(#warm)"/>')

    draw_caption(svg, captions, cam)

    # The cursor and its clicks, in screen space.
    rest = (W * 0.66, H * 0.42)
    cpts = [(0.0, rest)]
    for t, p, _ in clicks:
        cpts += [(t - 0.5, p), (t + 0.3, p)]
    cpts.append((T - 0.6, rest))
    name = svg.keyframes("transform", [(t, f"translate({x:.1f}px, {y:.1f}px)") for t, (x, y) in cpts])
    for t, (x, y), ripple in clicks:
        if not ripple:
            continue
        rip = svg.keyframes("transform", [(0, "scale(.3)"), (t, "scale(.3)"), (t + 0.45, "scale(1.7)"), (t + 0.46, "scale(.3)")])
        op = svg.keyframes("opacity", [(0, "0"), (t - 0.01, "0"), (t, ".9"), (t + 0.45, "0")])
        svg.add(f'<circle class="a" style="animation-name:{rip},{op};transform-box:fill-box;transform-origin:center" opacity="0" '
                f'cx="{x:.1f}" cy="{y:.1f}" r="{16 * S:.1f}" fill="none" stroke="{FROST}" stroke-width="{2.5 * S:.1f}"/>')
    sx, sy = next((p for t, p in reversed(cpts) if t <= STILL), rest)
    svg.add(f'<g class="a" style="animation-name:{name}" transform="translate({sx:.1f} {sy:.1f})">'
            f'<path transform="scale({S:.3f})" d="M0,0 L0,22 L6,17 L10,26 L14,24 L10,15 L18,15 Z" fill="#eceff4" '
            'stroke="#1d2024" stroke-width="1.4" stroke-linejoin="round"/></g>')
    return svg.render(W, H, ALT)


# ------------------------------------------------------------------ strips

STRIP_STEP = 1.6


def with_parts(m: Mod) -> Mod:
    """A module drawn as one widget with its "#name" parts (the lit key
    lights beside the drawer): each state shows whichever part prints it."""
    parts = [m.w] + [p.w for p in ALL.values() if p.name.split("#", 1)[0] == m.name and p is not m]
    states = {
        s: next((p.states[s] for p in parts if s in p.states and any(p.states[s].frames)), st)
        for s, st in m.w.states.items()
    }
    out = Mod(m.name, replace(m.w, states=states))
    return out


def own_widgets() -> list[Mod]:
    """The right side's custom modules with a strip and a table row each;
    "#name" parts are drawn inside their module's strip instead, and the
    handle and the cover belong to their pills."""
    right = [m for e in RIGHT for m in e.mods]
    return [with_parts(ALL[m]) for m in right if ALL[m].w.kind == "custom" and "#" not in m and ALL[m].w.what]


def strip(m: Mod):
    states = [s for s, st in m.w.states.items() if any(st.frames)]
    if not states:
        return None
    loop = STRIP_STEP * len(states) if len(states) > 1 else T
    timeline = [(i * STRIP_STEP, (i + 1) * STRIP_STEP, s) for i, s in enumerate(states)] if len(states) > 1 else [(0.0, loop, states[0])]
    arts = any(m.w.states[s].art for s in states)
    art_w = ART_PAD + ART if arts else 0.0
    width = max(m.lpad(s) + m.text_width(s) + CSS.pad(f"#{m.css}")[1] for s in states) + art_w + 8
    height = BAR_H + 8
    svg = Svg(loop)
    defs = scenes.apps.tannoy_defs() if arts else ""
    svg.add(f"<defs>{defs}</defs>")
    # Opaque: the pill's own color is see-through for the wallpaper, and a
    # README can be white behind it.
    svg.add(f'<rect x=".5" y=".5" width="{width - 1:.1f}" height="{height - 1}" rx="12" fill="{CSS.defines["bar"]}" stroke="{PILL_LINE}"/>')
    if arts:
        for art in sorted({m.w.states[s].art for s in states} - {None}):
            ivs = [(a, b) for a, b, s in timeline if m.w.states[s].art == art]
            name = svg.keyframes("opacity", visible_points(ivs, loop=loop))
            svg.add(f'<g class="a" style="animation-name:{name}" opacity="{1 if at(ivs, 0.0) else 0}">'
                    f'<use href="#{art}" x="{4 + ART_PAD:.1f}" y="{4 + (BAR_H - ART) / 2:.1f}" width="{ART}" height="{ART}"/></g>')
    draw_module_states(svg, m, 4, 4, timeline=timeline, loop=loop, still=0.0, art_w=art_w)
    return svg.render(round(width, 1), height, f"{m.w.name}: " + ", ".join(states), scale=1.5)


def write_table():
    rows = ["| | Widget | What it does | Needs |", "|---|---|---|---|"]
    for m in own_widgets():
        slug = m.name.split("/")[-1]
        rows.append(
            f'| <img src="Pictures/bar/widgets/{slug}.svg" height="36" alt="{esc(m.w.name)}"> '
            f"| [{m.w.name}]({m.w.source}) | {m.w.what} | {m.w.needs} |"
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
    for m in own_widgets():
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
