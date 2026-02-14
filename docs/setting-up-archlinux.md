# Setting Up Archlinux

## Arch From Scratch

When all else fails, the best installation guide is [the official arch wiki](https://wiki.archlinux.org/index.php/installation_guide).

To start, let's ensure the internet is connected and sync time

```
ping -c 3 google.com
timedatectl set-ntp true
```

Use this to make sure you know your drive names, mine show `nvme0n1` and `nvme1n1`. I'll reference those going forward to stripe (RAID 0) those m.2 drives.

```
fdisk -l
```

Will be using GPT and partition 2 nvme drives based on their sizes. Your sizes may be different.

```
cfdisk /dev/nvme0n1
# create 500M
# create 16G
# create 900G
# create 15G
# write and then quit
cfdisk /dev/nvme1n1
# create 16G
# create 900G
# create 15G
# write and then quit
fdisk -l
```

now that the drives are partitioned lets setup raid 0
(if these cause issues: `sudo mdadm -Esv` or `sudo mdadm --stop /dev/md*` then `sudo mdadm --misc --scan --detail /dev/md0`)

```
mdadm --create --verbose --level=0 --metadata=1.2 --chunk=128 --raid-devices=2 /dev/md0 /dev/nvme0n1p2 /dev/nvme1n1p1
mdadm --create --verbose --level=0 --metadata=1.2 --chunk=128 --raid-devices=2 /dev/md1 /dev/nvme0n1p3 /dev/nvme1n1p2
mdadm --create --verbose --level=0 --metadata=1.2 --chunk=128 --raid-devices=2 /dev/md2 /dev/nvme0n1p4 /dev/nvme1n1p3
```

if last one fails for "cannot assemble multi-zone RAID0 with default_layout.. do this last line, and retry otherwise skip

```
echo 1 > /sys/module/raid0/parameters/default_layout
```

Now lets validate those changes

```
lvmdiskscan
```

physical volumes

```
pvcreate /dev/md0
pvcreate /dev/md1
pvcreate /dev/md2
```

volume groups

```
vgcreate vg_swap /dev/md0
vgcreate vg_main /dev/md1
vgcreate vg_tmp /dev/md2
vgscan
```

logical volumes

```
lvcreate -l +100%FREE vg_swap -n swap
lvcreate -L 60GiB vg_main -n rootfs
lvcreate -l +100%FREE vg_main -n homefs
lvcreate -l +100%FREE vg_tmp -n tmpfs
lvscan
```

setup swap, ensure fat32 boot partition & declare ext4 elsewhere

```
mkswap /dev/mapper/vg_swap-swap
mkfs.ext4 /dev/mapper/vg_main-rootfs
mkfs.ext4 /dev/mapper/vg_main-homefs
mkfs.ext4 /dev/mapper/vg_tmp-tmpfs
swapon /dev/mapper/vg_swap-swap
mkfs.fat -F32 /dev/nvme0n1p1
```

now mount points

```
mount /dev/mapper/vg_main-rootfs /mnt
mkdir /mnt/home
mkdir /mnt/tmp
mount /dev/mapper/vg_main-homefs /mnt/home
mount /dev/mapper/vg_tmp-tmpfs /mnt/tmp
pacstrap -i /mnt base base-devel linux linux-firmware lvm2 mdadm gvim
genfstab -U -p  /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash
```

Now uncomment "[en_US.UTF-8 UTF-8]"

```
vim /etc/locale.gen
# it's :wq in-case you've been using emacs too long haha
```

Now configure local time

```
locale-gen
ln -sf /usr/share/zoneinfo/America/Chicago  /etc/localtime
hwclock --systohc --utc
```

Now add `dm_mod` between the `()` on `MODULES` and add `mdadm_udev lvm2` between block & filesystems of `HOOKS=()` here:

```
vim /etc/mkinitcpio.conf
```

Now setup grub:

```
mkinitcpio -p linux
pacman -S grub efibootmgr
mkdir /boot/efi
mount /dev/nvme0n1p1 /boot/efi
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg
mkdir /boot/efi/EFI/BOOT
cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI
```

Now you'll add the following within `vim /boot/efi/startup.nsh`:

```
bcf boot add 1 fs0:\EFI\GRUB\grubx64.efi "My GRUB bootloader"
```

Now properly setup networking, substitute `FROSTY` for your computer name.

```
pacman -S networkmanager
systemctl enable NetworkManager --now
echo FROSTYARCH > /etc/hostname
```

Now add the following within `vim /etc/hosts`:

```
127.0.0.1 localhost
::1       localhost
127.0.1.1 FROSTYARCH.localdomain FROSTYARCH
```

newer machines, no eth0. config DHCP make sure to edit the proper `ip link` name
mine shows `enp5s0` for ethernet, `vim /etc/systemd/network/enp5s0` and write this:

```
[Match]
Name=en**

[Network]
DHCP=yes
```

Now setup password

```
passwd
```

Now lets wrap things up. after rebooting, boot to bios, ensure nvme raid is on and remove boot flash drive.

```
exit
umount -R /mnt
reboot
```

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

Sound and bluetooth - will enable pulseaudio on user later

- `alsa-utils` - command line alteration of audio levels on alsa's kernel level sound mixer
- `pipewire` - a new low-level multimedia framework compared to pulseaudio or alsa
- `wireplumber` - a policy manager for pipewire, allowing lua plugins
- `pipewire-audio` - the default audio server for pipewire
- `pipewire-alsa` - provides support for older ALSA API applications
- `pipewire-pulse` - provides support for older pulse audio API applications
- `bluez` - bluetooth protocol stack
- `bluez-utils` - provides bluetoothctl utility
- `blueberry` - a gui applet ontop of bluez to make bluetooth support easier

```
Pacman -S alsa-utils pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse bluez bluez-utils blueberry
systemctl enable pipewire.socket pipewire-pulse.socket wireplubmer.service --now
systemctl enable pipewire.service --now
systemctl enable bluetooth.service --now
```

Now for installing window manager stuff (Hyprland)

- `hyprland` - tiling Wayland compositor with dynamic tiling, animations, and scripting
- `waybar` - highly customizable bar for Wayland compositors
- `rofi-wayland` - hotkey app opener overlay, Wayland-native fork of rofi
- `dunst` - notification display app (works on Wayland)
- `swaync` - notification center with history panel for Wayland
- `ghostty` - fast GPU-accelerated terminal emulator with ligature support
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
- `cliphist` - clipboard history manager for Wayland
- `grim` - screenshot utility for Wayland
- `slurp` - region selection tool for Wayland screenshots
- `swappy` - screenshot annotation tool
- `swaylock` - screen locker for Wayland
- `swayidle` - idle management daemon for Wayland
- `pamixer` - pulseaudio/pipewire CLI mixer
- `playerctl` - MPRIS media player controller
- `brightnessctl` - brightness control utility
- `xdg-desktop-portal-hyprland` - desktop portal backend for Hyprland
- `qt5-wayland` - Qt5 Wayland platform plugin
- `qt6-wayland` - Qt6 Wayland platform plugin
- `bc` - tiny precision calculator used for netstats averaging
- `xdg-user-dirs` - help ensure well-known user directories are created automatically
- `xdg-utils` - for helpful things such as mime detection

```
pacman -S hyprland waybar rofi-wayland dunst swaync ghostty network-manager-applet noto-fonts adobe-source-code-pro-fonts otf-font-awesome ttf-droid ttf-fira-code ttf-jetbrains-mono ttf-jetbrains-mono-nerd swww wl-clipboard cliphist grim slurp swappy swaylock swayidle pamixer playerctl brightnessctl xdg-desktop-portal-hyprland qt5-wayland qt6-wayland bc xdg-user-dirs xdg-utils
```

No display manager is needed. Hyprland auto-launches via `.zshrc` when logging in on tty1, and getty autologin handles the login (configured below).

Before we can start Hyprland we need graphics drivers, validate what we're using

```
lspci -v | grep -A1 -e VGA -e 3D
```

Now acquire graphics packages (if issues see [here](https://github.com/JaKooLit/Arch-Hyprland/blob/main/install-scripts/nvidia.sh)):

- `nvidia` - core driver package alternative to nouveau
- `nvidia-dkms` - we're not on maxwell so let's use this driver package
- `nvidia-settings` - configure nvidia options through cli or gui
- `nvidia-utils` - blacklist nouveau packages and other things
- `libva` - hardware video acceleration offloads cpu usage to gpu
- `libva-nvidia-driver-git` - translation layer for libva to nvidia

```
pacman -S nvidia nvidia-settings nvidia-utils # this is my driver stuff
```

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

The following is outdated, but sets up a window manager to get started, substitute `nate` for your name:

```
useradd -m -g users -G wheel -s /bin/bash nate
passwd nate
```

Now ensure user is sudoer, vim `/etc/sudoers` and uncomment this line and :wq!

```
%wheel ALL=(ALL) NOPASSWD: ALL
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

Now make sure we disable suspend on idle and pause on idle power saving options. We do this because when zoom is quiet, sometimes it takes a second or two to wake up the pipewire sink and the beginning of sentences could be completely missed.

```
pw-metadata -n settings 0 node.suspend-on-idle false
pw-metadata -n settings 0 node.pause-on-idle false
systemctl --user restart wireplumber.service && systemctl --user restart pipewire.service pipewire-pulse.service
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
stow -t ~ hyprland waybar swaylock swaync dunst rofi ghostty zsh git nvim starship wallpaper
```

if at any point you want to remove the symlinks `stow -D <package>` from within the packages folder
Feel free to manually copy any ./Sites/dot-files/usr/share/applications files
in order to setup launching using rofi or hiding unused/unwanted apps.
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
- `git-delta` by dandavison is an amazing pager tool for git diffs
- `zsh` will be our default shell
- `python-pip` will give us pip for python package management
- `pyenv` python version manager and virtual environment
- `wl-clipboard` provides `wl-copy` and `wl-paste` for clipboard input/output on Wayland. see alias pbcopy & pbpaste aliases in .zshrc
- `task` is a very simple cli todo app named taskwarrior
- `scc` breaks down LOC on a repo, broken by language
- `duf` a better version of `df` (disk free utility)
- `bandwhich` a bandwidth utilization monitor
- `fkill` a beautiful way to kill apps instead of `pkill`, `killall` etc
- `gping` ping multiple targets at the same time for comparison
- `jq` is a command-line JSON processor

```
yay -S curl wget diff-so-fancy eza bat fd ripgrep git zsh python-pip pyenv wl-clipboard task scc duf bandwhich fkill gping jq
```

Validate that under `core` of `.gitconfig` the `pager` value is set to `delta` to reflect `git-delta` package.

Screen locking is handled by `swaylock` and idle management by `swayidle`. Both are configured in `hyprland.conf`:

```
# Already in hyprland.conf exec-once:
exec-once = swayidle -w timeout 900 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on'
# Lock screen via SUPER+Alt+L which runs swaylock
```

The swaylock config is at `~/.config/swaylock/config` (Nord-themed, installed via stow).

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

Now for any other essentials for arch

- `hyprpicker` Wayland-native color picker
- `slack-desktop` for work, quite a bit better than regular browser version
- `discord` for games and communication with friends and family
- `feh` is an image viewer (wallpapers are now handled by swww)
- `file-roller` is an gui archive manager, although mostly `tar` on cli, nice to have
- `ttf-joypixels` adds support for emoji's within ghostty terminal and elsewhere
- `vit` is a TUI for taskwarrior
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
- `neofetch` cli info tool
- `sdcv-git` cli dictionary
- `xsv` is a cli for splitting/joining/analyzing csv files
- `obsidian` is a note-taking application leveraging zettelkasten
- `cronie` cron service to help sync any `notes` and `todo` repo changes automatically
- `dog` is a DNS lookup cli info tool
- `sd` is a replacement for sed with sane regex instead
- `onefetch` is a command that gets important stats on a git repo
- `okular` is a pdf, epub, cbr, cbz etc minimal chrome reader
- `usbutils` allows `lsusb` and other helpful minor functions
- `hyprpicker` is a Wayland-native color picker (replaces gpick on X11)
- `thunar` is a slim file manager
- `thunar-volman` is a slim volume manager for the thunar fm gui
- `thunar-archive-plugin` is a slim shim for file roller integration with thunar
- `ffmpegthumbnailer` is a video thumbnail support for thunar
- `gvfs` gnome virtual file system unlocks usb, trash can etc on thunar
- `gvfs-smb` mounts samba networked filesystem volumes
- `tumbler` unlocks generation of thumbnails for thunar
- `libgsf` is a super fast image thumbnailer for `tumbler`
- `lxappearance` is tiny a theme chooser for GTK (alternatively use `nwg-look` for a Wayland-native option)
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
yay -S hyprpicker slack-desktop discord feh file-roller ttf-joypixels vit ncdu lazygit glow glances procs tokei zoxide fzf didyoumean translate-shell udict neofetch sdcv-git xsv obsidian cronie dog sd onefetch okular usbutils kooha thunar thunar-volman thunar-archive-plugin ffmpegthumbnailer gvfs gvfs-smb tumbler libgsf lxappearance galculator orchis-theme-git gtk-engine-murrine gthumb vscode-langservers-extracted inxi vfox yazi fselect
```

Now open up `lxappearance` and set the theme to `orchis-dark` with `feather` font and `qogir-icon-theme` for icons.
You can now set any default applications you prefer:

```
handlr set .png feh.desktop
```

If you want to view pixel art with feh, it may make sense to force aliasing and auto zooming. `sudo vim /usr/share/applications/feh.desktop` and change `Exec` lint to be:

```
Exec=feh --start-at %u --force-aliasing --auto-zoom
```

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

Now sync tasks for `taskwarrior` and `vit`:

```
git clone https://github.com/nathanielinman/tasks.git ~/.task
```

Now enable the cronie cron service for systemd and start immediately

```
sudo systemctl enable cronie.service --now
```

cron workfiles are stored under `/var/spool/cron` and `/etc/cron*`. You can edit crontab with `crontab -e`. Go ahead and add those cron actions now to keep things synced:

```
# `cron tab -e` then add the following lines to update both automatically hourly
@hourly /home/nate/Sites/dot-files/scripts/cron-git-notes-auto-update.sh
@hourly /home/nate/Sites/dot-files/scripts/cron-git-tasks-auto-update.sh
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

Now we'll grab `snap` so we can grab `docker` and other things easily

```
cd ~/Sites
git clone https://aur.archlinux.org/snapd.git
cd snapd
makepkg -si
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
```

Finally we can grab some `snap` stuff we'll use when developing a lot

Note: `colorpicker-app` may not work well on Wayland - use `hyprpicker` instead as a Wayland-native color picker. `emote` should work under XWayland.

```
snap install emote gnome-3-28-1804 gtk-common-themes snapd bare core18
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
stow -t ~ hyprland waybar swaylock swaync dunst rofi ghostty zsh git nvim starship wallpaper
```

| Package | Description |
|---------|-------------|
| `hyprland` | Hyprland compositor config with hyprscrolling |
| `waybar` | Bottom bar with system info, scripts, and workspaces |
| `swaylock` | Nord-themed lock screen |
| `swaync` | Notification center with history |
| `dunst` | Simple notification daemon |
| `rofi` | Application launcher and clipboard manager |
| `ghostty` | Terminal emulator |
| `zsh` | Shell configuration with aliases and plugins |
| `git` | Git configuration with delta pager |
| `nvim` | Neovim configuration |
| `starship` | Cross-shell prompt |
| `wallpaper` | Desktop wallpaper |

## Default Applications

In order to ensure that `xdg-open` via rofi opens things in the right applications:

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

## Make shutdown and reboot faster

add `use_lvmetad = 0` to `/etc/lvm/lvm.conf`

## Setting up Titan Security Key

First validate udev is over version 188 with `sudo udevadm --version`, and if so in `sudo vim /etc/udev/rules.d/70-titan-key.rules`:

```
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="18d1|096e", ATTRS{idProduct}=="5026|0858|085b", TAG+="uaccess"
```

then `:wq` and `sudo udevadm control --reload-rules`.

## Setting up streamdeck

```
yay -S streamdeck-ui
```

then reboot

```
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/lightbulb-off.png -o ~/Pictures/lightbulb-off.png
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/lightbulb-on.png -o ~/Pictures/lightbulb-on.png
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/screencapture-icon.png -o ~/Pictures/screencapture-icon.png
cd ~/Sites
git clone https://github.com/endocrimes/keylightctl.git
cd keylightctl
make build
sudo cp ./dist/linux_amd64/keylightctl /usr/bin
```

now we'll discover any lights on the network

```
keylightctl discover
```

now we can add the following commands to streamdeck (substitute your light ids used in discover)

```
bash -c "keylightctl switch --light 8A95 on & keylightctl switch --light 9F74 on"
bash -c "keylightctl switch --light 8A95 off & keylightctl switch --light 9F74 off"
```

make sure to use the `on` and `off` icons you downloaded earlier
While we're here, let's also set the icon for the `screencapture-icon.png` and setup the command:

```
bash -c "grim -g \"$(slurp)\" - | swappy -f -"
```

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
