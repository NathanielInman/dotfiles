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

The camera settles once per app. Frame the panel before its lamp changes
("panel:<name>" works ahead of the opening) and stay there through the
lamp, the panel and its clicks; go from one app straight to the next. Zoom
on a module only when the beat has no panel (the volume, the desk) or the
lamp tells several beats on its own (Tablet connecting). Show the whole
desktop only for what happens out on it: dictation and the notification.
"""

from dataclasses import dataclass, field

LOOP = 70.6  # seconds
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
    Beat(5.0, camera="panel:roundhouse"),
    Beat(5.8, set={"custom/roundhouse": "act"},
         caption=("Roundhouse", "one lamp for the whole machine, red when it needs you")),
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

    # Waybill: an agent files a decision, and one click in the drawer rules.
    Beat(16.2, camera="panel:waybill"),
    Beat(16.9, set={"custom/waybill": "needs"},
         caption=("Waybill", "amber when the agents are waiting on you: a decision is open")),
    Beat(18.3, click="custom/waybill", open=("waybill", "asked"),
         caption=("Waybill", "what waits on you, decisions first")),
    Beat(20.3, click="waybill:option:0", look=("waybill", "ruled"), set={"custom/waybill": "calm"},
         caption=("Waybill", "one click rules, and the task goes back to the agents")),
    Beat(22.0, click="outside", close="waybill"),

    # Signal Box: an agent asks for a secret, a touch grants it, and the
    # panel shows everything live and revokes it.
    Beat(22.9, camera="panel:request", open=("request", "ask"), set={"custom/broker": "asking"},
         caption=("Signal Box", "an agent asks for a secret; broker asks you")),
    Beat(24.8, look=("request", "granted"), set={"custom/broker": "granted"},
         caption=("Signal Box", "a YubiKey touch grants it for an hour")),
    Beat(25.9, close="request"),
    Beat(26.2, camera="panel:signalbox"),
    Beat(26.7, click="custom/broker", open=("signalbox", "live"),
         caption=("Signal Box", "every secret agents can use right now, and for how long")),
    Beat(28.6, click="signalbox:revoke-all", look=("signalbox", "empty"), set={"custom/broker": "quiet"},
         caption=("Signal Box", "Revoke all, and the lamp goes dim")),
    Beat(30.0, click="custom/broker", close="signalbox"),

    # Tablet: the VPN lamp, frost only while the tunnel works.
    Beat(30.6, camera=(ZOOM, "custom/tablet")),
    Beat(31.1, click="custom/tablet", set={"custom/tablet": "connecting"},
         caption=("Tablet", "one click starts the work VPN")),
    Beat(31.8, set={"custom/tablet": "signin"},
         caption=("Tablet", "amber while the web sign-in waits")),
    Beat(32.8, set={"custom/tablet": "held"},
         caption=("Tablet", "frost once the tunnel answers")),
    Beat(33.4, camera="panel:tablet"),
    Beat(33.8, click="custom/tablet", open=("tablet", "held"),
         caption=("Tablet", "probes check that the tunnel really works")),
    Beat(35.4, look=("tablet", "stale"), set={"custom/tablet": "stale"},
         caption=("Tablet", "connected, but nothing gets through: stale")),
    Beat(37.0, click="tablet:card:reconnect", look=("tablet", "reconnected"), set={"custom/tablet": "held"},
         caption=("Tablet", "one click reconnects")),
    Beat(38.4, click="outside", close="tablet"),

    # Logbook: a meeting on air, then its transcript, then dictation.
    Beat(38.8, camera="panel:logbook"),
    Beat(39.2, set={"custom/logbook": "mic"},
         caption=("Logbook", "frost: Chrome has the mic, and Logbook says so")),
    Beat(40.6, click="custom/logbook", open=("logbook", "mic")),
    Beat(42.0, click="logbook:record-meeting", look=("logbook", "onair"),
         set={"custom/logbook": "recording", "custom/silence-notifications": "on",
              "custom/silence-notifications#on": "on", "custom/tannoy": "hidden"},
         caption=("Logbook", "Record meeting: on air, and do not disturb hides the song")),
    Beat(43.6, click="logbook:mark", look=("logbook", "marked"),
         caption=("Logbook", "Mark the moment to come back to")),
    Beat(44.8, click="logbook:stop", look=("logbook", "transcribing"),
         set={"custom/logbook": "transcribing", "custom/silence-notifications": "off",
              "custom/silence-notifications#on": "off", "custom/tannoy": "podcast"},
         caption=("Logbook", "Stop: the transcript makes itself")),
    Beat(46.6, look=("logbook", "ready"), set={"custom/logbook": "mic"},
         caption=("Logbook", "ready to copy")),
    Beat(47.6, click="outside", close="logbook"),
    Beat(48.0, camera=(1.0, None), set={"custom/logbook": "dictating"}),
    Beat(48.4, scene="type",
         caption=("Dictation", "middle-click the lamp and talk; voxtype types where the cursor is")),
    Beat(50.0, set={"custom/logbook": "off"}),

    # The notification arrives while the whole desktop is in view.
    Beat(50.2, scene="toast",
         caption=("Notifications", "swaync, in the same Nord colors")),

    # Audio.
    Beat(51.6, camera=(ZOOM, "pulseaudio")),
    Beat(52.2, click="pulseaudio", set={"pulseaudio": "headset"},
         caption=("Volume", "click to switch to the headset")),
    Beat(53.2, camera=(ZOOM, "custom/mouse-battery")),
    Beat(53.6, set={"custom/mouse-battery": "low"},
         caption=("Mouse battery", "amber when it needs charging")),

    # The desk: plain toggles wait behind the arrow, and what is on stays
    # in view when it closes.
    Beat(54.6, camera=(ZOOM, "custom/desk-handle")),
    Beat(55.1, hover="custom/desk-handle", set={"group/desk-drawer": "open"},
         caption=("Desk", "do not disturb, the key lights and the power menu wait behind the arrow")),
    Beat(56.2, click="custom/silence-notifications",
         set={"custom/silence-notifications": "on", "custom/silence-notifications#on": "on"}, scene="toast-dismiss",
         caption=("Do not disturb", "silences notifications, and hides the song title for screen shares")),
    Beat(56.7, set={"custom/tannoy": "hidden"}),
    Beat(57.6, click="custom/keylights", set={"custom/keylights": "on", "custom/keylights#lit": "on"}, scene="lights-on",
         caption=("Key lights", "both Elgato lights in one click")),
    Beat(58.8, hover="custom/timetable", set={"group/desk-drawer": "closed"},
         caption=("Desk", "whatever is on stays in view when the drawer closes")),

    # Timetable: the clock says what's next.
    Beat(59.8, camera="panel:timetable", set={"custom/timetable": "next"},
         caption=("Timetable", "the clock names the next meeting")),
    Beat(61.2, click="custom/timetable", open=("timetable", "next"),
         caption=("Timetable", "three zones, Join, and the day with its free gaps")),
    Beat(63.0, click="timetable:focus", look=("timetable", "focus"), set={"custom/timetable": "focus"},
         caption=("Timetable", "a focus block that ends before the next meeting")),
    Beat(64.8, click="outside", close="timetable"),
    Beat(65.2, camera=(ZOOM, "custom/timetable")),
    Beat(65.8, set={"custom/timetable": "soon"},
         caption=("Timetable", "amber 10 minutes out")),
    Beat(66.9, set={"custom/timetable": "now"},
         caption=("Timetable", "red at start time; middle-click joins on workspace 2")),
    Beat(68.2, camera=(1.0, None)),

    # Back to rest.
    Beat(69.0, scene="lights-off",
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
             "custom/waybill": "calm",
             "custom/switchyard": "idle",
             "pulseaudio": "speakers",
             "custom/mouse-battery": "ok",
         }),
]
