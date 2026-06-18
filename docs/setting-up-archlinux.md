# Setting Up Archlinux

## Install Method

**FROSTYARCH was installed with [`archinstall`](https://wiki.archlinux.org/title/Archinstall).** It handles partitioning, filesystem, bootloader, swap, locale, networking, and user creation — so the old manual cfdisk/mdadm/LVM/grub flow is gone. Just pick the right options in the installer.

### Selections to choose during archinstall

- **Mirror region** — your country
- **Locale** — language `en_US.UTF-8`, keymap `us`
- **Timezone** — `America/Chicago` (US/Central)
- **Disk configuration** — select **`nvme0n1` only**, best-effort default partitioning, filesystem **btrfs** (with subvolumes). Leave `nvme1n1` untouched — it becomes the separate `~/Sites` drive afterward.
- **Disk encryption** — none (this machine is unencrypted by choice)
- **Bootloader** — **Limine**
- **Swap** — enable **zram**
- **Hostname** — `FROSTYARCH`
- **Root password** — set one (or leave unset; tty1 autologin + NOPASSWD sudo are configured in First Boot)
- **User account** — create `nate` and mark it a **superuser** (adds it to `wheel`)
- **Profile** — **Minimal** (no desktop environment; Hyprland is installed manually below)
- **Audio** — **Pipewire**
- **Kernels** — `linux`
- **Network configuration** — **systemd-networkd** (i.e. *not* NetworkManager; the networkd default works on wired). Note: `network-manager-applet` in the Hyprland package list below is then an unused no-op — harmless, remove if you like.
- **Additional packages** — optional (e.g. `git vim`); microcode (`amd-ucode`) is auto-detected

The resulting layout: single `nvme0n1`, **btrfs** on LVM (`ArchinstallVg-root`, subvol `@`), **zram** swap, **limine** bootloader, `amd-ucode`.

> [!IMPORTANT]
> Use UUIDs for **every** `/etc/fstab` entry, including `/boot` — NVMe enumeration order (`nvme0` vs `nvme1`) is not stable across reboots. Find them with `lsblk -f` or `blkid`.

After `archinstall` finishes, continue at [First Boot](#first-boot).

## First Boot

Now after boot, login with `root` with the configured password and unncomment `multilib` within:
if u have issues with timing out due to /tmp, just remove it from `/etc/fstab`

```
sudo ln -s /usr/bin/vim /usr/bin/vi # make sure we always use vim instead of vi
vim /etc/pacman.conf
```

Now lets update everything:

```
pacman -Syyu
```

Enable weekly automatic cleanup of the pacman package cache (keeps the last 3 versions of each package). This prevents `/` from filling up over time:

```
pacman -S pacman-contrib
systemctl enable paccache.timer --now
```

Sound and bluetooth. PipeWire replaces PulseAudio and is enabled **per-user** later (not system-wide), so here we only install the stack and enable bluetooth at the system level.

- `alsa-utils` - command line alteration of audio levels on alsa's kernel level sound mixer
- `pipewire` - a new low-level multimedia framework compared to pulseaudio or alsa
- `wireplumber` - a policy manager for pipewire, allowing lua plugins
- `pipewire-audio` - the default audio server for pipewire
- `pipewire-alsa` - provides support for older ALSA API applications
- `pipewire-pulse` - provides support for older pulse audio API applications
- `bluez` - bluetooth protocol stack
- `bluez-utils` - provides bluetoothctl utility
- `blueberry` - bluetooth GUI applet (**AUR** — install with `yay`, not pacman)

```
pacman -S alsa-utils pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse bluez bluez-utils
yay -S blueberry
systemctl enable bluetooth.service --now
```

Now for installing window manager stuff (Hyprland)

- `hyprland` - tiling Wayland compositor with dynamic tiling, animations, and scripting
- `waybar` - highly customizable bar for Wayland compositors
- `walker` - Wayland-native GTK4 application launcher (requires `elephant` provider daemon)
- `elephant-all` - general-purpose data provider daemon for walker (includes all providers)
- `swaync` - notification center with history panel for Wayland
- `kitty` - GPU-accelerated terminal emulator with ligature support
- `network-manager-applet` - gui layer for managing network apps & vpn
- `noto-fonts` - emoji extras & base fonts
- `adobe-source-code-pro-fonts` - additional fallback fonts
- `otf-font-awesome` - additional fallback fonts
- `ttf-droid` - additional fallback fonts
- `ttf-fira-code` - additional fallback fonts
- `ttf-jetbrains-mono` - additional fallback fonts
- `ttf-jetbrains-mono-nerd` - additional fallback fonts
- `swww` - wallpaper daemon for Wayland
- `wl-clipboard` - command-line clipboard utilities for Wayland (wl-copy, wl-paste)
- `copyq` - clipboard manager with searchable history and system tray
- `blueman` - Bluetooth manager with system tray applet
- `grim` - screenshot utility for Wayland
- `slurp` - region selection tool for Wayland screenshots
- `swappy` - screenshot annotation tool
- `hyprlock` - screen locker for Hyprland
- `hypridle` - idle management daemon for Hyprland
- `pamixer` - pulseaudio/pipewire CLI mixer
- `playerctl` - MPRIS media player controller
- `brightnessctl` - brightness control utility
- `xdg-desktop-portal-hyprland` - desktop portal backend for Hyprland
- `qt5-wayland` - Qt5 Wayland platform plugin
- `qt6-wayland` - Qt6 Wayland platform plugin
- `bc` - tiny precision calculator used for netstats averaging
- `xdg-user-dirs` - help ensure well-known user directories are created automatically
- `xdg-utils` - for helpful things such as mime detection
- `yad` - GTK dialog tool; powers the waybar hotkeys (⌨) and commands cheat-sheet buttons
- `wf-recorder` - screen recording backend for the Super+R / waybar screen-record script
- `hyprpicker` - screen color picker bound to Super+I

```
pacman -S hyprland waybar swaync kitty network-manager-applet noto-fonts adobe-source-code-pro-fonts otf-font-awesome ttf-droid ttf-fira-code ttf-jetbrains-mono ttf-jetbrains-mono-nerd swww wl-clipboard copyq yad blueman grim slurp swappy wf-recorder hyprlock hypridle hyprpicker pamixer playerctl brightnessctl xdg-desktop-portal-hyprland qt5-wayland qt6-wayland bc xdg-user-dirs xdg-utils
yay -S walker elephant-all
```

No display manager is needed. Hyprland auto-launches via `.zshrc` when logging in on tty1, and getty autologin handles the login (configured below).

Before we can start Hyprland we need graphics drivers, validate what we're using

```
lspci -v | grep -A1 -e VGA -e 3D
```

Now acquire graphics packages (if issues see [here](https://github.com/JaKooLit/Arch-Hyprland/blob/main/install-scripts/nvidia.sh)):

> The proprietary `nvidia` / `nvidia-dkms` packages no longer exist in current Arch — only the **open kernel modules** remain. Use `nvidia-open`, which is correct for Turing (GTX 1650) and newer.

- `nvidia-open` - open NVIDIA kernel modules (replaces `nvidia`/`nvidia-dkms`)
- `nvidia-settings` - configure nvidia options through cli or gui
- `nvidia-utils` - userspace libraries and tools
- `libva` - hardware video acceleration offloads cpu usage to gpu
- `libva-nvidia-driver` - translation layer for libva to nvidia (now in **extra**, no `-git`)
- `egl-wayland` - EGLStream-based Wayland external platform

```
pacman -S nvidia-open nvidia-utils nvidia-settings libva libva-nvidia-driver egl-wayland
```

Configure the modules for Wayland/KMS so the framebuffer comes up early and survives suspend:

```
# /etc/mkinitcpio.conf — load the modules early and DROP the kms hook (stops nouveau)
MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
# HOOKS=(... remove 'kms' ...)

# /etc/modprobe.d/nvidia.conf
options nvidia_drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1

# /etc/modprobe.d/nouveau-blacklist.conf
blacklist nouveau

# /boot/limine/limine.conf — append to the kernel cmdline
nvidia_drm.modeset=1 nvidia_drm.fbdev=1
```

Regenerate the initramfs and reboot to activate the modules:

```
mkinitcpio -P
```

The Wayland env vars (`LIBVA_DRIVER_NAME=nvidia`, `GBM_BACKEND=nvidia-drm`, etc.) are exported by the `start-hyprland` launcher (`scripts/start-hyprland`, install to `/usr/local/bin/start-hyprland`), which `.zshrc` runs on tty1 login.

If you have multiple monitors and need to set them up, here are some helpful commands

```
hyprctl monitors # list all connected monitors with names, resolutions, positions
```

Monitor configuration is handled in `~/.config/hypr/hyprland.conf`:

```
monitor = DP-1, preferred, auto, 1
monitor = DP-2, preferred, auto, 1
# or with explicit resolution/position:
# monitor = DP-1, 2560x1440@144, 0x0, 1
# monitor = DP-2, 2560x1440@144, 2560x0, 1
```

Your user (`nate`) was created during archinstall and added to `wheel`. For passwordless sudo, add a drop-in rule (safer than editing `/etc/sudoers` directly; `visudo -c` validates it):

```
echo '%wheel ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/10-wheel-nopasswd
sudo visudo -c
```

finally set the default editor for all users to vim save this to `vim /etc/profile.d/editor.sh`

```
export EDITOR=vim
```

helpful non-user-specific applications

- `ntp` (network-time-protocol) helps ensure we're always time synchronized
- `unzip` - obviously helps us w/ zip files
- `gnome-keychain` - helps us maintain a keychain across different apps
- `libsecret` - library necessary for gnome-keychain

Note: `numlockx` is not needed - Hyprland handles numlock via `input { numlock_by_default = 1 }` in hyprland.conf

```
pacman -S unzip ntp gnome-keychain libsecret
```

ensure time synchronization service is started and activated

```
systemctl enable ntpd.service --now
```

login to user

```
login
```

Let's enable pipewire for the user (pipewire replaces pulseaudio as the sound server, `pamixer` is the CLI mixer)

```
systemctl --user enable pipewire pipewire-pulse wireplumber --now
```

Now disable node suspend/idle (when zoom is quiet, the pipewire sink can take a second or two to wake up and clip the start of sentences). The `pw-metadata` runtime commands don't survive a reboot, so use a **persistent WirePlumber drop-in** instead:

```
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
cat > ~/.config/wireplumber/wireplumber.conf.d/50-no-suspend.conf <<'EOF'
# Disable node suspend/idle so the start of audio (e.g. Zoom) isn't clipped.
monitor.alsa.rules = [
  {
    matches = [ { node.name = "~alsa_output.*" } { node.name = "~alsa_input.*" } ]
    actions = { update-props = { session.suspend-timeout-seconds = 0 } }
  }
]
EOF
systemctl --user restart wireplumber.service
```

Ensure we're automatically logged in, `systemctl edit getty@tty1.service` and add:

```
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin nate --noclear %I $TERM
```

Hyprland auto-launches from `.zshrc` when on tty1 (no display manager needed). The dbus setup is handled in `hyprland.conf` via `exec-once`:

```
# These are already in hyprland.conf:
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
```

Since we're not using a display manager, PAM won't automatically unlock the GNOME keyring on login. Add the following lines to `/etc/pam.d/login` to fix this:

```
auth       optional     pam_gnome_keyring.so        # add after the auth include
session    optional     pam_gnome_keyring.so auto_start  # add after the session include
```

The full file should look like:

```
#%PAM-1.0

auth       requisite    pam_nologin.so
auth       include      system-local-login
auth       optional     pam_gnome_keyring.so
account    include      system-local-login
session    include      system-local-login
session    optional     pam_gnome_keyring.so auto_start
password   include      system-local-login
```

No `~/.xinitrc` is needed for Wayland.

install user-specific applications

```
# stow - gnu utility that loads up config files easily
sudo pacman -S stow
```

Make basic home folders

```
mkdir ~/Sites #will hold our projects
mkdir ~/Pictures #will hold backgrounds etc
```

Now grab all of the dot files

```
cd ~/Sites && git clone https://github.com/nathanielinman/dot-files.git
cd dot-files
```

Install stow packages for the Wayland setup:

```
cd packages
stow -t ~ hyprland waybar swaync walker kitty zsh git nvim starship wallpaper
```

if at any point you want to remove the symlinks `stow -D <package>` from within the packages folder
Feel free to manually copy any ./Sites/dot-files/usr/share/applications files
in order to setup launching using walker or hiding unused/unwanted apps.
Now grab paru for AUR, used to use yay but Rust ftw :)

```
cd ~/Sites
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

Now install web browser

```
yay -S google-chrome
```

## CLI Configuration

We start by using our package manager `pacman` to get all necessary binaries. We'll omit `node` as it will be managed by it's own version manager `pnpm`.

- `curl` helps make web requests from the command line
- `wget` command helps acquire data from the web via the command line
- `diff-so-fancy` helps make cli `git diff` look good (automatic)
- `eza` is prettier version of `ls` command (we alias it instead in .zshrc)
- `bat` is prettier version of `cat` command (we alias it instead in .zshrc)
- `fd` is aliased in .zshrc as `searchFiles` and finds within directories filenames
- `ripgrep` looks within files for strings
- `git` is basic requirement for version control
- `github-cli` provides the `gh` command for GitHub from the terminal (auth, PRs, issues)
- `glab` is the GitLab CLI, the GitLab equivalent of `gh`
- `git-delta` by dandavison is an amazing pager tool for git diffs
- `zsh` will be our default shell
- `python-pip` will give us pip for python package management
- `pyenv` python version manager and virtual environment
- `wl-clipboard` provides `wl-copy` and `wl-paste` for clipboard input/output on Wayland. see alias pbcopy & pbpaste aliases in .zshrc
- `scc` breaks down LOC on a repo, broken by language
- `duf` a better version of `df` (disk free utility)
- `bandwhich` a bandwidth utilization monitor
- `fkill` a beautiful way to kill apps instead of `pkill`, `killall` etc
- `gping` ping multiple targets at the same time for comparison
- `jq` is a command-line JSON processor

```
yay -S curl wget diff-so-fancy eza bat fd ripgrep git github-cli glab zsh python-pip pyenv wl-clipboard scc duf bandwhich fkill gping jq
```

Validate that under `core` of `.gitconfig` the `pager` value is set to `delta` to reflect `git-delta` package.

Screen locking is handled by `hyprlock` and idle management by `hypridle`. Both configs live in `~/.config/hypr/` (installed via the hyprland stow package). Lock screen is triggered manually via SUPER+Alt+L.

Now we update our python package manager

```
pip3 install --upgrade pip
```

Now for installing vim package manager

```
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```

Now that Vundler is installed, we can install all the plugins.

```
vim +PluginInstall +qall
```

Now for configuring the shell.

```
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```

Lets ensure that zsh will have fish-like syntax highlighting & autocompletion

```
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

Install node js package manager pnpm, this also manages our node versions now instead of `nvm` or `n`. After installing leverage it to install the latest or whatever versions required.

```
yay -S pnpm
pnpm env use --global lts
pnpm env ls
```

Now we'll install Rust:

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Now some rust utils:

- `rusti-cal` is a better calendar
- `melt` is a way of easily extracting zip, gz, Z, bz2, tar, etc
- `tidy-viewer` or "tv" is an easy way to preview csv files
- `pueue` is a tool that helps manage a queue of shell commands (daemon is pueued)

```
cargo install rusti-cal melt tidy-viewer pueue
```

## Voxtype (Push-to-Talk Voice-to-Text)

- `voxtype-bin` - push-to-talk voice-to-text tool for Linux, optimized for Wayland
- `wtype` - keyboard simulation for Wayland (recommended by voxtype)

```
yay -S voxtype-bin wtype
```

Run the initial setup to download the Whisper model and configure GPU acceleration:

```
voxtype setup
voxtype setup gpu --enable  # optional, requires vulkan-icd-loader
```

Voxtype runs as a daemon and is bound to F13 (code:191) as push-to-talk in `hyprland.conf`. The waybar module shows recording/transcribing status. A meeting recording script (`~/.config/waybar/scripts/meeting-record.sh`) captures audio to 15-minute WAV chunks for later batch transcription via `voxtype transcribe`, toggled with F14 (code:192).

Now for any other essentials for arch

- `slack-desktop` for work, quite a bit better than regular browser version
- `discord` for games and communication with friends and family
- `file-roller` is an gui archive manager, although mostly `tar` on cli, nice to have
- `ttf-joypixels` adds support for emoji's within kitty terminal and elsewhere
- `ncdu` NCurses Disk Usage shows what files/folders are occupying how much space
- `lazygit` is tui controls for beautiful git as well as nvim
- `glow` is for cating out or reading markdown files in terminal
- `glances` is better version of `top` command (we alias it instead in .zshrc)
- `procs` is a better version of `ps` command (we alias it instead in .zshrc)
- `tokei` analyzes a folders programming language, loc, comments, etc
- `zoxide` allows jumpting to random folders, inspired by z and autojump
- `fzf` is a fuzzy finder for files usable in vim or cli
- `didyoumean` is a spell-checking app
- `translate-shell` is a translation app
- `udict` urban dictionary
- `fastfetch` cli system info tool (actively maintained neofetch replacement)
- `sdcv-git` cli dictionary
- `xsv` is a cli for splitting/joining/analyzing csv files
- `obsidian` is a note-taking application leveraging zettelkasten
- `cronie` cron service to help sync any `notes` and `todo` repo changes automatically
- `dog` is a DNS lookup cli info tool
- `sd` is a replacement for sed with sane regex instead
- `onefetch` is a command that gets important stats on a git repo
- `okular` is a pdf, epub, cbr, cbz etc minimal chrome reader
- `usbutils` allows `lsusb` and other helpful minor functions
- `thunar` is a slim file manager
- `thunar-volman` is a slim volume manager for the thunar fm gui
- `thunar-archive-plugin` is a slim shim for file roller integration with thunar
- `ffmpegthumbnailer` is a video thumbnail support for thunar
- `gvfs` gnome virtual file system unlocks usb, trash can etc on thunar
- `gvfs-smb` mounts samba networked filesystem volumes
- `tumbler` unlocks generation of thumbnails for thunar
- `libgsf` is a super fast image thumbnailer for `tumbler`
- `galculator` is a simple scientific gtk calculator
- `orchis-theme-git` is a simple XFCE4 & GTK dark theme
- `gtk-engine-murrine` helps with backwards-compatibility themes for gtk2
- `kooha` is a Wayland-native screen recorder (replaces peek)
- `gthumb` is the best tiny app for browsing images
- `vscode-langservers-extracted` unlocks all lsp servers for neovim
- `inxi` is a system information tool that shows everything in one place, like HWiNFO for windows
- `vfox` is a version management tool for multiple programming languages
- `yazi` a faster version of `nnn` with simple controls (file viewer on cli)
- `fselect` is a SQL-like querying tool for the filesystem

```
yay -S slack-desktop discord file-roller ttf-joypixels ncdu lazygit glow glances procs tokei zoxide fzf didyoumean translate-shell udict fastfetch sdcv-git xsv obsidian cronie dog sd onefetch okular usbutils kooha thunar thunar-volman thunar-archive-plugin ffmpegthumbnailer gvfs gvfs-smb tumbler libgsf galculator orchis-theme-git gtk-engine-murrine gthumb vscode-langservers-extracted inxi vfox yazi fselect
```

Now open up `nwg-look` and set the theme to `orchis-dark` with `feather` font and `qogir-icon-theme` for icons.

Now grab the dictionary file for sdcv:

```
sudo mkdir -p /usr/share/stardict/dic/
sudo wget -c https://web.archive.org/web/20200630200122/http://download.huzheng.org/dict.org/stardict-dictd_www.dict.org_gcide-2.4.2.tar.bz2 -O /tmp/dict.tar.bz2 && sudo tar -xvjf /tmp/dict.tar.bz2 -C /usr/share/stardict/dic/
```

Now sync notes for `obsidian` into Sites:

```
cd ~/Sites
git clone https://github.com/nathanielinman/notes.git
```

Now enable the cronie cron service for systemd and start immediately

```
sudo systemctl enable cronie.service --now
```

cron workfiles are stored under `/var/spool/cron` and `/etc/cron*`. You can edit crontab with `crontab -e`. Go ahead and add those cron actions now to keep things synced:

```
# `cron tab -e` then add the following lines to update both automatically hourly
@hourly /home/nate/Sites/dot-files/scripts/cron-git-notes-auto-update.sh
```

Finally we should make sure our `/etc/hosts` file is prioritized for blocking hosts if we want. Within `sudo vim /etc/nsswitch.conf` make sure the `files` attribute is before the others:

```
hosts: files mymachines resolve [!UNAVAIL=return] myhostname dns
```

Then we can add urls we want to block within it (for me, yandex - which i usually allow on pihole but not my work machine):

```
127.0.0.1 yandex.ru
127.0.0.1 cdn.dzen.ru
127.0.0.1 yabs.yandex.ru
```

## Hyprland Plugin Setup

Install plugins from the official hyprland-plugins repo:

```
hyprpm update
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm enable hyprscrolling hyprbars
```

- `hyprscrolling` - scrolling/column-based window layout (like PaperWM)
- `hyprbars` - window title bars with close/fullscreen/float buttons

Plugin config is in `hyprland.conf` under the `plugin { ... }` block.

## Stow Packages

The following stow packages should be installed for the Wayland setup:

```
cd ~/Sites/dot-files/packages
stow -t ~ hyprland waybar swaync walker kitty zsh git nvim starship wallpaper
```

| Package | Description |
|---------|-------------|
| `hyprland` | Hyprland compositor config with hyprscrolling, hyprlock, and hypridle |
| `waybar` | Bottom bar with system info, scripts, and workspaces |
| `swaync` | Notification center with history |
| `walker` | Application launcher with file browser, symbols, and window switcher |
| `kitty` | Terminal emulator |
| `zsh` | Shell configuration with aliases and plugins |
| `git` | Git configuration with delta pager |
| `nvim` | Neovim configuration |
| `starship` | Cross-shell prompt |
| `wallpaper` | Desktop wallpaper |

## Default Applications

In order to ensure that `xdg-open` opens things in the right applications:

```
xdg-mime default neovide.desktop application/javascript
xdg-mime default neovide.desktop application/json
xdg-mime default neovide.desktop application/x-shellscript
xdg-mime default neovide.desktop text/english
xdg-mime default neovide.desktop text/plain
xdg-mime default neovide.desktop text/x-c
xdg-mime default neovide.desktop text/x-c++
xdg-mime default neovide.desktop text/x-c++hdr
xdg-mime default neovide.desktop text/x-c++src
xdg-mime default neovide.desktop text/x-chdr
xdg-mime default neovide.desktop text/x-csrc
xdg-mime default neovide.desktop text/x-java
xdg-mime default neovide.desktop text/x-makefile
xdg-mime default neovide.desktop text/x-moc
xdg-mime default neovide.desktop text/x-pascal
xdg-mime default neovide.desktop text/x-tcl
xdg-mime default neovide.desktop text/x-text
xdg-mime default neovide.desktop text/xml
```

This will save things to your `~/.config/mimeapps.list` file. In order to see what mime a file is:

```
xdg-mime query ./ref/to/file.ext
```

In order to see what app will open a mime:

```
xdg-mime query default mimetype
```

If something isn't within your `~/.config/mimeapps.list` then `xdg-open` will look in `/usr/share/applications/mimeinfo.cache`

## Setting up Titan Security Key

First validate udev is over version 188 with `sudo udevadm --version`, and if so in `sudo vim /etc/udev/rules.d/70-titan-key.rules`:

```
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="18d1|096e", ATTRS{idProduct}=="5026|0858|085b", TAG+="uaccess"
```

then `:wq` and `sudo udevadm control --reload-rules`.

## autostart apps using systemd

https://github.com/jceb/dex


## Openvpn

Instead of going down the route of openvpn3 which is super buggy, it's best to just use the built-in `nmcli` client similar to `docker`:

```bash
# add ability to add openvpn files to network manager
yay -S extra/networkmanager-openvpn libnma

# list connections
nmcli connection

# add a new openvpn connection
nmcli connection import type openvpn file example.ovpn

# activate the new connection (--ask is only helpful if there's a private key password)
nmcli connection up connection_name --ask

# deactivate the connection
nmcli connection down connection_name
```

If you have issues such as needing to auth over browser, here's how to do openvpn3:

```bash
# install openvpn
yay -S openvpn3

# show sessions
openvpn3 sessions-list

# make connection
openvpn3 session-start --config ~/example.ovpn

# disconnect from session
openvpn3 session-manage --disconnect --path /net/openvpn/v3/sessions/___example__uid__real__one__in__sessions-list
```
