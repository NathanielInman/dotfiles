"""What each waybar module shows, state by state.

One entry per module in `modules-left` / `modules-right` of
packages/waybar/.config/waybar/config.jsonc, keyed by the module's name
there. `build.py` refuses to run while a module in the config has no entry,
so a new widget cannot slip into the bar without being described here.

Colors are not set here: they come from the real style.css, by the module's
CSS id (`#custom-pomodoro`) and the state's class (`.work`), the same way
waybar picks them.

A state's text is exactly what the module prints: an empty string hides the
module (waybar does the same). `ticking()` makes a counting timer.
"""

from dataclasses import dataclass, field


@dataclass
class State:
    # One string, or several shown one after another (`every` seconds each).
    text: str | list[str]
    # The CSS class the module gets in this state, if any.
    cls: str | None = None
    every: float = 1.0

    @property
    def frames(self) -> list[str]:
        return self.text if isinstance(self.text, list) else [self.text]


@dataclass
class Widget:
    name: str
    # One or two sentences for the README's widget table.
    what: str
    # The file that makes it, relative to the repo root.
    source: str
    # What to install (or own) before the widget works, for the README's
    # Needs column. Markdown; empty for widgets drawn only in the hero.
    needs: str = ""
    states: dict[str, State] = field(default_factory=dict)
    default: str = ""
    # "custom" for exec modules; "workspaces", "window" and "tray" are drawn
    # by build.py from the fields below.
    kind: str = "custom"
    # Workspaces: (name, active) pairs; window: the title; tray: icon
    # glyphs with their colors.
    items: list = field(default_factory=list)


def ticking(icon: str, minutes: int, seconds: int, count: int, cls: str) -> State:
    """A timer counting down one second per frame."""
    total = minutes * 60 + seconds
    frames = [f"{icon} {(total - i) // 60:02d}:{(total - i) % 60:02d}" for i in range(count)]
    return State(frames, cls)


WAYBAR = "packages/waybar/.config/waybar"
SONG = "Lofi Rails - Night Shift"

