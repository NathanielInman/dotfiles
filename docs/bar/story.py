"""The README hero's story: each app in the suite opens out of its place in
the bar, left to right, with the small widgets and the desk drawer after
the lamps.

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

LOOP = 65.0  # seconds
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
    # Tannoy: the player slides out of the cover.
    Beat(0.6, camera="panel:tannoy"),
    Beat(1.1, click="image#tannoy-art", open=("tannoy", "song"),
         caption=("Tannoy", "now playing, and the player slides out of the cover")),
    Beat(2.8, click="tannoy:chip:Chrome", look=("tannoy", "podcast"), set={"custom/tannoy": "podcast"},
         caption=("Tannoy", "pick which player the media keys follow")),
    Beat(4.6, click="outside", close="tannoy"),

    # Roundhouse: a heavy build turns the lamp red, and the drawer says why.
    Beat(4.8, set={"custom/switchyard": "building"}),
    Beat(5.0, camera=(2.0, "custom/roundhouse")),
    Beat(5.8, set={"custom/roundhouse": "act"},
         caption=("Roundhouse", "one lamp for the whole machine, red when it needs you")),
    Beat(6.9, camera="panel:roundhouse"),
    Beat(7.3, click="custom/roundhouse", open=("roundhouse", "act"),
         caption=("Roundhouse", "click it to see why: memory is stalling")),
    Beat(9.5, look=("roundhouse", "calm"), set={"custom/roundhouse": "calm"},
         caption=("Roundhouse", "memory frees, and the lamp calms")),
    Beat(11.0, click="outside", close="roundhouse"),

    # Switchyard: the build board, from its own signal.
    Beat(11.4, camera="panel:switchyard"),
    Beat(11.8, click="custom/switchyard", open=("switchyard", "held"),
         caption=("Switchyard", "the build board: android waits until there is memory for it")),
    Beat(14.0, look=("switchyard", "done"),
         caption=("Switchyard", "storefront finishes, and android takes the main line")),
    Beat(15.8, click="outside", close="switchyard"),
    Beat(16.0, camera=(1.0, None)),

    # Signal Box: an agent asks for a secret, a touch grants it, and the
    # panel shows everything live and revokes it.
    Beat(16.5, camera="panel:request", open=("request", "ask"), set={"custom/broker": "asking"},
         caption=("Signal Box", "an agent asks for a secret; broker asks you")),
    Beat(18.4, look=("request", "granted"), set={"custom/broker": "granted"},
         caption=("Signal Box", "a YubiKey touch grants it for an hour")),
    Beat(19.5, close="request"),
    Beat(19.8, camera="panel:signalbox"),
    Beat(20.3, click="custom/broker", open=("signalbox", "live"),
         caption=("Signal Box", "every secret agents can use right now, and for how long")),
    Beat(22.2, click="signalbox:revoke-all", look=("signalbox", "empty"), set={"custom/broker": "quiet"},
         caption=("Signal Box", "Revoke all, and the lamp goes dim")),
    Beat(23.6, click="custom/broker", close="signalbox"),

    # Tablet: the VPN lamp, frost only while the tunnel works.
    Beat(24.2, camera=(ZOOM, "custom/tablet")),
    Beat(24.7, click="custom/tablet", set={"custom/tablet": "connecting"},
         caption=("Tablet", "one click starts the work VPN")),
    Beat(25.4, set={"custom/tablet": "signin"},
         caption=("Tablet", "amber while the web sign-in waits")),
    Beat(26.4, set={"custom/tablet": "held"},
         caption=("Tablet", "frost once the tunnel answers")),
    Beat(27.0, camera="panel:tablet"),
    Beat(27.4, click="custom/tablet", open=("tablet", "held"),
         caption=("Tablet", "probes check that the tunnel really works")),
    Beat(29.0, look=("tablet", "stale"), set={"custom/tablet": "stale"},
         caption=("Tablet", "connected, but nothing gets through: stale")),
    Beat(30.6, click="tablet:card:reconnect", look=("tablet", "reconnected"), set={"custom/tablet": "held"},
         caption=("Tablet", "one click reconnects")),
    Beat(32.0, click="outside", close="tablet"),

    # Logbook: a meeting on air, then its transcript, then dictation.
    Beat(32.4, camera=(ZOOM, "custom/logbook")),
    Beat(32.8, set={"custom/logbook": "mic"},
         caption=("Logbook", "frost: Chrome has the mic, and Logbook says so")),
    Beat(34.0, camera="panel:logbook"),
    Beat(34.4, click="custom/logbook", open=("logbook", "mic")),
    Beat(35.6, click="logbook:record-meeting", look=("logbook", "onair"),
         set={"custom/logbook": "recording", "custom/silence-notifications": "on",
              "custom/silence-notifications#on": "on", "custom/tannoy": "hidden"},
         caption=("Logbook", "Record meeting: on air, and do not disturb hides the song")),
    Beat(37.2, click="logbook:mark", look=("logbook", "marked"),
         caption=("Logbook", "Mark the moment to come back to")),
    Beat(38.4, click="logbook:stop", look=("logbook", "transcribing"),
         set={"custom/logbook": "transcribing", "custom/silence-notifications": "off",
              "custom/silence-notifications#on": "off", "custom/tannoy": "podcast"},
         caption=("Logbook", "Stop: the transcript makes itself")),
    Beat(40.2, look=("logbook", "ready"), set={"custom/logbook": "mic"},
         caption=("Logbook", "ready to copy")),
    Beat(41.2, click="outside", close="logbook"),
    Beat(41.6, camera=(1.0, None), set={"custom/logbook": "dictating"}),
    Beat(42.0, scene="type",
         caption=("Dictation", "middle-click the lamp and talk; voxtype types where the cursor is")),
    Beat(43.6, set={"custom/logbook": "off"}),

    # Audio.
    Beat(44.0, camera=(ZOOM, "pulseaudio")),
    Beat(44.6, click="pulseaudio", set={"pulseaudio": "headset"},
         caption=("Volume", "click to switch to the headset")),
    Beat(45.6, camera=(ZOOM, "custom/mouse-battery")),
    Beat(46.0, set={"custom/mouse-battery": "low"},
         caption=("Mouse battery", "amber when it needs charging")),

    # The desk: plain toggles wait behind the arrow, and what is on stays
    # in view when it closes.
    Beat(47.0, camera=(1.0, None)),
    Beat(47.4, scene="toast",
         caption=("Notifications", "swaync, in the same Nord colors")),
    Beat(48.8, camera=(ZOOM, "custom/desk-handle")),
    Beat(49.3, hover="custom/desk-handle", set={"group/desk-drawer": "open"},
         caption=("Desk", "do not disturb, the key lights and the power menu wait behind the arrow")),
    Beat(50.4, click="custom/silence-notifications",
         set={"custom/silence-notifications": "on", "custom/silence-notifications#on": "on"}, scene="toast-dismiss",
         caption=("Do not disturb", "silences them, and hides the song title for screen shares")),
    Beat(50.9, set={"custom/tannoy": "hidden"}),
    Beat(51.8, click="custom/keylights", set={"custom/keylights": "on", "custom/keylights#lit": "on"}, scene="lights-on",
         caption=("Key lights", "both Elgato lights in one click")),
    Beat(53.0, hover="custom/timetable", set={"group/desk-drawer": "closed"},
         caption=("Desk", "whatever is on stays in view when the drawer closes")),

    # Timetable: the clock says what's next.
    Beat(54.0, camera=(ZOOM, "custom/timetable"), set={"custom/timetable": "next"},
         caption=("Timetable", "the clock names the next meeting")),
    Beat(55.2, camera="panel:timetable"),
    Beat(55.6, click="custom/timetable", open=("timetable", "next"),
         caption=("Timetable", "three zones, Join, and the day with its free gaps")),
    Beat(57.4, click="timetable:focus", look=("timetable", "focus"), set={"custom/timetable": "focus"},
         caption=("Timetable", "a focus block that ends before the next meeting")),
    Beat(59.2, click="outside", close="timetable"),
    Beat(59.6, camera=(ZOOM, "custom/timetable")),
    Beat(60.2, set={"custom/timetable": "soon"},
         caption=("Timetable", "amber 10 minutes out")),
    Beat(61.3, set={"custom/timetable": "now"},
         caption=("Timetable", "red at start time; middle-click joins on workspace 2")),
    Beat(62.6, camera=(1.0, None)),

    # Back to rest.
    Beat(63.4, scene="lights-off",
         set={
             "custom/timetable": "free",
             "custom/keylights": "off",
             "custom/keylights#lit": "off",
             "custom/silence-notifications": "off",
             "custom/silence-notifications#on": "off",
             "custom/tannoy": "playing",
             "custom/broker": "live",
             "custom/logbook": "off",
             "custom/tablet": "off",
             "custom/switchyard": "idle",
             "pulseaudio": "speakers",
             "custom/mouse-battery": "ok",
         }),
]
