"""The README hero's story: a short day at the desk, one widget at a time.

Each beat happens at `t` seconds into the loop and may:

- `camera`: zoom to `zoom` (1 is the whole desktop) centered on a module,
  or on the whole screen with `focus=None`. The camera starts moving at `t`
  and arrives `MOVE` seconds later.
- `click`: click a module (the cursor goes there; a ripple marks it), or a
  screen point given as (x, y).
- `set`: put modules in new states, by name from widgets.py.
- `caption`: show "Name: text" at the top until the next caption.
- `scene`: start a scene effect build.py knows: "type" (dictated words
  appear in the editor), "drawer-open" / "drawer-close" (Roundhouse's
  drawer), "lights-on" / "lights-off" (the room warms up).

To show off a new widget, add a few beats (and widen `LOOP` if needed).
Every state must be back to its default by the end of the loop.
"""

from dataclasses import dataclass, field

LOOP = 30.0  # seconds
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
    # The whole desk for a moment, then in close.
    Beat(1.6, camera=(ZOOM, "custom/pomodoro")),
    Beat(2.6, click="custom/pomodoro", set={"custom/pomodoro": "work"},
         caption=("Pomodoro", "25 minutes of focus, then a break")),
    # Do not disturb, and the song title it hides.
    Beat(4.6, camera=(ZOOM, "custom/silence-notifications")),
    Beat(5.5, click="custom/silence-notifications", set={"custom/silence-notifications": "on"},
         caption=("Do not disturb", "silences notifications")),
    Beat(6.6, camera=(ZOOM, "custom/currently-playing")),
    Beat(7.6, set={"custom/currently-playing": "hidden"},
         caption=("Now playing", "hides itself too, so songs stay off screen shares")),
    # A meeting gets recorded.
    Beat(9.2, camera=(ZOOM, "custom/meeting-record")),
    Beat(10.0, set={"custom/meeting-record": "recording"},
         caption=("Meeting recorder", "15 minute chunks, transcribed afterwards")),
    # Dictation into the editor.
    Beat(12.0, camera=(ZOOM, "custom/voxtype"), set={"custom/voxtype": "recording"},
         caption=("Dictation", "hold a key and talk")),
    Beat(13.4, camera=(1.0, None), set={"custom/voxtype": "transcribing"}),
    Beat(14.2, set={"custom/voxtype": "idle"}, scene="type",
         caption=("Dictation", "voxtype types it where the cursor is")),
    # A heavy build, the lamp, and why.
    Beat(15.6, camera=(1.6, "custom/roundhouse")),
    Beat(16.4, set={"custom/switchyard": "building"},
         caption=("Switchyard", "one heavy build at a time")),
    Beat(17.6, set={"custom/roundhouse": "act"},
         caption=("Roundhouse", "memory is stalling, so the next build waits")),
    Beat(19.0, click="custom/roundhouse", scene="drawer-open",
         caption=("Roundhouse", "click the lamp to see why")),
    Beat(21.4, click=(240.0, 200.0), scene="drawer-close",
         set={"custom/roundhouse": "calm", "custom/switchyard": "ok"}),
    # The room, and the time elsewhere.
    Beat(22.4, camera=(ZOOM, "custom/keylights")),
    Beat(23.2, click="custom/keylights", set={"custom/keylights": "on"}, scene="lights-on",
         caption=("Key lights", "both Elgato lights in one click")),
    Beat(25.0, camera=(ZOOM, "custom/timezone"), set={"custom/switchyard": "idle"}),
    Beat(25.8, click="custom/timezone", set={"custom/timezone": "eet"},
         caption=("Clock", "click for other time zones")),
    # Back to the whole desk; everything returns to rest.
    Beat(27.6, camera=(1.0, None), scene="lights-off",
         set={
             "custom/timezone": "local",
             "custom/keylights": "off",
             "custom/pomodoro": "idle",
             "custom/silence-notifications": "off",
             "custom/currently-playing": "playing",
             "custom/meeting-record": "off",
         }),
]