WIDGETS: dict[str, Widget] = {
    "hyprland/workspaces": Widget(
        "Workspaces",
        "One icon per workspace, each with a job (browser, chat, editor, notes); the active one is underlined.",
        f"{WAYBAR}/config.jsonc",
        kind="workspaces",
        items=[("1", False), ("2", False), ("4", True), ("5", False)],
    ),
    "hyprland/window": Widget(
        "Window title",
        "The focused window's title.",
        f"{WAYBAR}/config.jsonc",
        kind="window",
        items=["nvim  src/retry.ts"],
    ),
    "custom/currently-playing": Widget(
        "Now playing",
        "The current track from playerctl. Click for the previous track, right-click for the next, "
        "middle-click to pause. Hidden while do not disturb is on, so song titles stay off screen shares.",
        f"{WAYBAR}/scripts/currently-playing.sh",
        needs='`playerctl`, `swaync`',
        states={
            "playing": State(f"\uf04b  {SONG}"),
            "paused": State(f"\uf04c  {SONG}"),
            "hidden": State(""),
        },
        default="playing",
    ),
    "custom/roundhouse": Widget(
        "Roundhouse",
        "One lamp for the whole machine: green, amber, red. Click it for the "
        "[Roundhouse](https://github.com/NathanielInman/roundhouse) drawer: CPU, GPU, memory, disks and why the lamp is lit.",
        "packages/roundhouse/.config/roundhouse/config.toml",
        needs='[Roundhouse](https://github.com/NathanielInman/roundhouse)',
        states={
            "calm": State("\U000f0765", "calm"),
            "heads-up": State("\U000f0765", "heads-up"),
            "act": State("\U000f0765", "act"),
        },
        default="calm",
    ),
    "pulseaudio": Widget(
        "Volume",
        "Volume and output. Click to switch the output, right-click to switch the input, middle-click for the mixer.",
        f"{WAYBAR}/scripts/audio-switch.sh",
        needs='PipeWire (`wpctl`), `walker`, `pavucontrol`',
        states={
            "speakers": State("\uf028 42%"),
            "headset": State("\U000f02ce 42%"),
            "muted": State("\uf026 muted", "muted"),
        },
        default="speakers",
    ),
    "custom/mouse-battery": Widget(
        "Mouse battery",
        "The Logitech mouse's charge, amber when low, red when nearly empty.",
        f"{WAYBAR}/scripts/mouse-battery.sh",
        needs='A Logitech mouse (kernel `hidpp` driver)',
        states={
            "ok": State("\U000f037d 80%", "ok"),
            "low": State("\U000f037d 18%", "low"),
            "charging": State("\U000f06a5 64%", "charging"),
        },
        default="ok",
    ),
    "custom/voxtype": Widget(
        "Dictation",
        "[voxtype](https://voxtype.io) speech to text: hold a key, talk, and it types where the cursor is. "
        "Red while listening, amber while transcribing.",
        f"{WAYBAR}/scripts/voxtype-status.sh",
        needs='[voxtype](https://voxtype.io), `jq`',
        states={
            "idle": State("\U000f036c", "idle"),
            "recording": State("\U000f044a", "recording"),
            "transcribing": State("\u23f3", "transcribing"),
        },
        default="idle",
    ),
    "custom/meeting-record": Widget(
        "Meeting recorder",
        "Records a meeting in 15 minute chunks and transcribes them with voxtype afterwards. Shows only while recording.",
        f"{WAYBAR}/scripts/meeting-record.sh",
        needs='`pw-record`, voxtype',
        states={"off": State(""), "recording": State("\U000f0ede")},
        default="off",
    ),
    "custom/screen-record": Widget(
        "Screen recorder",
        "Records the screen with wf-recorder. Shows only while recording.",
        f"{WAYBAR}/scripts/screen-record.sh",
        needs='`wf-recorder`, `slurp`, `ffmpeg`',
        states={"off": State(""), "recording": State("\u23fa")},
        default="off",
    ),
    "custom/pomodoro": Widget(
        "Pomodoro",
        "25 minutes of focus, then a 5 minute break. Click to start or pause, right-click to reset.",
        f"{WAYBAR}/scripts/pomodoro.sh",
        needs='`notify-send`',
        states={
            "idle": State("\uf017", "idle"),
            "work": ticking("\uf017", 24, 59, 30, "work"),
            "break": ticking("\uf0f4", 4, 12, 30, "break"),
        },
        default="idle",
    ),
    "custom/keylights": Widget(
        "Key lights",
        "Both Elgato Key Lights on or off in one click, over the IoT network.",
        f"{WAYBAR}/scripts/keylights.sh",
        needs="Elgato Key Lights, `curl` (set the light's IP in the script)",
        states={"off": State("\U000f0335", "off"), "on": State("\U000f06e8", "on")},
        default="off",
    ),
    "custom/vpn": Widget(
        "VPN",
        "Connects or drops the work VPN (openvpn3). Right-click lists the sessions.",
        f"{WAYBAR}/scripts/vpn.sh",
        needs='`openvpn3` and an imported profile',
        states={
            "disconnected": State("\U000f0319", "disconnected"),
            "connected": State("\U000f0318", "connected"),
        },
        default="disconnected",
    ),
    "custom/silence-notifications": Widget(
        "Do not disturb",
        "Silences notifications (swaync). Also hides the song title while it is on.",
        f"{WAYBAR}/config.jsonc",
        needs='`swaync`',
        states={"off": State("\uf0f3"), "on": State("\uf1f6")},
        default="off",
    ),
    "custom/switchyard": Widget(
        "Switchyard",
        "The signal for [Switchyard](https://github.com/NathanielInman/switchyard), the board that builds, launches and deploys "
        "everything, one heavy build at a time: blue at rest, amber while building, green when it worked, red when it broke.",
        "packages/switchyard/.config/switchyard/config.toml",
        needs='[Switchyard](https://github.com/NathanielInman/switchyard)',
        states={
            "idle": State("\U000f0431", "idle"),
            "building": State("\U000f0431", "building"),
            "ok": State("\U000f0431", "ok"),
            "failed": State("\U000f0431", "failed"),
        },
        default="idle",
    ),
    "custom/power-menu": Widget(
        "Power",
        "Idle, lock, log out, suspend, reboot or shut down, through walker.",
        f"{WAYBAR}/scripts/power-menu.sh",
        needs='`walker`, `hyprlock`, `hypridle`',
        states={"on": State("\u23fb")},
        default="on",
    ),
    "custom/timezone": Widget(
        "Clock",
        "The date and time. Click to cycle through Chicago, Eastern Europe and GMT; right-click for the calendar.",
        f"{WAYBAR}/scripts/timezone.sh",
        needs='Nothing extra',
        states={
            "local": State(" Tue Nov 10  14:32"),
            "chicago": State("America/Chicago:  Tue Nov 10  14:32"),
            "eet": State("EET:  Tue Nov 10  22:32"),
        },
        default="local",
    ),
    "tray": Widget(
        "Tray",
        "Apps that keep running in the background.",
        f"{WAYBAR}/config.jsonc",
        kind="tray",
        items=[("\uf198", "#e01e5a"), ("\U000f066f", "#7289da"), ("\uf293", "#5e81ac")],
    ),
}
