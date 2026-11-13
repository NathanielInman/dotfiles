"""The panels the bar opens, and the other effects the story can start.

Every panel is drawn by its own app (apps.py runs the panel part of each
app's README hero), so this file only says which states the tour shows
(`LOOKS`), where each panel springs out of (`ANCHORS`), and how a panel
opens, changes state and closes on screen.

A panel is placed above the module that opened it, at the app's real
size, anchored at its bottom edge like the GTK layer surfaces are: a
taller state grows upward.
"""

from dataclasses import dataclass
from functools import cache

import apps
from svgkit import FROST, GO, STOP, Svg, at, visible_points

PULSE_CSS = (
    ".pulse { animation: pulse 1.4s ease-in-out infinite; }\n"
    "@keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: .35; } }\n"
    "@media (prefers-reduced-motion: reduce) { .pulse { animation: none !important; } }"
)

# The module each panel springs out of. None: the panel is a window of
# its own, centered on the desk (broker's request window).
ANCHORS = {
    "roundhouse": "custom/roundhouse",
    "switchyard": "custom/switchyard",
    "signalbox": "custom/broker",
    "request": None,
    "tannoy": "image#tannoy-art",
    "logbook": "custom/logbook",
    "timetable": "custom/timetable",
    "tablet": "custom/tablet",
}

# The states the tour shows, by panel. Each is a function so an app is
# only read when the story uses it.
LOOKS = {
    "roundhouse": {
        # Memory is stalling and Switchyard holds android: its phase is
        # waiting, which dots the link to the board.
        "act": lambda: apps.roundhouse("act", "waiting"),
        "calm": lambda: apps.roundhouse("calm", "building"),
    },
    "switchyard": {
        "held": lambda: apps.switchyard("held", STOP),
        "done": lambda: apps.switchyard("done", GO),
    },
    "signalbox": {
        "live": lambda: apps.signal_box("live"),
        "register": lambda: apps.signal_box("register"),
        "empty": lambda: apps.signal_box("empty"),
    },
    "request": {
        "ask": lambda: apps.request_window(False),
        "granted": lambda: apps.request_window(True),
    },
    "tannoy": {
        "song": lambda: apps.tannoy("song"),
        "podcast": lambda: apps.tannoy("pod", picked=True),
    },
    "logbook": {k: (lambda k=k: apps.logbook(k)) for k in ("mic", "onair", "marked", "transcribing", "ready")},
    "tablet": {k: (lambda k=k: apps.tablet(k)) for k in ("held", "stale", "reconnected", "checks")},
    "timetable": {
        "next": lambda: apps.timetable(14, 33),
        "focus": lambda: apps.timetable(14, 33, 25),
    },
}


@cache
def look(panel: str, key: str) -> apps.Look:
    if panel not in LOOKS or key not in LOOKS[panel]:
        raise KeyError(f"no look {key!r} for panel {panel!r}; scenes.py has {list(LOOKS.get(panel, {}))}")
    return LOOKS[panel][key]()


def defs() -> str:
    """What the apps' panels reference by id: Tannoy's covers (the bar's
    media pill uses them too), Signal Box's and Timetable's shadows."""
    return apps.tannoy_defs() + apps.broker_defs() + apps.timetable_defs()


def css() -> str:
    return PULSE_CSS + "\n" + apps.logbook_css()


@dataclass
class Opening:
    """One time a panel is open: from `t_open` to `t_close`, sprung out of
    `anchor` (a module, or None for a window), showing each look from its
    time on."""
    panel: str
    anchor: str | None
    t_open: float
    t_close: float
    looks: list[tuple[float, str]]

    def look_at(self, t: float) -> str:
        key = self.looks[0][1]
        for when, k in self.looks:
            if when <= t + 1e-9:
                key = k
        return key

    def size(self) -> tuple[float, float]:
        """The widest and tallest of its looks: the box the camera frames."""
        ls = [look(self.panel, k) for _, k in self.looks]
        return max(lk.w for lk in ls), max(lk.h for lk in ls)


@dataclass
class Place:
    """Where an opening sits on screen: the left edge, the bottom edge every
    look is anchored to, and the point it springs out of."""
    x: float
    bottom: float
    origin: tuple[float, float]

    def screen(self, lk: apps.Look, sx: float, sy: float) -> tuple[float, float]:
        return (self.x + sx, self.bottom - lk.h + sy)


def place_above(anchor_x: float, bar_y: float, screen_w: float, w: float) -> Place:
    x = min(max(anchor_x - w / 2, 10), screen_w - 10 - w)
    return Place(x, bar_y - 8, (anchor_x, bar_y))


def place_window(screen_w: float, top: float, w: float, h: float) -> Place:
    x = (screen_w - w) / 2
    return Place(x, top + h, (x + w / 2, top + h / 2))


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


def shown_during(svg: Svg, spans, still: float, fade=0.18):
    name = svg.keyframes("opacity", visible_points(spans, fade=fade, loop=svg.loop))
    svg.add(f'<g class="a" style="animation-name:{name}" opacity="{1 if at(spans, still) else 0}">')


_drawn = 0


def panel(svg: Svg, o: Opening, p: Place, still: float) -> None:
    """One opening: springs open, crossfades between its looks (each at the
    same bottom edge), and folds back into its anchor."""
    global _drawn
    spring(svg, [(o.t_open, o.t_close)], p, still)
    svg.add(f'<g font-family="{apps.FONT}">')
    for i, (when, key) in enumerate(o.looks):
        until = o.looks[i + 1][0] if i + 1 < len(o.looks) else o.t_close + 0.4
        lk = look(o.panel, key)
        _drawn += 1
        body = apps.scoped(lk.svg, f"p{_drawn}")
        if len(o.looks) > 1:
            # The first look is there from the start, so the spring opens
            # on it; the last stays through the fold.
            shown_during(svg, [(0.0 if i == 0 else when, until if i + 1 < len(o.looks) else svg.loop)], still, fade=0.14)
        else:
            svg.add("<g>")
        svg.add(f'<g transform="translate({p.x:.1f},{p.bottom - lk.h:.1f})">{body}</g>')
        svg.add("</g>")
    svg.add("</g></g>")


# ------------------------------------------------------------ swaync

TOAST_W, TOAST_H = 400, 92
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
    svg.add(f'<rect x="0" y="0" width="6" height="{TOAST_H}" rx="3" fill="{FROST}"/>')
    svg.add(f'<rect x="3" y="0" width="5" height="{TOAST_H}" fill="{FROST}"/>')
    # The app's icon.
    svg.add(f'<rect x="20" y="16" width="60" height="60" rx="12" fill="#2e3440"/>')
    svg.text(50, 58, "", 32, "#e01e5a", 400, "middle")
    svg.text(96, 38, "Slack · #deploys", 15, FROST, 700)
    svg.text(96, 62, "storefront 4.2 is on staging", 14.5, "#d8dee9")
    svg.text(TOAST_W - 46, 38, "now", 13, "#5e81ac", 400, "end")
    svg.add(f'<rect x="{TOAST_W - 34}" y="16" width="22" height="22" rx="4" fill="#434c5e"/>')
    svg.text(TOAST_W - 23, 32, "×", 15, "#d8dee9", 400, "middle")
    svg.add("</g></g>")
