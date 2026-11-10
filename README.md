# Arch + Hyprland dotfiles

<p align="center">
  <img src="Pictures/bar/hero.svg" width="100%" alt="A Hyprland desktop with a waybar along the bottom. A build turns the Roundhouse lamp red; its drawer explains that memory is stalling and links to the Switchyard board, where the build finishes and the held one starts. Then the view zooms along the bar from left to right: the song pauses, the volume switches to the headset, the mouse battery runs low, dictation types into the editor, the meeting recorder and a pomodoro start, the key lights warm the room, the VPN connects, a swaync notification arrives and do not disturb silences it and hides the song title, and the clock switches time zones.">
</p>

<p align="center">
  <a href="docs/setting-up-archlinux.md"><img alt="Arch Linux" src="https://img.shields.io/badge/Arch_Linux-1793D1?style=flat-square&logo=arch-linux&logoColor=white"></a>
  <a href="packages/hyprland/.config/hypr"><img alt="Hyprland, Lua config" src="https://img.shields.io/badge/Hyprland-Lua_config-58E1FF?style=flat-square&logo=hyprland&logoColor=white"></a>
  <a href="packages/nvim/.config/nvim/README.md"><img alt="Neovim" src="https://img.shields.io/badge/Neovim-57A143?style=flat-square&logo=neovim&logoColor=white"></a>
  <a href="packages/zsh/.zshrc"><img alt="Zsh" src="https://img.shields.io/badge/Zsh-F15A24?style=flat-square&logo=zsh&logoColor=white"></a>
  <a href="docs/fonts.md"><img alt="PragmataPro" src="https://img.shields.io/badge/PragmataPro-1BB91F?style=flat-square"></a>
</p>

<p align="center">
  <a href="#quick-start">Quick start</a> ·
  <a href="#the-bar">The bar</a> ·
  <a href="#packages">Packages</a> ·
  <a href="#field-notes">Field notes</a> ·
  <a href="#rebuilding-a-machine">Rebuilding a machine</a>
</p>

