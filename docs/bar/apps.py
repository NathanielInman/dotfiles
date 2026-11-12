"""The panels the bar opens, drawn by the apps themselves.

Roundhouse, Switchyard, Signal Box (credential-broker), Tannoy, Timetable
and Logbook each draw their own README hero, and each hero.py keeps its
panel's code above a line that reads `# ---- end of the panel ----`. This
module runs that top part of each file (never the story below it, which
would write the app's own hero) and wraps the panel functions in one
shape: `Look`, one state of a panel as SVG in the panel's own pixels, with
the spots a story can click.

So when an app's interface changes, its own hero changes, and this tour
picks it up on the next build. The apps are read from sibling checkouts:
~/Sites/roundhouse and so on, or BAR_APPS=<dir> for another parent.
"""

import os
import re
import sys
from dataclasses import dataclass, field, replace
from functools import cache
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APPS = Path(os.environ.get("BAR_APPS", ROOT.parent))
MARK = "# ---- end of the panel ----"

HEROES = {
    "roundhouse": "roundhouse/docs/assets/hero.py",
    "switchyard": "switchyard/docs/assets/hero.py",
    "broker": "credential-broker/artwork/hero/hero.py",
    "tannoy": "tannoy/docs/assets/hero.py",
    "timetable": "timetable/docs/assets/hero.py",
    "logbook": "logbook/docs/assets/hero.py",
}

# The apps' heroes use the system's monospace (an <img> loads no fonts),
# and so do their panels here.
FONT = "JetBrains Mono, DejaVu Sans Mono, Menlo, Consolas, monospace"


@cache
def app(name: str) -> dict:
    """The namespace of an app's hero.py, run up to its panel mark."""
    path = APPS / HEROES[name]
    if not path.exists():
        sys.exit(f"apps.py: {path} is missing; clone {HEROES[name].split('/')[0]} beside dot-files or set BAR_APPS")
    src = path.read_text(encoding="utf-8")
    if MARK not in src:
        sys.exit(f"apps.py: {path} has no '{MARK}' line, so its panel can't be told from its story")
    ns = {"__name__": f"hero_{name}", "__file__": str(path)}
    exec(compile(src.split(MARK, 1)[0], str(path), "exec"), ns)  # noqa: S102
    return ns


@dataclass
class Look:
    """One state of a panel: its SVG with the top-left at (0, 0), its size,
    and where a story can click, name -> (x, y)."""
    svg: str
    w: float
    h: float
    spots: dict = field(default_factory=dict)


class StrPen:
    """A pen for the apps whose panels draw through add() and text()."""

    def __init__(self, text_fn=None):
        self.out: list[str] = []
        self._text = text_fn

    def add(self, s: str):
        self.out.append(s)

    def text(self, x, y, s, size=13, fill="#c5c8c6", weight=400, anchor="start", extra=""):
        s = s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        self.add(f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" fill="{fill}" font-weight="{weight}" '
                 f'text-anchor="{anchor}"{extra}>{s}</text>')

    def svg(self) -> str:
        return "".join(self.out)


def scoped(svg: str, prefix: str) -> str:
    """Renames the ids an SVG fragment defines (and its references to them),
    so two states of one panel can sit in the same file."""
    ids = set(re.findall(r'\sid="([^"]+)"', svg))
    if not ids:
        return svg
    pat = re.compile(r'(\sid="|url\(#|href="#)(' + "|".join(re.escape(i) for i in sorted(ids, key=len, reverse=True)) + r')(["\)])')
    return pat.sub(lambda m: f"{m.group(1)}{prefix}-{m.group(2)}{m.group(3)}", svg)


# ------------------------------------------------------------ Roundhouse

def roundhouse(level="calm", yard="building", tab="machine") -> Look:
    """The drawer on `tab` at a lamp `level`, the dot on its Switchyard link
    colored by Switchyard's phase `yard`."""
    rh = app("roundhouse")
    out: list[str] = []
    rh["drawer"](out.append, tab=tab, level=level, yard=yard, clip="rh")
    return Look("".join(out), rh["DRAWER_W"], rh["drawer_height"](tab, level), dict(rh["DRAWER_SPOTS"]))


# ------------------------------------------------------------ Switchyard

