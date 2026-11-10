"""Drawing primitives shared by build.py and scenes.py: the embedded font,
an SVG builder that collects keyframes, and visibility timelines."""

import base64
import io
import logging
import os
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

logging.getLogger("fontTools.subset").setLevel(logging.ERROR)

FONT_PATH = Path(os.environ.get("BAR_FONT", "/usr/share/fonts/TTF/JetBrainsMonoNerdFontPropo-Regular.ttf"))
FONT_BOLD = Path(os.environ.get("BAR_FONT_BOLD", str(FONT_PATH).replace("-Regular", "-Bold")))

# Nord, as the desktop, the bar and both sibling apps use it.
BG0, BG1 = "#14171c", "#0d0f12"
WIN, WIN_LINE, WIN_BAR = "#1d2025", "#353a42", "#262a30"
FG, DIM, FAINT, IDLE = "#c5c8c6", "#7c838e", "#4c566a", "#555b64"
FROST, GO, CAUTION, STOP, VIOLET, ORANGE = "#88c0d0", "#a3be8c", "#ebcb8b", "#bf616a", "#b48ead", "#d08770"
PANEL, PANEL_LINE, TILE, TILE_LINE, DARK = "#25282c", "#41464e", "#2c2f34", "#363a40", "#1d2024"


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
    # Keep the font's own timestamp, so a rebuild with no changes writes the
    # same bytes and leaves git clean.
    f = TTFont(font.path, recalcTimestamp=False)
    s.subset(f)
    buf = io.BytesIO()
    f.flavor = "woff"
    f.save(buf)
    return base64.b64encode(buf.getvalue()).decode()


def esc(s: str) -> str:
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


class Svg:
    def __init__(self, loop: float):
        self.loop = loop
        self.body: list[str] = []
        self.css: list[str] = []
        self.chars = {"bar": set(), "bold": set()}
        self.n = 0

    def add(self, s: str):
        self.body.append(s)

    def text(self, x, y, s, size=15, fill=FG, weight=400, anchor="start", extra=""):
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
        # Points past the end of the loop (a fade that would run over) drop.
        pts = sorted((p for p in points if p[0] <= self.loop + 1e-9), key=lambda p: p[0])
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


def visible_points(intervals, fade=0.07, loop=None):
    """Opacity points for an element visible during the given intervals.
    `loop` is only used to leave an interval that runs to the end open."""
    loop = float("inf") if loop is None else loop
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


def width(s: str, size: float, weight: int = 400) -> float:
    return (BOLD if weight >= 600 else REG).width(s, size)


def fit(s: str, size: float, room: float, weight: int = 400) -> str:
    """`s` cut with an ellipsis to fit `room` pixels, as GTK ellipsizes."""
    if width(s, size, weight) <= room:
        return s
    while s and width(s + "\u2026", size, weight) > room:
        s = s[:-1]
    return s.rstrip() + "\u2026"