My Arch Linux desktop: Hyprland, waybar, kitty, zsh and Neovim. Each tool is its own [GNU Stow](https://www.gnu.org/software/stow/) package, so you can take the bar or the editor and leave the rest. The configs stay compact and commented; the bar is where the effort went.

- **Hyprland in Lua.** There is no `hyprland.conf`. Binds, rules, monitors and idle are all [Lua files](packages/hyprland/.config/hypr).
- **A bar made of small scripts.** Each widget below is one script you can drop into your own waybar, and the table says what it needs.
- **Pictures that can't go stale.** The animation above and the widget strips are drawn from the real config and stylesheet by [`docs/bar/build.py`](docs/bar/README.md), not screenshotted, so they change when the bar does.
- **A one-reboot rebuild.** [`rebuild/`](rebuild/README.md) takes a blank machine from the Arch ISO to a working Hyprland session with every package installed.
- **[Field notes](#field-notes)** for the problems real hardware threw at it, so you don't lose the evening I did.

<p align="center">
  <img src="Pictures/desktop.png" width="100%" alt="A real screenshot of the desktop: Neovide with the waybar stylesheet and the Hyprland window rules side by side, kitty showing fastfetch, and the Roundhouse drawer open above the bar with CPU, GPU, memory, network and memory by app.">
  <br><sub>The real thing: Neovide on the waybar stylesheet and the Lua window rules, kitty, and the Roundhouse drawer open over the bar.</sub>
</p>

## Quick start

```bash
sudo pacman -S stow
git clone https://github.com/NathanielInman/dotfiles.git ~/Sites/dot-files
cd ~/Sites/dot-files

./install.sh -l              # list the packages
./install.sh waybar nvim     # link just those into ~
./install.sh -a              # or everything
```

`./install.sh -u nvim` removes a package and `./install.sh -r nvim` restows it after a pull. Stow refuses to overwrite a real file, so move an existing config aside before installing over it.

## The bar

Every widget in [`packages/waybar`](packages/waybar/.config/waybar), as it looks in the bar. The name links to the script or program behind it.

<!-- bar-widgets:start -->
| | Widget | What it does | Needs |
|---|---|---|---|
| <img src="Pictures/bar/widgets/currently-playing.svg" height="36" alt="Now playing"> | [Now playing](packages/waybar/.config/waybar/scripts/currently-playing.sh) | The current track from playerctl. Click for the previous track, right-click for the next, middle-click to pause. Hidden while do not disturb is on, so song titles stay off screen shares. | `playerctl`, `swaync` |
| <img src="Pictures/bar/widgets/roundhouse.svg" height="36" alt="Roundhouse"> | [Roundhouse](packages/roundhouse/.config/roundhouse/config.toml) | One lamp for the whole machine: green, amber, red. Click it for the [Roundhouse](https://github.com/NathanielInman/roundhouse) drawer: CPU, GPU, memory, disks and why the lamp is lit. | [Roundhouse](https://github.com/NathanielInman/roundhouse) |
| <img src="Pictures/bar/widgets/pulseaudio.svg" height="36" alt="Volume"> | [Volume](packages/waybar/.config/waybar/scripts/audio-switch.sh) | Volume and output. Click to switch the output, right-click to switch the input, middle-click for the mixer. | PipeWire (`wpctl`), `walker`, `pavucontrol` |
| <img src="Pictures/bar/widgets/mouse-battery.svg" height="36" alt="Mouse battery"> | [Mouse battery](packages/waybar/.config/waybar/scripts/mouse-battery.sh) | The Logitech mouse's charge, amber when low, red when nearly empty. | A Logitech mouse (kernel `hidpp` driver) |
| <img src="Pictures/bar/widgets/voxtype.svg" height="36" alt="Dictation"> | [Dictation](packages/waybar/.config/waybar/scripts/voxtype-status.sh) | [voxtype](https://voxtype.io) speech to text: hold a key, talk, and it types where the cursor is. Red while listening, amber while transcribing. | [voxtype](https://voxtype.io), `jq` |
| <img src="Pictures/bar/widgets/meeting-record.svg" height="36" alt="Meeting recorder"> | [Meeting recorder](packages/waybar/.config/waybar/scripts/meeting-record.sh) | Records a meeting in 15 minute chunks and transcribes them with voxtype afterwards. Shows only while recording. | `pw-record`, voxtype |
| <img src="Pictures/bar/widgets/screen-record.svg" height="36" alt="Screen recorder"> | [Screen recorder](packages/waybar/.config/waybar/scripts/screen-record.sh) | Records the screen with wf-recorder. Shows only while recording. | `wf-recorder`, `slurp`, `ffmpeg` |
| <img src="Pictures/bar/widgets/pomodoro.svg" height="36" alt="Pomodoro"> | [Pomodoro](packages/waybar/.config/waybar/scripts/pomodoro.sh) | 25 minutes of focus, then a 5 minute break. Click to start or pause, right-click to reset. | `notify-send` |
| <img src="Pictures/bar/widgets/keylights.svg" height="36" alt="Key lights"> | [Key lights](packages/waybar/.config/waybar/scripts/keylights.sh) | Both Elgato Key Lights on or off in one click, over the IoT network. | Elgato Key Lights, `curl` (set the light's IP in the script) |
| <img src="Pictures/bar/widgets/vpn.svg" height="36" alt="VPN"> | [VPN](packages/waybar/.config/waybar/scripts/vpn.sh) | Connects or drops the work VPN (openvpn3). Right-click lists the sessions. | `openvpn3` and an imported profile |
| <img src="Pictures/bar/widgets/silence-notifications.svg" height="36" alt="Do not disturb"> | [Do not disturb](packages/waybar/.config/waybar/config.jsonc) | Silences notifications (swaync). Also hides the song title while it is on. | `swaync` |
| <img src="Pictures/bar/widgets/switchyard.svg" height="36" alt="Switchyard"> | [Switchyard](packages/switchyard/.config/switchyard/config.toml) | The signal for [Switchyard](https://github.com/NathanielInman/switchyard), the board that builds, launches and deploys everything, one heavy build at a time: blue at rest, amber while building, green when it worked, red when it broke. | [Switchyard](https://github.com/NathanielInman/switchyard) |
| <img src="Pictures/bar/widgets/power-menu.svg" height="36" alt="Power"> | [Power](packages/waybar/.config/waybar/scripts/power-menu.sh) | Idle, lock, log out, suspend, reboot or shut down, through walker. | `walker`, `hyprlock`, `hypridle` |
| <img src="Pictures/bar/widgets/timezone.svg" height="36" alt="Clock"> | [Clock](packages/waybar/.config/waybar/scripts/timezone.sh) | The date and time. Click to cycle through Chicago, Eastern Europe and GMT; right-click for the calendar. | Nothing extra |
<!-- bar-widgets:end -->

To use one widget without the rest, copy its script into `~/.config/waybar/scripts/`, its block from [`config.jsonc`](packages/waybar/.config/waybar/config.jsonc) and its `#custom-<name>` rules from [`style.css`](packages/waybar/.config/waybar/style.css). The pomodoro, for example:

```jsonc
"custom/pomodoro": {
  "exec": "~/.config/waybar/scripts/pomodoro.sh",
  "interval": 1,
  "on-click": "~/.config/waybar/scripts/pomodoro.sh toggle",
  "on-click-right": "~/.config/waybar/scripts/pomodoro.sh reset",
  "return-type": "json"
}
```

## Packages

| | Package | What it holds |
| --- | --- | --- |
| Desktop | `hyprland` | Wayland compositor (Lua config), lock and idle |
| | `waybar` | The bar above |
| | `walker` | Application launcher, also used for menus |
| | `swaync` | Notification center |
| | `kitty` | Terminal |
| | `pipewire` | rtkit wait and WirePlumber no-suspend drop-ins |
| | `chrome` | Chrome Wayland flags |
| Shell | `zsh` | Zsh and Oh My Zsh |
| | `starship` | Prompt |
| | `nushell` | Second shell |
| Editors | `nvim` | Standalone lazy.nvim config ([README](packages/nvim/.config/nvim/README.md)) |
| | `vim` | Vim config |
| Dev tools | `git` | Git config with the delta pager |
| | `biome` | Global Biome formatter and linter config |
| | `cargo` | Cargo dev profile that keeps `target/` small |
| | `task` | Taskwarrior and vit |
| | `topgrade` | Upgrade everything in one command |
| | `t3code` | T3 Code color theme |
| Companions | `roundhouse` | Config for the Roundhouse drawer (see below) |
| | `switchyard` | Tasks for the Switchyard board (see below) |

### Companion programs

Three widgets are front ends for programs that live in their own repos. Install the program, then stow its package here (Signal Box needs nothing stowed: its module is already in the waybar config).

[**Roundhouse**](https://github.com/NathanielInman/roundhouse) is the lamp: one color for the health of the whole machine, and a drawer with CPU, GPU, memory pressure, network, every disk and share, and memory by app.

```bash
git clone https://github.com/NathanielInman/roundhouse.git ~/Sites/roundhouse
cd ~/Sites/roundhouse && cargo build --release
install -Dm755 target/release/rh target/release/rh-board -t ~/.local/bin/
cd ~/Sites/dot-files && ./install.sh roundhouse
```

[**Switchyard**](https://github.com/NathanielInman/switchyard) is the signal: a board that builds and launches the games, runs deploys and holds small desk scripts, one heavy build at a time.

```bash
git clone https://github.com/NathanielInman/switchyard.git ~/Sites/switchyard
~/Sites/switchyard/install.sh       # installs yard and yard-board, enables the user units
cd ~/Sites/dot-files && ./install.sh switchyard
```

[**Signal Box**](https://github.com/NathanielInman/credential-broker#signal-box) is the key: the secrets agents can use right now through broker, how long each has left, the requests nobody answered, and a revoke for all of it. It comes with credential-broker; the panel needs `gtk-layer-shell`.

```bash
sudo pacman -S --needed gtk-layer-shell
cd ~/Sites/credential-broker/packaging/aur/credential-broker-bin && makepkg -si
```

## Field notes

Fixes for things that broke on this machine, each written up where it lives:

- [NVIDIA hoards VRAM under Hyprland](docs/system-files.md#nvidia-hoards-vram-under-hyprland): one driver profile setting stops the leak. Downgrading doesn't.
- [Bluetooth headset stutters at full signal](docs/system-files.md#bluetooth-headset-stutters-at-full-signal): the PC had ended up as the peripheral. A udev rule switches it back on every link.
- [openvpn3 ignores the DNS the server pushes](docs/openvpn3-vpn-dns.md), so internal hosts don't resolve.
- [Don't name your launcher `start-hyprland`](docs/system-files.md#starting-hyprland-on-tty1): it shadows Hyprland's own crash watchdog.
- [Never losing uncommitted work](docs/sites-nightly-backup.md): a 3am job commits or snapshots every dirty repo in `~/Sites`.
- [A Claude Code statusline](docs/setting-up-archlinux.md#claude-code-statusline) with context, usage window and cost.
- [Drawing the README's bar from the real config](docs/bar/README.md), and adding a widget to it.

## Rebuilding a machine

[`docs/setting-up-archlinux.md`](docs/setting-up-archlinux.md) is the full guide for my desktop (Ryzen 9800X3D, RTX 3080, three NVMe drives) and explains why each package is there. [`rebuild/`](rebuild/README.md) scripts it with one reboot: `bootstrap.sh` and `10-live.sh` on the live ISO, `40-first-boot.sh` afterwards. A step that fails either stops and hands over to a person or, if it's minor, goes in `/var/log/rebuild/followups.md` for later.

[`pkglist/`](pkglist) lists every explicitly installed package, refreshed nightly, so a rebuild installs everything in one pass:

```bash
grep -v '^#' pkglist/repo.txt | sudo pacman -S --needed -
grep -v '^#' pkglist/aur.txt  | paru -S --needed -
```

Files outside `$HOME` (udev rules, systemd units, the NVIDIA profile, the Hyprland launcher) install with `./install.sh -s`. [`docs/system-files.md`](docs/system-files.md) says what each one does.

---

<p align="center">
  I'm Nathaniel Inman, a software engineer who makes roguelikes for fun.<br>
  <a href="https://nathanielinman.com">nathanielinman.com</a> ·
  <a href="https://github.com/NathanielInman">GitHub</a> ·
  <a href="https://www.linkedin.com/in/nathanielinman">LinkedIn</a> ·
  <a href="https://codepen.io/NathanielInman">CodePen</a>
</p>
