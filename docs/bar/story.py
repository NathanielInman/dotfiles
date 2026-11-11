"""The README hero's story: Roundhouse and Switchyard first, then the rest of
the bar from left to right, one widget at a time.

Each beat happens at `t` seconds into the loop and may:

- `camera`: zoom to `zoom` (1 is the whole desktop) centered on a module,
  or on the whole screen with `focus=None`. The camera starts moving at `t`
  and arrives `MOVE` seconds later.
- `click`: click a module (the cursor goes there; a ripple marks it), a
  part of an open panel ("board:storefront", "drawer:switchyard"; the spots
  are in scenes.py), or a screen point given as (x, y).
- `set`: put modules in new states, by name from widgets.py.
- `caption`: show "Name: text" at the top until the next caption.
- `scene`: start a scene effect build.py knows: "type" (dictated words
  appear in the editor); "board-open" / "board-close" (Switchyard's board
  over its signal) and "drawer-open" (Roundhouse's drawer over the lamp),
  with "handoff" closing the drawer and opening the board from the lamp;
  the board's story ("storefront-build", "android-queue", "android-held",
  "storefront-done", "android-build"); "toast" / "toast-dismiss" (a swaync
  notification slides in and out); "lights-on" / "lights-off" (the room
  warms up).

To show off a new widget, add a few beats (and widen `LOOP` if needed).
Every state must be back to its default by the end of the loop.
"""

from dataclasses import dataclass, field

LOOP = 36.0  # seconds
MOVE = 0.7  # camera travel time
ZOOM = 2.3


@dataclass
class Beat:
    t: float
    camera: tuple[float, str | None] | None = None  # (zoom, module or None)
    click: str | tuple[float, float] | None = None
    set: dict[str, str] = field(default_factory=dict)
    caption: tuple[str, str] | None = None
    scene: str | None = None


DICTATED = "// back off and retry, give up after five tries"

BEATS: list[Beat] = [
    # The money shot first: a heavy build turns the lamp red, Roundhouse's
    # drawer says why, and its link opens Switchyard's board from the lamp.
    Beat(0.6, set={"custom/switchyard": "building"}, scene="storefront-build"),
    Beat(0.7, scene="android-queue"),
    Beat(0.9, camera=(2.0, "custom/roundhouse")),
    Beat(1.8, set={"custom/roundhouse": "act"}, scene="android-held",
         caption=("Roundhouse", "one lamp for the whole machine, red when it needs you")),
    Beat(2.9, camera=(1.0, None)),
    Beat(3.6, click="custom/roundhouse", scene="drawer-open",
         caption=("Roundhouse", "click it to see why: memory is stalling")),
    Beat(6.4, click="drawer:switchyard", scene="handoff",
         caption=("Switchyard", "its link opens the build board from the same lamp")),
    Beat(7.6, scene="storefront-done", set={"custom/roundhouse": "calm"},
         caption=("Switchyard", "storefront finishes, the lamp calms, the held build starts")),
    Beat(8.1, scene="android-build"),
    Beat(9.6, click=(300.0, 240.0), scene="board-close"),
    # Then the rest of the bar, left to right.
    Beat(10.2, camera=(ZOOM, "custom/tannoy")),
    Beat(11.0, click="custom/tannoy", set={"custom/tannoy": "paused"},
         caption=("Tannoy", "middle-click pauses, click opens the player")),
    Beat(12.4, camera=(ZOOM, "pulseaudio")),
    Beat(13.0, click="pulseaudio", set={"pulseaudio": "headset"},
         caption=("Volume", "click to switch to the headset")),
    Beat(14.2, camera=(ZOOM, "custom/mouse-battery"), set={"custom/switchyard": "ok"}),
    Beat(14.7, set={"custom/mouse-battery": "low"},
         caption=("Mouse battery", "amber when it needs charging")),
    Beat(15.8, camera=(ZOOM, "custom/logbook"), set={"custom/logbook": "dictating"},
         caption=("Logbook", "hold a key and talk; the lamp listens with you")),
    Beat(17.4, camera=(1.0, None), set={"custom/logbook": "off", "custom/switchyard": "idle"}),
    Beat(18.2, scene="type",
         caption=("Dictation", "voxtype types it where the cursor is")),
    Beat(20.0, camera=(ZOOM, "custom/logbook")),
    Beat(20.7, set={"custom/logbook": "recording"},
         caption=("Logbook", "a meeting on air; its transcript makes itself after")),
    Beat(21.8, camera=(ZOOM, "custom/timetable")),
    Beat(22.4, set={"custom/timetable": "focus"},
         caption=("Timetable", "a focus block that ends before the next meeting")),
    Beat(23.8, camera=(ZOOM, "custom/keylights")),
    Beat(24.4, click="custom/keylights", set={"custom/keylights": "on"}, scene="lights-on",
         caption=("Key lights", "both Elgato lights in one click")),
    Beat(25.8, camera=(ZOOM, "custom/vpn")),
    Beat(26.3, click="custom/vpn", set={"custom/vpn": "connected"},
         caption=("VPN", "one click for the work VPN")),
    # A notification arrives, and do not disturb puts it (and the song
    # title) away.
    Beat(27.6, camera=(1.0, None)),
    Beat(28.1, scene="toast",
         caption=("Notifications", "swaync, in the same Nord colors")),
    Beat(29.7, click="custom/silence-notifications", set={"custom/silence-notifications": "on"}, scene="toast-dismiss",
         caption=("Do not disturb", "silences them, and hides the song title for screen shares")),
    Beat(30.2, set={"custom/tannoy": "hidden"}),
    Beat(31.2, camera=(ZOOM, "custom/timetable"), set={"custom/timetable": "soon"},
         caption=("Timetable", "the clock says what's next, amber 10 minutes out")),
    Beat(32.4, set={"custom/timetable": "now"},
         caption=("Timetable", "red at start time; middle-click joins on workspace 2")),
    # Back to the whole desk; everything returns to rest.
    Beat(33.8, camera=(1.0, None), scene="lights-off",
         set={
             "custom/timetable": "free",
             "custom/keylights": "off",
             "custom/silence-notifications": "off",
             "custom/tannoy": "playing",
             "custom/logbook": "off",
             "custom/vpn": "disconnected",
             "pulseaudio": "speakers",
             "custom/mouse-battery": "ok",
         }),
]
