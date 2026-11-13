"""The README hero's story: Roundhouse and Switchyard first, then each app
in the suite opens out of its place in the bar, with the small widgets in
between, left to right.

Each beat happens at `t` seconds into the loop and may:

- `camera`: (zoom, module) zooms to `zoom` (1 is the whole desktop)
  centered on a module; (1.0, None) shows the whole desktop; "panel:<name>"
  frames that panel (open now or opening at this beat) with room for a
  caption. The camera starts moving at `t` and arrives `MOVE` seconds later.
- `click`: click a module (the cursor goes there; a ripple marks it), a
  spot in an open panel ("tannoy:chip:Chrome"; each app names its spots),
  "outside" (the desktop, which closes a panel), or a screen point (x, y).
- `hover`: move the cursor onto a module without clicking.
- `set`: put modules in new states, by name from widgets.py. A drawer
  group ("group/desk-drawer") is "open" or "closed".
- `open`: (panel, look) springs a panel out of its module (scenes.ANCHORS)
  showing that look; `via` names another module to spring it from.
- `look`: (panel, look) switches an open panel to another look.
- `close`: a panel's name, or a list of names, folds it back.
- `caption`: show "Name: text" until the next caption.
- `scene`: "type" (dictated words appear in the editor), "toast" /
  "toast-dismiss" (a swaync notification), "lights-on" / "lights-off" (the
  room warms up with the key lights).

The looks each panel can show are in scenes.LOOKS. Every module must be
back in its default state, and every panel closed, by the end of the loop.
"""

from dataclasses import dataclass, field

LOOP = 66.5  # seconds
MOVE = 0.7  # camera travel time
ZOOM = 2.3


@dataclass
class Beat:
    t: float
    camera: tuple[float, str | None] | str | None = None
    click: str | tuple[float, float] | None = None
    hover: str | None = None
    set: dict[str, str] = field(default_factory=dict)
    open: tuple[str, str] | None = None
    via: str | None = None
    look: tuple[str, str] | None = None
    close: str | list[str] | None = None
    caption: tuple[str, str] | None = None
    scene: str | None = None


DICTATED = "// back off and retry, give up after five tries"