def switchyard(story: str, roundhouse_color: str) -> Look:
    """The board at a moment of the tour's story: "build" (storefront on the
    main line, android queued behind it), "held" (Roundhouse holds android)
    or "done" (storefront finished, android on the main line). The link to
    Roundhouse is dotted with the lamp's color."""
    sy = app("switchyard")
    task, tasks = sy["task"], sy["TASKS"]
    held = task("android", "APK to emulator", "held: Roundhouse says act", "waiting", "g")
    queued = tasks["android"][0]
    tiles = {
        "build": {"storefront": tasks["storefront"][0], "android": queued},
        "held": {"storefront": tasks["storefront"][0], "android": held},
        "done": {"storefront": tasks["storefront"][1], "android": tasks["android"][1]},
    }[story]
    mainline = "android" if story == "done" else "storefront"
    pen = sy["Pen"]()
    h = sy["BH_GRID"]
    sy["board_panel"](pen, h)
    sy["board_header"](pen, roundhouse=roundhouse_color)
    label, used, cap, waiting = sy["MAINLINE"][mainline]
    sy["board_mainline"](pen, label, used, cap, "" if story == "held" else waiting)
    for i, name in enumerate(sy["ORDER"]):
        t = tiles.get(name) or tasks[name][1 if name == "ledger-api" else 0]
        if name == "ledger-api":
            t = tasks[name][2]  # idle: this tour has no failure to show
        sy["board_tile"](pen, sy["GX"][i % 4], sy["GY"][i // 4], t)
    sy["board_recent"](pen, sy["RECENT"])
    sy["board_footer"](pen, h, sy["GRID_HINTS"])
    spots = {k: v for k, v in sy["BOARD_SPOTS"].items()}
    svg = f'<g filter="url(#shadow)">{"".join(pen.out[:1])}</g>' + "".join(pen.out[1:])
    return Look(svg, sy["BW"], h, spots)


# ------------------------------------------------------------ Signal Box

def signal_box(state="live", h=580) -> Look:
    """The Signal Box panel: "live", "register" or "empty" (after Revoke
    all), `h` tall (the page takes the monitor's free height, up to 640)."""
    sb = app("broker")
    return Look(sb["sb_panel"](state, h, None, f"sb-{state}"), sb["SB_W"], h, dict(sb["SB_SPOTS"]))


def request_window(done=False) -> Look:
    """broker's request window: waiting for a YubiKey touch, or granted."""
    sb = app("broker")
    return Look(sb["request_window"](done), sb["RW"], sb["RH_DONE"] if done else sb["RH"])


def broker_defs() -> str:
    return app("broker")["SB_DEFS"]


# ------------------------------------------------------------ Tannoy

def tannoy(track="song", status="playing", picked=False, hidden=False) -> Look:
    """The drawer playing the Spotify song or the Chrome podcast."""
    tn = app("tannoy")
    t = tn["SONG"] if track == "song" else tn["POD"]
    if track == "song":
        players = (("Chrome", "paused"), ("Spotify", status))
    else:
        players = (("Chrome", status), ("Spotify", "paused"))
    s = tn["DrawerState"](t, status, hidden, players, picked)
    svg, h, spots = tn["draw_drawer"](s)
    return Look(svg, tn["DRAWER_W"], h, {k: tn["center"](v) for k, v in spots.items()})


def tannoy_defs() -> str:
    """The covers, as symbols #pod and #song; the bar's media pill uses them too."""
    return app("tannoy")["cover_defs"]()


# ------------------------------------------------------------ Timetable

def timetable(hh: int, mm: int, focus_min: int | None = None) -> Look:
    """The drawer at hh:mm on Tue Nov 10, with a focus block running for
    `focus_min` minutes from then if given."""
    tt = app("timetable")
    now = tt["hm"](hh, mm)
    b = tt["Board"](now, (now, now + focus_min * 60) if focus_min else None)
    w, h = tt["drawer_size"](b)
    return Look(tt["drawer"](b), w, h, dict(tt["drawer_spots"](b)))


def timetable_defs() -> str:
    return app("timetable")["DRAWER_DEFS"]


# ------------------------------------------------------------ Logbook

def logbook(moment: str) -> Look:
    """The drawer's Now tab at a moment of the tour: "mic" (Chrome has the
    mic), "onair", "marked", "transcribing" or "ready"."""
    lb = app("logbook")
    Now, Meeting, Job, Row = lb["Now"], lb["Meeting"], lb["Job"], lb["Row"]
    older = [
        Row("meeting", "today 10:02", "30 min · transcript ready", "Copy"),
        Row("screen", "today 09:15", "2:14 · recording-20261110-091532.mp4", "Open"),
        Row("meeting", "yesterday 14:30", "31 min · 2 marks · transcript ready", "Copy"),
    ]
    chrome = [("chrome", "Google Chrome", "Shure MV7")]
    new = "24 min · 1 mark"
    base = dict(others=chrome, recent=older, total=18, today=2)
    after = dict(others=chrome, total=19, today=3)
    s = {
        "mic": Now("mic", **base),
        "onair": Now("recording", Meeting("00:24:12", chunk=2), **base),
        "marked": Now("recording", Meeting("00:24:13", chunk=2, marks=["00:24:13"]), **base),
        "transcribing": Now("transcribing", job=Job("today 14:08", "switchyard", 2, 3, "~1 min left", 0.62),
                            recent=[Row("meeting", "today 14:08", f"{new} · transcribing")] + older, **after),
        "ready": Now("mic", recent=[Row("meeting", "today 14:08", f"{new} · transcript ready", "Copy")] + older, **after),
    }[moment]
    pen = StrPen()
    spots = lb["drawer"](pen, s)
    w, h = lb["drawer_size"](s)
    return Look(pen.svg(), w, h, spots)


def logbook_css() -> str:
    return app("logbook")["METER_CSS"]


__all__ = ["Look", "FONT", "scoped", "replace"]
