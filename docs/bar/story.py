"""The README hero's story: a short day at the desk, one widget at a time.

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
  "storefront-done", "android-build"); "lights-on" / "lights-off" (the room
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
    # Switchyard: the board behind the signal, one heavy build at a time.
    Beat(15.8, click="custom/switchyard", scene="board-open",
         caption=("Switchyard", "the board behind the signal: builds, launches, deploys")),
    Beat(17.0, click="board:storefront", scene="storefront-build", set={"custom/switchyard": "building"},
         caption=("Switchyard", "storefront builds on the main line")),
    Beat(18.2, click="board:android", scene="android-queue",
         caption=("Switchyard", "one heavy build at a time, so android queues")),
    Beat(19.4, click=(300.0, 240.0), scene="board-close"),
    # Roundhouse: the lamp turns red, the drawer says why, and links back.
    Beat(20.0, set={"custom/roundhouse": "act"}, scene="android-held",
         caption=("Roundhouse", "memory is stalling: the lamp turns red and android is held")),
    Beat(21.2, click="custom/roundhouse", scene="drawer-open",
         caption=("Roundhouse", "the drawer says why")),
    Beat(24.0, click="drawer:switchyard", scene="handoff",
         caption=("Roundhouse", "its Switchyard link opens the board from the same lamp")),
    Beat(25.2, scene="storefront-done", set={"custom/roundhouse": "calm"},
         caption=("Switchyard", "storefront is done, the lamp calms down, android starts")),
    Beat(25.7, scene="android-build"),
    Beat(27.4, click=(300.0, 240.0), scene="board-close"),
    # The room, and the time elsewhere.
    Beat(27.8, camera=(ZOOM, "custom/keylights")),
    Beat(28.6, click="custom/keylights", set={"custom/keylights": "on"}, scene="lights-on",
         caption=("Key lights", "both Elgato lights in one click")),
    Beat(30.4, camera=(ZOOM, "custom/timezone"), set={"custom/switchyard": "ok"}),
    Beat(31.2, click="custom/timezone", set={"custom/timezone": "eet"},
         caption=("Clock", "click for other time zones")),
    # Back to the whole desk; everything returns to rest.
    Beat(33.0, camera=(1.0, None), scene="lights-off",
         set={
             "custom/timezone": "local",
             "custom/keylights": "off",
             "custom/pomodoro": "idle",
             "custom/silence-notifications": "off",
             "custom/currently-playing": "playing",
             "custom/meeting-record": "off",
             "custom/switchyard": "idle",
         }),
]