BEATS: list[Beat] = [
    # Roundhouse and Switchyard: a heavy build turns the lamp red, the
    # drawer says why, and its link opens the board from the same lamp.
    Beat(0.6, set={"custom/switchyard": "building"}),
    Beat(0.9, camera=(2.0, "custom/roundhouse")),
    Beat(1.8, set={"custom/roundhouse": "act"},
         caption=("Roundhouse", "one lamp for the whole machine, red when it needs you")),
    Beat(2.9, camera="panel:roundhouse"),
    Beat(3.4, click="custom/roundhouse", open=("roundhouse", "act"),
         caption=("Roundhouse", "click it to see why: memory is stalling")),
    Beat(6.4, click="roundhouse:switchyard", close="roundhouse", open=("switchyard", "held"), via="custom/roundhouse",
         camera="panel:switchyard",
         caption=("Switchyard", "its link opens the build board: android is held until memory frees")),
    Beat(8.6, look=("switchyard", "done"), set={"custom/roundhouse": "calm"},
         caption=("Switchyard", "storefront finishes, the lamp calms, the held build starts")),
    Beat(10.6, click="outside", close="switchyard"),
    Beat(10.8, camera=(1.0, None)),

    # Tannoy: the player slides out of the cover.
    Beat(11.4, camera="panel:tannoy"),
    Beat(11.9, click="image#tannoy-art", open=("tannoy", "song"),
         caption=("Tannoy", "now playing, and the player slides out of the cover")),
    Beat(13.6, click="tannoy:chip:Chrome", look=("tannoy", "podcast"), set={"custom/tannoy": "podcast"},
         caption=("Tannoy", "pick which player the media keys follow")),
    Beat(15.4, click="outside", close="tannoy"),

    # Signal Box: an agent asks for a secret, a touch grants it, and the
    # panel shows everything live and revokes it.
    Beat(15.9, camera="panel:request", open=("request", "ask"), set={"custom/broker": "asking"},
         caption=("Signal Box", "an agent asks for a secret; broker asks you")),
    Beat(17.8, look=("request", "granted"), set={"custom/broker": "granted"},
         caption=("Signal Box", "a YubiKey touch grants it for an hour")),
    Beat(18.9, close="request"),
    Beat(19.2, camera="panel:signalbox"),
    Beat(19.7, click="custom/broker", open=("signalbox", "live"),
         caption=("Signal Box", "every secret agents can use right now, and for how long")),
    Beat(21.6, click="signalbox:revoke-all", look=("signalbox", "empty"), set={"custom/broker": "quiet"},
         caption=("Signal Box", "Revoke all, and the lamp goes dim")),
    Beat(23.0, click="custom/broker", close="signalbox"),

    # The small widgets in between.
    Beat(23.6, camera=(ZOOM, "pulseaudio")),
    Beat(24.2, click="pulseaudio", set={"pulseaudio": "headset"},
         caption=("Volume", "click to switch to the headset")),
    Beat(25.2, camera=(ZOOM, "custom/mouse-battery")),
    Beat(25.6, set={"custom/mouse-battery": "low"},
         caption=("Mouse battery", "amber when it needs charging")),

    # Logbook: a meeting on air, then its transcript.
    Beat(26.6, camera=(ZOOM, "custom/logbook")),
    Beat(27.0, set={"custom/logbook": "mic"},
         caption=("Logbook", "frost: Chrome has the mic, and Logbook says so")),
    Beat(28.2, camera="panel:logbook"),
    Beat(28.6, click="custom/logbook", open=("logbook", "mic")),
    Beat(29.8, click="logbook:record-meeting", look=("logbook", "onair"),
         set={"custom/logbook": "recording", "custom/silence-notifications": "on", "custom/tannoy": "hidden"},
         caption=("Logbook", "Record meeting: on air, and do not disturb hides the song")),
    Beat(31.4, click="logbook:mark", look=("logbook", "marked"),
         caption=("Logbook", "Mark the moment to come back to")),
    Beat(32.6, click="logbook:stop", look=("logbook", "transcribing"),
         set={"custom/logbook": "transcribing", "custom/silence-notifications": "off", "custom/tannoy": "podcast"},
         caption=("Logbook", "Stop: the transcript makes itself, one Switchyard task")),
    Beat(34.4, look=("logbook", "ready"), set={"custom/logbook": "mic"},
         caption=("Logbook", "ready to copy")),
    Beat(35.4, click="outside", close="logbook"),
    Beat(35.8, camera=(1.0, None), set={"custom/logbook": "dictating"}),
    Beat(36.2, scene="type",
         caption=("Dictation", "middle-click the lamp and talk; voxtype types where the cursor is")),
    Beat(37.8, set={"custom/logbook": "off"}),

    # The desk drawer: rarely touched toggles wait behind the arrow.
    Beat(38.4, camera=(ZOOM, "custom/desk-handle")),
    Beat(38.9, hover="custom/desk-handle", set={"group/desk-drawer": "open"},
         caption=("Desk", "the key lights and the power menu wait behind the arrow")),
    Beat(40.1, click="custom/keylights", set={"custom/keylights": "on", "custom/keylights#lit": "on"}, scene="lights-on",
         caption=("Key lights", "both Elgato lights in one click; lit, the lamp stays in view")),
    Beat(41.3, hover="custom/logbook", set={"group/desk-drawer": "closed"}),

    # Timetable: the clock says what's next.
    Beat(42.0, camera=(ZOOM, "custom/timetable"), set={"custom/timetable": "next"},
         caption=("Timetable", "the clock names the next meeting")),
    Beat(43.2, camera="panel:timetable"),
    Beat(43.6, click="custom/timetable", open=("timetable", "next"),
         caption=("Timetable", "three zones, Join, and the day with its free gaps")),
    Beat(45.4, click="timetable:focus", look=("timetable", "focus"), set={"custom/timetable": "focus"},
         caption=("Timetable", "a focus block that ends before the next meeting")),
    Beat(47.2, click="outside", close="timetable"),
    Beat(47.6, camera=(ZOOM, "custom/timetable")),
    Beat(48.2, set={"custom/timetable": "soon"},
         caption=("Timetable", "amber 10 minutes out")),
    Beat(49.3, set={"custom/timetable": "now"},
         caption=("Timetable", "red at start time; middle-click joins on workspace 2")),

    # Tablet: the VPN lamp, frost only while the tunnel works.
    Beat(50.6, camera=(ZOOM, "custom/tablet")),
    Beat(51.1, click="custom/tablet", set={"custom/tablet": "connecting"},
         caption=("Tablet", "one click starts the work VPN")),
    Beat(51.8, set={"custom/tablet": "signin"},
         caption=("Tablet", "amber while the web sign-in waits")),
    Beat(52.8, set={"custom/tablet": "held"},
         caption=("Tablet", "frost once the tunnel answers")),
    Beat(53.4, camera="panel:tablet"),
    Beat(53.8, click="custom/tablet", open=("tablet", "held"),
         caption=("Tablet", "probes check that the tunnel really works")),
    Beat(55.4, look=("tablet", "stale"), set={"custom/tablet": "stale"},
         caption=("Tablet", "connected, but nothing gets through: stale")),
    Beat(57.0, click="tablet:card:reconnect", look=("tablet", "reconnected"), set={"custom/tablet": "held"},
         caption=("Tablet", "one click reconnects")),
    Beat(58.4, click="outside", close="tablet"),
    Beat(58.8, camera=(1.0, None)),

    # A notification, and do not disturb puts it (and the song title) away.
    Beat(59.3, scene="toast",
         caption=("Notifications", "swaync, in the same Nord colors")),
    Beat(60.7, camera=(ZOOM, "custom/broker")),
    Beat(61.3, click="custom/silence-notifications", set={"custom/silence-notifications": "on"}, scene="toast-dismiss",
         caption=("Do not disturb", "silences them, and hides the song title for screen shares")),
    Beat(61.8, set={"custom/tannoy": "hidden"}),
    Beat(63.5, camera=(1.0, None)),

    # Back to rest.
    Beat(64.1, scene="lights-off",
         set={
             "custom/timetable": "free",
             "custom/keylights": "off",
             "custom/keylights#lit": "off",
             "custom/silence-notifications": "off",
             "custom/tannoy": "playing",
             "custom/broker": "live",
             "custom/logbook": "off",
             "custom/tablet": "off",
             "custom/switchyard": "idle",
             "pulseaudio": "speakers",
             "custom/mouse-battery": "ok",
         }),
]
