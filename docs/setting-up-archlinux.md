# Setting Up Archlinux

## Install Method

FROSTYARCH (Ryzen 7 9800X3D, TUF X870, 64 GB RAM, RTX 3080) has three 2 TB NVMe drives, one per role. No RAID (backups go to Rime), no LVM (it does nothing under btrfs), no encryption (single-user autologin desktop).

| Drive | Filesystem | Mounts |
|---|---|---|
| OS (Sabrent, in M.2_1, CPU-attached) | btrfs, subvols `@ @home @snapshots @log @pkg @swap` | `/`, `/home`, `/.snapshots`, `/var/log`, `/var/cache/pacman/pkg`, `/swap`, plus `/boot` (2 GB ESP) |
| Scratch (Samsung 990 PRO, `LABEL=scratch`) | ext4 | `/scratch`, and `/tmp` as a bind of `/scratch/tmp` |
| Data (Samsung 990 PRO, `LABEL=data`) | btrfs, subvols `@data @sites` | `/data`, `~/Sites` |

- **`/tmp` is on the scratch disk, not in RAM.** Agents filled a 16 GB tmpfs, and the workaround (`~/.cache`) grew to 425 GB with nothing cleaning it. A disk-backed `/tmp` uses no RAM. `/etc/tmpfiles.d/tmp.conf` holds `Q /tmp 1777 root root 7d` (replaces the stock 10-day file; `systemd-tmpfiles-clean.timer` runs it daily). It is not wiped on reboot, so agent worktrees survive a restart.
- **Scratch is for rebuildable, high-churn data** (`/tmp`, Docker, Gradle, VMs, emulators). Never snapshotted or backed up; if it dies, reformat it.
- **Data holds what matters**: `~/Sites` (same path as before so Claude memories and T3 threads still match), Steam library, assets. Snapshot it and back it up to Rime.
- **Swap**: zram (`ram / 4`) plus a 16 GB swapfile, no hibernate. Keep `systemd-oomd` on.

### Rebuild order (one reboot)

> [!TIP]
> [`rebuild/`](../rebuild/README.md) scripts this whole order: `bootstrap.sh` and `10-live.sh` on the ISO, `40-first-boot.sh` after the reboot. Steps that fail are either critical (the script stops and says how to resume) or minor (written to `/var/log/rebuild/followups.md` for later). The steps below are the reference for what those scripts do.

Do everything that doesn't need a running desktop from the archiso, so the first boot lands in a working Hyprland session. The 2026-11-06 rebuild didn't, and paid for it: it stopped at a bare system and rebooted, then installed only the [First Boot](#first-boot) packages and rebooted again just to start Hyprland. That session had no oh-my-zsh, zoxide, atuin, starship or eza yet, so every shell errored. About 120 more packages went in after that, and adding the `docker` group needed a third log-out.

1. **Live ISO.** Get online, then uncomment `[multilib]` in the ISO's own `/etc/pacman.conf` (pacstrap resolves against the host config). Partition and mount the [OS drive](#os-drive-from-the-archiso), and format the [scratch and data drives](#scratch-and-data-drives) too, mounted at `/mnt/scratch`, `/mnt/data` and `/mnt/home/nate/Sites`. Then install the whole package manifest in one pass. `-P` copies the ISO's `pacman.conf` (with multilib) into the new system:

   ```
   git clone https://github.com/NathanielInman/dotfiles.git /root/dot-files
   pacstrap -K -P /mnt $(grep -v '^#' /root/dot-files/pkglist/repo.txt)
   genfstab -U /mnt >> /mnt/etc/fstab    # then swap the scratch/data lines for the LABEL= ones below
   ```

2. **`arch-chroot /mnt`, as root.** Do everything in [In the new system](#in-the-new-system). Create the user with all of its groups now, so nothing needs a log-out later. `docker` already exists from the package; `plugdev` is for the [ZSA keyboard](#zsa-keyboard-oryx-flashing-and-live-training):

   ```
   groupadd -f plugdev
   useradd -m -G wheel,users,docker,plugdev -s /bin/zsh nate
   chown nate:nate /home/nate/Sites /data /scratch /scratch/{gradle,vms,avd}
   btrfs subvolume create /home/nate/.cache && chown nate:nate /home/nate/.cache
   ```

3. **Still in the chroot, as nate** (`su - nate`). Clone dot-files and stow it. `install.sh` creates `~/.local/bin` as a real directory first, so stow links only the tracked scripts ([why](#why-local-is-a-real-directory)). Then install the shell plugins and the AUR side of the manifest:

   ```
   git clone https://github.com/NathanielInman/dotfiles.git ~/Sites/dot-files && cd ~/Sites/dot-files
   ./install.sh hyprland waybar swaync walker kitty zsh git nvim starship vim topgrade task chrome pipewire cargo paru
   (cd ~/.oh-my-zsh && git init -q && git remote add origin https://github.com/ohmyzsh/ohmyzsh.git \
     && git fetch -q --depth=1 origin master && git checkout -q -f -B master FETCH_HEAD)   # not the installer: it replaces .zshrc
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
   git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
   git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim && vim +PluginInstall +qall
   broot --install                       # writes the `br` launcher that .zshrc sources
   rustup default stable                 # before any AUR build, so nothing pulls in the conflicting `rust`
   git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin && (cd /tmp/paru-bin && makepkg -si)
   grep -v '^#' pkglist/aur.txt | paru -S --needed --removemake -   # openvpn3 needs --nocheck; waybar-git asks about its conflict
   pacman -Qdtq                          # orphaned build tools: should print nothing (paru's RemoveMake)
   ./install.sh -s                       # in a chroot systemctl enables units and skips --now/daemon-reload
   ```

   `systemctl --user` needs a running user manager, so enable the user units (`waybar`, `headset-autoswitch`, `elephant`, `hyprpolkitagent`) from the first Hyprland terminal. PipeWire's sockets are enabled by default.

4. **Leave the chroot**, point `resolv.conf` at resolved (arch-chroot bind-mounts over it, so do it from outside), and reboot. This is the only reboot:

   ```
   ln -sf ../run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf
   umount -R /mnt && reboot
   ```

5. **After the first boot**, getty autologin starts Hyprland. Do the YubiKey, secrets and `~/Sites` restore from a kitty terminal as `nate`, never as root. Under `sudo`, `~` expands to `/root`, and files land root-owned. Run Claude Code as `nate` too. After restoring `~/.claude`, restart Claude itself. The session doesn't need a restart.

> [!TIP]
> A restored GNOME keyring is still locked with the old machine's login password, so `glab` can't read its token and every GitLab clone fails. On the old machine, blank the keyring password (see the [autologin keyring step](#first-boot)) before archiving it. Otherwise, unlock it in Seahorse before restoring repos.

### OS drive (from the archiso)

Partition and mount by hand, then either run `archinstall` with "Pre-mounted configuration" for the selections below, or `pacstrap` directly:

```
OS=/dev/disk/by-id/nvme-<os-drive>
sgdisk -Z $OS
sgdisk -n1:0:+2G -t1:ef00 -c1:ESP -n2:0:0 -t2:8304 -c2:root $OS
mkfs.fat -F32 -n ESP $OS-part1
mkfs.btrfs -L root $OS-part2

mount $OS-part2 /mnt
for s in @ @home @snapshots @log @pkg @swap; do btrfs subvolume create /mnt/$s; done
umount /mnt

o=noatime,compress=zstd:1
mount -o $o,subvol=@ $OS-part2 /mnt
mount --mkdir -o $o,subvol=@home      $OS-part2 /mnt/home
mount --mkdir -o $o,subvol=@snapshots $OS-part2 /mnt/.snapshots
mount --mkdir -o $o,subvol=@log       $OS-part2 /mnt/var/log
mount --mkdir -o $o,subvol=@pkg       $OS-part2 /mnt/var/cache/pacman/pkg
mount --mkdir -o noatime,subvol=@swap $OS-part2 /mnt/swap
mount --mkdir -o umask=0077 $OS-part1 /mnt/boot
btrfs filesystem mkswapfile --size 16g /mnt/swap/swapfile && swapon /mnt/swap/swapfile

# without archinstall: the whole manifest (see "Rebuild order"), or at minimum
pacstrap -K -P /mnt $(grep -v '^#' /root/dot-files/pkglist/repo.txt)
genfstab -U /mnt >> /mnt/etc/fstab
```

### In the new system

From `arch-chroot /mnt`. This is what the 2026-11-06 install did, minus its mistakes:

- Locale and time: `en_US.UTF-8 UTF-8` in `/etc/locale.gen` then `locale-gen`, `LANG=en_US.UTF-8` in `/etc/locale.conf`, `ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime && hwclock --systohc`, `KEYMAP=us` in `/etc/vconsole.conf`, `FROSTYARCH` in `/etc/hostname`.
- Limine. `efibootmgr` writes the firmware entry, and the second copy is the fallback path some boards boot first:

  ```
  install -Dm644 /usr/share/limine/BOOTX64.EFI /boot/EFI/limine/BOOTX64.EFI
  install -Dm644 /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI
  efibootmgr --create --disk $(readlink -f $OS) --part 1 --label Limine --loader '\EFI\limine\BOOTX64.EFI' --unicode
  ```

  `/boot/limine.conf`, at the root of the ESP (root UUID from `blkid`, machine ID from `/etc/machine-id`; `zswap.enabled=0` because zram does that job). Keep it in this nested shape and in exactly this place: `limine-snapper-sync` only manages `$ESP/limine.conf`, it finds the entry by the `machine-id` comment, and it fills `//Snapshots`. Limine reads `/limine/limine.conf` before `/limine.conf`, so a leftover `/boot/limine/limine.conf` would shadow this file. `default_entry` uses the path form because an index that lands on a directory disables autoboot:

  ```
  timeout: 3
  default_entry: Arch Linux/Linux

  /+Arch Linux
  comment: machine-id=<machine-id>

      //Linux
      protocol: linux
      kernel_path: boot():/vmlinuz-linux
      kernel_cmdline: root=UUID=<root-uuid> rootflags=subvol=@ rw quiet nvidia_drm.modeset=1 nvidia_drm.fbdev=1 zswap.enabled=0
      module_path: boot():/amd-ucode.img
      module_path: boot():/initramfs-linux.img

      //Snapshots
  ```

  `/etc/pacman.d/hooks/99-limine.hook` copies the EFI binary to both paths again on every `limine` upgrade (`[Trigger]` Install/Upgrade, Package, `Target = limine`; `[Action]` PostTransaction, `Exec = /bin/sh -c 'cp /usr/share/limine/BOOTX64.EFI /boot/EFI/limine/BOOTX64.EFI && cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI'`).

  Snapshots in the boot menu: `limine-snapper-sync` (AUR, in `pkglist/aur.txt`; a GraalVM native build, so run it through `lowprio`). Put `ESP_PATH="/boot"` and `SNAPPER_CONFIG_NAME="root"` in `/etc/default/limine`, then `systemctl enable --now limine-snapper-sync.service` and run `limine-snapper-sync` once. Each snapshot entry boots `/@snapshots/<n>/snapshot` read-only, with copies of the kernel and initramfs it was taken with under `/boot/<machine-id>/limine_history/`. The NVIDIA initramfs is about 100 MB, so the 2 GB ESP holds about a dozen distinct kernel/initramfs pairs (make it 4 GB on the next rebuild, as the tool recommends); old entries drop off at `LIMIT_USAGE_PERCENT=85`. Snapshots taken before the tool was installed can't be added, because their kernels are gone. To roll back, boot a snapshot and accept the "Restore now" prompt.
- NVIDIA modules, `mkinitcpio.conf` and modprobe files as in [First Boot](#first-boot), then `mkinitcpio -P`.
- `/etc/systemd/zram-generator.conf`: `[zram0]` / `zram-size = ram / 4`. `/etc/tmpfiles.d/tmp.conf`: `Q /tmp 1777 root root 7d`.
- Wired network, `/etc/systemd/network/20-wired.network`:

  ```
  [Match]
  Type=ether
  Kind=!*

  [Network]
  DHCP=yes
  MulticastDNS=yes
  ```

- `echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/10-wheel-nopasswd`, the tty1 autologin drop-in, `/etc/profile.d/editor.sh`, the PAM keyring lines, and `passwd -l root`: all from [First Boot](#first-boot).
- Rime: `/etc/cifs-credentials/rime` and its fstab line from [Network storage](#network-storage-rime-truenas-smb-share). broker isn't restored yet, so type the password in by hand this once.
- Docker data root: `/etc/docker/daemon.json` with `{"data-root": "/scratch/docker"}`.
- Snapper root config: `snapper -c root create-config /` fails while `/.snapshots` exists. Unmount and `rmdir` it, run create-config, delete the `.snapshots` subvolume snapper made, then `mkdir /.snapshots` and `mount -a`. Then `snapper -c sites create-config /home/nate/Sites`.
- Enable every system service in one go. `snapper-cleanup.timer` matters: without it, snap-pac's pre/post pairs pile up past `NUMBER_LIMIT` (99 root snapshots on day one). The scrub timers read every block monthly, which is the only way to find silent corruption on drives with no mirror:

  ```
  systemctl enable systemd-networkd systemd-resolved systemd-timesyncd sshd pcscd.socket bluetooth \
    cronie docker.socket fstrim.timer paccache.timer systemd-oomd \
    snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer btrfs-scrub@data.timer
  ```

### Scratch and data drives

```
SCR=/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S7L9NJ0L206326Y
DATA=/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S7L9NJ0L206355B
sudo sgdisk -Z $SCR  && sudo sgdisk -n1:0:0 -t1:8300 -c1:scratch $SCR && sudo mkfs.ext4 -L scratch $SCR-part1
sudo sgdisk -Z $DATA && sudo sgdisk -n1:0:0 -t1:8300 -c1:data $DATA   && sudo mkfs.btrfs -L data $DATA-part1
sudo mount $DATA-part1 /mnt && sudo btrfs subvolume create /mnt/@data /mnt/@sites && sudo umount /mnt
```

`/etc/fstab` additions (`nofail` so a dead drive cannot block boot; the `/tmp` line replaces Arch's tmpfs `tmp.mount` on its own):

```
LABEL=scratch  /scratch          ext4   noatime,nofail,x-systemd.device-timeout=10s  0 2
LABEL=data     /data             btrfs  noatime,compress=zstd:1,subvol=@data,nofail,x-systemd.device-timeout=10s   0 0
LABEL=data     /home/nate/Sites  btrfs  noatime,compress=zstd:1,subvol=@sites,nofail,x-systemd.device-timeout=10s  0 0
/scratch/tmp   /tmp              none   bind,x-systemd.requires-mounts-for=/scratch  0 0
```

From the archiso (the [one-reboot order](#rebuild-order-one-reboot)), mount them under `/mnt` and create the directories there, before pacstrap:

```
mount --mkdir $SCR-part1 /mnt/scratch
mount --mkdir -o noatime,compress=zstd:1,subvol=@data  $DATA-part1 /mnt/data
mount --mkdir -o noatime,compress=zstd:1,subvol=@sites $DATA-part1 /mnt/home/nate/Sites
install -d -m 1777 /mnt/scratch/tmp && mkdir -p /mnt/scratch/{gradle,vms,avd}
```

Adding them to a running system instead needs a reboot, because the live tmpfs `/tmp` is busy:

```
sudo mkdir -p /scratch /data /home/nate/Sites && sudo systemctl daemon-reload
sudo mount /scratch && sudo mount /data && sudo mount /home/nate/Sites
sudo install -d -m 1777 /scratch/tmp
sudo chown nate:nate /scratch /data /home/nate/Sites
sudo reboot        # then `findmnt /tmp` must show /scratch/tmp, not tmpfs
```

`/scratch` must be owned by `nate`, or scripts and agents can't create their own dirs in it. Heavy writers that go there:

- Docker: `/etc/docker/daemon.json` `{"data-root": "/scratch/docker"}`
- Gradle and Android AVDs: `.zshrc` exports `GRADLE_USER_HOME=/scratch/gradle` and `ANDROID_AVD_HOME=/scratch/avd` when `/scratch` exists
- libvirt: storage pool at `/scratch/vms`
- Rust: the `cargo` stow package sets `[profile.dev] debug = "line-tables-only"` in `~/.cargo/config.toml`. Don't set a global `CARGO_TARGET_DIR`: parallel agents would block on its lock.

Steam's library goes on data, not scratch: install `steam` (multilib), then add a library folder at `/data/steam` in its Storage settings.

### Selections to choose during archinstall

- **Mirror region** - your country
- **Locale** - language `en_US.UTF-8`, keymap `us`
- **Timezone** - `America/Chicago` (US/Central)
- **Disk configuration** - **Pre-mounted configuration** at `/mnt` (done above)
- **Disk encryption** - none (this machine is unencrypted by choice)
- **Bootloader** - **Limine**
- **Swap** - enable **zram**
- **Hostname** - `FROSTYARCH`
- **Root password** - set one (or leave unset; tty1 autologin + NOPASSWD sudo are configured in First Boot)
- **User account** - create `nate` and mark it a **superuser** (adds it to `wheel`)
- **Profile** - **Minimal** (no desktop environment; Hyprland is installed manually below)
- **Audio** - **Pipewire**
- **Kernels** - `linux`
- **Network configuration** - **systemd-networkd** (i.e. *not* NetworkManager; the networkd default works on wired). DNS goes through `systemd-resolved`, which the VPN DNS hook relies on.
- **Additional packages** - optional (e.g. `git vim`); microcode (`amd-ucode`) is auto-detected

> [!IMPORTANT]
> Use UUIDs or labels for **every** `/etc/fstab` entry, including `/boot` - NVMe enumeration order (`nvme0` vs `nvme1`) is not stable across reboots. Find them with `lsblk -f` or `blkid`.

After `archinstall` finishes, continue at [First Boot](#first-boot).

## First Boot

> [!NOTE]
> With the [one-reboot order](#rebuild-order-one-reboot), most of this section is already done from the chroot, and the packages come from `pkglist/`. This section stays as the reference for what each piece is and why.

Now after boot, login with the configured password and uncomment `multilib` within:

```
sudo ln -s /usr/bin/vim /usr/bin/vi # make sure we always use vim instead of vi
vim /etc/pacman.conf
```

Now lets update everything:

```
pacman -Syyu
```

Install the `paru` AUR helper now, since several steps below pull from the AUR. Build it as your user (`su - nate` if you're still root; `makepkg` refuses to run as root). The stowed `.zshrc` later aliases `yay` to `paru`, but until then call `paru` directly:

```
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru && makepkg -si
```

> Building `paru` from source pulls in the `rust` package, which **conflicts with `rustup`** (installed later). Remove it (`sudo pacman -R rust`) before installing `rustup`, or install `paru-bin` instead to skip the Rust build entirely. Even with `paru-bin`, other AUR builds pull `rust` in as a make dependency, so install `rustup` and run `rustup default stable` before the first AUR build. Once `rustup` provides `rust`, nothing pulls in the conflicting package.

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
- `rtkit` - grants PipeWire realtime priority so audio keeps playing under heavy CPU load. Only an optional dependency of `pipewire`, so nothing else installs it
- `bluez` - bluetooth protocol stack
- `bluez-utils` - provides bluetoothctl utility
- `bluez-deprecated-tools` - `hcitool` (RSSI, link role/policy); needed by the `bt-force-central` fix below
- `headsetcontrol` - reads the Arctis headset state from its USB base station over HID; used by `headset-autoswitch.service`
- `blueberry` - bluetooth GUI applet (**AUR**, install with `paru`, not pacman)

```
pacman -S alsa-utils pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse rtkit bluez bluez-utils bluez-deprecated-tools headsetcontrol
paru -S blueberry
systemctl enable bluetooth.service --now
```

The board also has onboard Bluetooth (MediaTek MT7925, USB `13d3:3602`, the BT half of the Wi-Fi card). With it present BlueZ made it the default controller and the MX Master paired to it instead of the dongle, so `etc/udev/rules.d/52-disable-onboard-bt.rules` deauthorizes it (`bluetoothctl list` should show one controller). Wi-Fi is unaffected.

Two Bluetooth quirks of the TP-Link UB500 (RTL8761B) dongle are handled by `install.sh`:

- `etc/udev/rules.d/50-bt-adapter-no-autosuspend.rules` keeps the dongle powered (USB autosuspend after 2s idle dropped the mouse mid-drag).
- `bt-force-central`: when the Arctis Nova Pro Wireless reconnects on its own it takes the central role, and with the dongle as peripheral A2DP audio stutters badly even at -20 dBm RSSI. `etc/udev/rules.d/51-bt-force-central.rules` starts `bt-force-central.service` for every new `hciX:N` link, which runs `usr/local/bin/bt-force-central` (`hcitool sr <addr> master`, then `hcitool lp <addr> HOLD,SNIFF,PARK` so the peer cannot switch it back). Check with `sudo hcitool con` (want `CENTRAL`) and `sudo hcitool rssi <addr>`.

Pairings live in `/var/lib/bluetooth/<adapter MAC>/` and the peripheral bonds to that MAC too, so swapping dongles (even the same model) means re-pairing every device.

The Arctis Nova Pro Wireless is normally used through its 2.4 GHz base station, which is a plain USB Audio Class device (no vendor software; the OLED menu covers EQ/sidetone/ChatMix). Its sink exists whether or not the headset is powered, so `headset-autoswitch.service` (stowed from `packages/hyprland/.config/systemd/user/`, script `~/.config/hypr/scripts/headset-autoswitch.sh`) polls `headsetcontrol -o json` every 2s and moves the default output to the base station when the headset comes online, back to the desk speakers when it goes off. `pacman -S headsetcontrol` (also needs `jq`), then `systemctl --user enable --now headset-autoswitch.service`. The headset's Bluetooth pairing was removed to keep it from grabbing the PC; turn Bluetooth off in the base station menu unless it is wanted for a phone.

Now for installing window manager stuff (Hyprland)

- `hyprland` - tiling Wayland compositor with dynamic tiling, animations, and scripting
- `waybar-git` (**AUR**) - highly customizable bar for Wayland compositors. Not the `extra/waybar` release: since the Hyprland config moved to the Lua root, `hyprctl dispatch workspace N` (the legacy keyword form) is rejected, and waybar 0.15.0's `hyprland/workspaces` still hardcodes it, so clicking a workspace icon does nothing. Upstream fixed it in April 2026 (`IPC::dispatch` detects the Lua protocol and emits `hl.dsp.*`) but no release has shipped it. Swap back to `pacman -S waybar` once a release newer than 0.15.0 lands. `paru --noconfirm` refuses the `waybar` -> `waybar-git` conflict and `yes |` loops on the provider prompt, so answer by hand or `printf '1\ny\ny\ny\n' | paru -S --skipreview aur/waybar-git`. Until [Waybar PR #5287](https://github.com/Alexays/Waybar/pull/5287) is merged, the build also needs `docs/patches/waybar-pr5287-sni-combined-registration.diff` applied in `prepare()` (add it to `source=`, `git apply` it): Electron 44+ apps (Slack 4.52+, Signal) register their tray icon as a combined `bus_name/object_path` string, waybar's watcher rejects it as an invalid bus name, and the app then drops the icon entirely. Any waybar-git rebuild from a plain PKGBUILD loses the Slack tray icon again.
- `walker` - Wayland-native GTK4 application launcher (requires `elephant` provider daemon)
- `elephant-all` - general-purpose data provider daemon for walker (includes all providers). Its clipboard provider records the clipboard history, which Super+Alt+V opens as `walker --provider clipboard`
- `swaync` - notification center with history panel for Wayland
- `kitty` - GPU-accelerated terminal emulator with ligature support
- `noto-fonts` - emoji extras & base fonts
- `adobe-source-code-pro-fonts` - additional fallback fonts
- `otf-font-awesome` - additional fallback fonts
- `ttf-droid` - additional fallback fonts
- `ttf-fira-code` - additional fallback fonts
- `ttf-jetbrains-mono` - additional fallback fonts
- `ttf-jetbrains-mono-nerd` - additional fallback fonts
- `awww` - wallpaper daemon for Wayland (fork of swww; binaries `awww`/`awww-daemon`, which the configs call)
- `wl-clipboard` - command-line clipboard utilities for Wayland (wl-copy, wl-paste)
- `blueman` - Bluetooth manager with system tray applet
- `grim` - screenshot utility for Wayland
- `slurp` - region selection tool for Wayland screenshots
- `swappy` - screenshot annotation tool
- `hyprlock` - screen locker for Hyprland
- `hypridle` - idle management daemon for Hyprland
- `hyprpolkitagent` - polkit authentication agent: the password dialog for `pkexec`, privileged mounts and settings panels. Without one these fail with "No authentication agent found" and no prompt ever appears. Runs as a user service (`systemctl --user enable --now hyprpolkitagent.service`), which `graphical-session.target` starts through `hyprland-session.target`
- `pamixer` - pulseaudio/pipewire CLI mixer
- `pavucontrol` - GUI volume mixer for per-app and per-device levels
- `playerctl` - MPRIS media player controller
- `brightnessctl` - brightness control utility
- `xdg-desktop-portal-hyprland` - desktop portal backend for Hyprland
- `qt5-wayland` - Qt5 Wayland platform plugin
- `qt6-wayland` - Qt6 Wayland platform plugin
- `bc` - tiny precision calculator used for netstats averaging
- `xdg-user-dirs` - help ensure well-known user directories are created automatically
- `xdg-utils` - for helpful things such as mime detection
- `yad` - GTK dialog tool; powers the waybar hotkeys (⌨) and commands cheat-sheet buttons
- `wf-recorder` - screen recording backend for Logbook (Super+R, `logbook toggle screen`)
- `hyprpicker` - screen color picker bound to Super+I
- `swayosd` - on-screen volume/brightness popups, started from `autostart.lua` and driven by the media keys in `binds.lua`
- `neovide` - GPU NeoVim GUI that `autostart.lua` opens on login (`scripts/neovide-autostart.sh`)
- `noto-fonts-emoji` - color emoji font
- `sway-audio-idle-inhibit-git` (**AUR**) - holds off hypridle while audio is playing, started from `autostart.lua`

```
pacman -S hyprland swaync kitty noto-fonts noto-fonts-emoji adobe-source-code-pro-fonts otf-font-awesome ttf-droid ttf-fira-code ttf-jetbrains-mono ttf-jetbrains-mono-nerd awww wl-clipboard yad blueman grim slurp swappy wf-recorder hyprlock hypridle hyprpolkitagent hyprpicker swayosd neovide pamixer pavucontrol playerctl brightnessctl xdg-desktop-portal-hyprland qt5-wayland qt6-wayland bc xdg-user-dirs xdg-utils
paru -S waybar-git walker elephant-all sway-audio-idle-inhibit-git
```

Enable the polkit agent with `systemctl --user enable --now hyprpolkitagent.service`. walker needs the `elephant` daemon running as a user service. `elephant service enable` writes `~/.config/systemd/user/elephant.service` and enables it. `autostart.lua` also starts `hyprland-session.target`, which is stowed with the `hyprland` package (`packages/hyprland/.config/systemd/user/`), so it doesn't need to be created by hand.

The Elgato Key Lights are driven over their built-in HTTP API with nothing but `curl` (already installed) - no extra packages or helper CLIs. The `lightson`/`lightsoff` shell aliases (in `.zshrc`) and the waybar keylights widget (`custom/keylights`, with its status script `keylights.sh` and on-click `keylights-toggle.sh`) all hit the same endpoint: `PUT http://<addr>:9123/elgato/lights` with `{"numberOfLights":1,"lights":[{"on":0|1,"brightness":0-100,"temperature":143-344}]}` to set state, and `GET` of the same path to read it.

> A common approach is the `keylightctl` CLI, but it rediscovers the lights over mDNS on every invocation and caches nothing, which is unreliable on a multi-homed host (this machine has two NICs on the same subnet, so its mDNS library frequently queries the wrong interface and finds no lights). It is deliberately not used here.

Instead the lights are addressed at their **IPv6 link-local address** (`fe80::…`), which is derived from the device MAC via EUI-64 and is therefore permanent - no DHCP lease, no discovery. The address carries a `%enp6s0` zone (the interface the lights are reachable on). To derive the address for a light, take its MAC, insert `ff:fe` in the middle, flip the universal/local bit of the first octet, and prefix `fe80::` (e.g. `3c:6a:9d:14:e8:8e` becomes `fe80::3e6a:9dff:fe14:e88e`). Confirm a light answers with:

```
curl http://[fe80::3e6a:9dff:fe14:e88e%enp6s0]:9123/elgato/accessory-info
```

If lights ever change, update the two `fe80::` addresses (and the `%enp6s0` interface) in `.zshrc` and the two waybar `keylights*.sh` scripts.

No display manager is needed. Hyprland auto-launches via `.zshrc` when logging in on tty1, and getty autologin handles the login (configured below).

Before we can start Hyprland we need graphics drivers, validate what we're using

```
lspci -v | grep -A1 -e VGA -e 3D
```

Now acquire graphics packages (if issues see [here](https://github.com/JaKooLit/Arch-Hyprland/blob/main/install-scripts/nvidia.sh)):

> The proprietary `nvidia` / `nvidia-dkms` packages no longer exist in current Arch - only the **open kernel modules** remain. Use `nvidia-open`, which is correct for Turing (GTX 1650) and newer.

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
# /etc/mkinitcpio.conf - load the modules early and DROP the kms hook (stops nouveau)
MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
# HOOKS=(... remove 'kms' ...)

# /etc/modprobe.d/nvidia.conf
options nvidia_drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1

# /etc/modprobe.d/nouveau-blacklist.conf
blacklist nouveau

# /boot/limine.conf - append to the //Linux entry's kernel_cmdline
nvidia_drm.modeset=1 nvidia_drm.fbdev=1
```

Regenerate the initramfs and reboot to activate the modules:

```
mkinitcpio -P
```

The Wayland env vars (`LIBVA_DRIVER_NAME=nvidia`, `GBM_BACKEND=nvidia-drm`, etc.) are exported by the `hypr-launch` launcher (`scripts/hypr-launch`, install to `/usr/local/bin/hypr-launch`), which `.zshrc` runs on tty1 login. It sets the env and then `exec`s Hyprland's own watchdog launcher at `/usr/bin/start-hyprland` (shipped by the `hyprland` package).

> **Do not name this script `start-hyprland`.** Hyprland 0.55+ ships its own launcher binary at `/usr/bin/start-hyprland` (a crash watchdog), and launching `Hyprland` directly bypasses it - Hyprland then warns `WARNING: Hyprland is being launched without start-hyprland. This is highly advised against.` A script named `start-hyprland` in `/usr/local/bin` shadows the real one on PATH, so we name ours `hypr-launch` and call the watchdog by absolute path.

`install.sh`'s system-config step installs `hypr-launch` to `/usr/local/bin/` and removes any stale `/usr/local/bin/start-hyprland`.

If you have multiple monitors and need to set them up, here are some helpful commands

```
hyprctl monitors # list all connected monitors with names, resolutions, positions
```

Monitor configuration is handled in `~/.config/hypr/monitors.lua` (required
from `hyprland.lua`; Hyprland 0.55+ uses lua configs). Connector names depend on the GPU: on the
current desktop the G9's PBP halves are `DP-3` (left) and `DP-2` (right), and a name that matches
nothing falls through to the `auto` fallback, which puts that screen on the wrong side.

```lua
hl.monitor({ output = "DP-1", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1 })
-- or with explicit resolution/position:
-- hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1 })
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "2560x0", scale = 1 })
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

- `unzip` - obviously helps us w/ zip files
- `gnome-keyring` - helps us maintain a keychain across different apps
- `libsecret` - library necessary for gnome-keyring
- `seahorse` - GUI to manage the keyring; **required** to blank the login keyring password for autologin auto-unlock (see the autologin keyring step below)

Note: `numlockx` is not needed - Hyprland handles numlock via `input = { numlock_by_default = true }` in `~/.config/hypr/options.lua`

```
pacman -S unzip gnome-keyring libsecret seahorse
```

enable time synchronization with `systemd-timesyncd` (ships with systemd, nothing to install). Don't install the `ntp` package: `ntpd` starts before the NICs finish IPv6 duplicate address detection, fails to bind the still-tentative link-local address, and segfaults in that error path (`daemon child died with signal 11`); systemd retries 5 times in 2 seconds and then gives up with `start-limit-hit`, leaving the clock unsynced for the whole boot. `timesyncd` is a plain SNTP client with no listening sockets, so it has no such race.

```
systemctl enable systemd-timesyncd.service --now
timedatectl set-ntp true
```

verify with `timedatectl` (`System clock synchronized: yes`, `NTP service: active`) and `timedatectl timesync-status` (shows the selected `*.arch.pool.ntp.org` server and offset)

login to user

```
login
```

Let's enable pipewire for the user (pipewire replaces pulseaudio as the sound server, `pamixer` is the CLI mixer)

```
systemctl --user enable pipewire pipewire-pulse wireplumber --now
```

Two problems need fixing, and the `pipewire` stow package has a drop-in for each:

- **Node suspend/idle.** When Zoom goes quiet, the PipeWire sink can take a second or two to wake up and clip the start of sentences. The `pw-metadata` runtime commands don't survive a reboot, so `~/.config/wireplumber/wireplumber.conf.d/50-no-suspend.conf` sets `session.suspend-timeout-seconds = 0` on every ALSA node.
- **No realtime priority.** PipeWire gets realtime scheduling from `rtkit`, which is D-Bus activated. At login PipeWire can ask before rtkit is up; the request fails silently and every audio thread stays at nice 0 / `SCHED_OTHER` until the next restart, so a busy CPU makes playback stutter even with the network fine. `~/.config/systemd/user/pipewire.service.d/10-wait-for-rtkit.conf` wakes rtkit before PipeWire starts. `wireplumber` and `pipewire-pulse` are ordered after `pipewire.service`, so it covers all three. The drop-in can't install rtkit, and it starts PipeWire anyway when rtkit is missing, so check with the loop below: the 2026-11 reinstall ran five days without rtkit (PipeWire logs `RTKit error: org.freedesktop.DBus.Error.ServiceUnknown`) before anyone noticed.

```
./install.sh pipewire
systemctl --user daemon-reload
systemctl --user restart pipewire pipewire-pulse wireplumber
# want nice -11 on the main threads and SCHED_RR 20 on data-loop.0
for t in /proc/$(pgrep -x pipewire)/task/*; do echo "$(cat $t/comm) nice=$(awk '{print $19}' $t/stat) $(chrt -p ${t##*/} | head -1 | sed 's/.*: //')"; done
# want session.suspend-timeout-seconds = "0"
wpctl inspect @DEFAULT_AUDIO_SINK@ | grep suspend-timeout
```

Heavy jobs (Gradle, big test suites, batch sims) should go through `lowprio` (stowed to `~/.local/bin` by the `zsh` package). It runs the command in a transient user scope with `CPUWeight=idle` (kernel `cpu.idle=1`, so the job only gets CPU nobody else wants; `nice 19` alone still competes), `MemoryMax=16G` and no swap, so the kernel OOM-kills the job instead of freezing the desktop. Override the cap with `LOWPRIO_MEM=24G lowprio ...`.

Ensure we're automatically logged in, `systemctl edit getty@tty1.service` and add:

```
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin nate --noclear %I $TERM
```

Hyprland auto-launches from `.zshrc` when on tty1 (no display manager needed). The dbus setup is handled in `~/.config/hypr/autostart.lua` on the `hyprland.start` event:

```lua
-- Already in autostart.lua:
hl.on("hyprland.start", function()
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
end)
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

**Autologin caveat - blank the login keyring password.** `pam_gnome_keyring` can only auto-unlock the keyring when it captures your login password at the `auth` step. With getty `--autologin` no password is ever entered, so the keyring stays locked and you get prompted to unlock it manually after boot. The fix is to give the login keyring an **empty** password so `gnome-keyring-daemon` unlocks it automatically:

1. Install and open **Seahorse** (`pacman -S seahorse`, the "Passwords and Keys" app).
2. In the sidebar right-click the default keyring - labeled **Default Keyring** (stored as `~/.local/share/keyrings/Default_Keyring.keyring`; older setups may call it "Login") → **Change Password**.
3. Enter the current passphrase, leave the new password **blank**, confirm, and accept the "store unencrypted" warning.

The keyring now auto-unlocks on every autologin with no prompt. (Secrets are stored unencrypted on disk - acceptable here because the disk is the trust boundary on a single-user autologin workstation.) If the keyring holds nothing you care about, you can instead delete `~/.local/share/keyrings/*` and a fresh blank keyring is created on next login.

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
cd ~/Sites && git clone https://github.com/NathanielInman/dotfiles.git dot-files
cd dot-files
```

#### Why `~/.local` is a real directory

`~/.local` must be a plain directory on `@home`, never a symlink into this repo. Until 2026-11-06 it was one (`~/.local -> Sites/dot-files/packages/zsh/.local`) so that stow could track the scripts in `~/.local/bin`. The side effect was that everything apps keep in `~/.local/share` and `~/.local/state` landed inside `~/Sites` too: 5.3 GB, including the 3.1 GB Steam client. That's on the data drive, and the `sites` snapper config snapshots it every hour. Now `install.sh` creates `~/.local/bin` before stowing `zsh`, so stow can't fold the directory and links each tracked script in `packages/zsh/.local/bin` individually. The `.gitignore` ignores everything else under `packages/zsh/.local`. A new script added to that `bin/` gets tracked like any other file; rerun `./install.sh -r zsh` to link it.

To undo a folded `~/.local` (as on 2026-11-06), close Steam and anything else writing there, then copy everything except the tracked scripts out, swap, and restow:

```
P=~/Sites/dot-files/packages/zsh/.local
rsync -aHAX $(git -C ~/Sites/dot-files ls-files packages/zsh/.local | sed 's|packages/zsh/.local|--exclude=|') $P/ ~/.local.new/
rm ~/.local && mv ~/.local.new ~/.local
git -C ~/Sites/dot-files clean -ffdX packages/zsh/.local && ~/Sites/dot-files/install.sh -r zsh
```

Afterwards, fix anything that recorded the old real path. Find it with `find ~/.local ~/.steam -lname "$P*"` and `grep -rIl "$P" ~/.local ~/.steam`, skipping logs. On 2026-11-06 that was: Steam's runtime symlinks, `~/.steam/*` links, `libraryfolders.vdf` and `registry.vdf`, Steam's Vulkan layer JSONs, and pipx (`rm -rf ~/.local/share/pipx/shared && pipx reinstall trcli`).

Install the stow packages for the Wayland setup (the full list is in the [README](../README.md#available-packages); `./install.sh -a` installs all of them):

```
./install.sh hyprland waybar swaync walker kitty zsh git nvim starship vim topgrade task chrome
```

Then install the system-level files (Hyprland launcher, NVIDIA profile, Bluetooth fixes, Rime shutdown fix, VPN DNS hook). Each one prompts, and the ones for tools that aren't installed yet are skipped, so rerun it after the later sections:

```
./install.sh -s
```

Enable waybar's user service so systemd revives it if it ever segfaults
(autostart.lua only does `systemctl --user start waybar.service`; the
packaged unit ships `Restart=on-failure`):

```
systemctl --user enable waybar
```

The hyprland package also stows `headset-autoswitch.service` (follows the Arctis
headset between the base station and the speakers, see the Bluetooth notes near
the top). Enable it on machines that have the base station plugged in:

```
systemctl --user enable --now headset-autoswitch
```

To remove a package's symlinks later, run `./install.sh -u <package>`.
Copy any `usr/share/applications/` files to `/usr/share/applications/` by hand to
hide unused/unwanted apps from walker.

Now install web browser

```
paru -S google-chrome
```

## CLI Configuration

We start by using our package manager `pacman` to get all necessary binaries. The system `nodejs` gets pulled in as a dependency (e.g. by `vscode-langservers-extracted`); `pnpm` installs and pins any other Node versions a project needs.

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
- `git-delta` by dandavison is an amazing pager tool for git diffs. The stowed `packages/git/.gitconfig` sets `core.pager = delta`, so this is not optional: without the package installed, every `git log`/`git diff` fails with `cannot run delta: No such file or directory` / `fatal: unable to execute pager 'delta'`
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
- `neovim` is the primary editor; its config is the stowed `nvim` package
- `tree-sitter-cli` is required by nvim-treesitter's `main` branch to generate and compile parsers (it uses the already-installed `nodejs` for the `generate` step). Without it, treesitter cannot build parsers and opening files fails with parser/query mismatch errors such as `Query error: Invalid field name "operator"`. After install, parsers are built with `:TSUpdate` (or automatically via `require('nvim-treesitter').install(...)` in the nvim config)
- `google-cloud-cli` provides the `gcloud` command for managing Google Cloud from the terminal (the `gsutil` and `bq` tools are split into the optional `google-cloud-cli-gsutil` and `google-cloud-cli-bq` packages)
- `aws-cli-v2` provides the `aws` command for managing Amazon Web Services from the terminal (`~/.aws/` is not stowed; it holds the SSO profiles and is set up locally)
- `kubectl` is the Kubernetes CLI for talking to clusters (the DT GKE clusters behind `app-agent-events.<ns>.gcp-*.digitalturbine.io`, etc.); it is in the official `extra` repo. Our clusters are GKE, so authenticating also needs the `gke-gcloud-auth-plugin` (AUR `google-cloud-cli-component-gke-gcloud-auth-plugin`, installed on the `paru` line below); without it `kubectl` errors with `gke-gcloud-auth-plugin ... not found`
- `jira-cli` is the AUR package providing the `jira` command for Atlassian Jira from the terminal (issues, sprints, boards); authenticate with `jira init`
- `maven` provides the `mvn` command for building and testing the Java/Maven microservices (e.g. `apk-fetch-service`); it depends on a JDK and will pull one in if none is present, though `jdk-openjdk` (see the Neovim language toolchains section below) already satisfies that
- `scrcpy` mirrors and controls an Android device from the desktop over ADB (USB or wireless), with no root and nothing to install on the phone: it pushes a short-lived server, runs it with the shell UID via `app_process`, and streams a hardware-encoded H.264 feed back over the ADB socket while injecting mouse/keyboard events as real touches. It pulls in `android-tools` (which provides `adb`/`fastboot`) as a dependency. Enable USB debugging on the device, accept the RSA prompt, then just run `scrcpy`; `paru -S android-udev` adds the vendor udev rules if a device shows as `unauthorized`/`no permissions` in `adb devices`
- `trcli` is the TestRail CLI for reporting automated test results to TestRail - it is a Python package (not in the Arch repos), so it is installed with `pipx` rather than on the `paru` line below (see the next step)
- `zsh-completions` adds extra completion definitions for zsh
- `atuin` replaces shell history with a searchable SQLite database (`history` alias and init in `.zshrc`; the history lives in `~/.local/share/atuin`)
- `broot` is a tree-style directory navigator (the `tree` alias and `br` launcher in `.zshrc`)
- `chafa` renders images in the terminal (the `icat` alias)
- `uv` is the fast Python package/project runner; `uv run --with <pkg>` covers one-off scripts without touching the system Python
- `bun` and `npm` are JavaScript runtimes/package managers alongside `pnpm`
- `cloudflared` is the Cloudflare Tunnel client
- `rsync` for copying and syncing directories (local or over SSH)

```
paru -S curl wget diff-so-fancy eza bat fd ripgrep git github-cli glab git-delta zsh zsh-completions python-pip pyenv wl-clipboard scc duf bandwhich fkill gping jq neovim tree-sitter-cli google-cloud-cli aws-cli-v2 kubectl jira-cli maven scrcpy atuin broot chafa uv bun npm cloudflared rsync
```

After installing, authenticate Google Cloud with `gcloud init` (or `gcloud auth login`). AWS uses IAM Identity Center (SSO): create the `sso-session` and profile with `aws configure sso`, then `aws sso login` when the session expires and `aws sts get-caller-identity` to confirm it can authenticate. Sign in to the git forges with `gh auth login` and `glab auth login`.

`kubectl` ships no config of its own; it reads `~/.kube/config`, which `gcloud` writes per cluster. Because the DT clusters are GKE, first install the auth plugin (AUR, kept off the `paru` line above since it's a gcloud component):

```
paru -S google-cloud-cli-component-gke-gcloud-auth-plugin
```

Then pull a cluster's credentials into `~/.kube/config` (gcloud must already be authenticated). List clusters with `gcloud container clusters list`, then:

```
gcloud container clusters get-credentials <cluster> --region <region> --project <project>
```

Verify the context works with `kubectl config current-context` and `kubectl get ns`. Switch between clusters with `kubectl config use-context <name>`.

`trcli` is not packaged for Arch, so install it in an isolated environment with `pipx` (which keeps it off the system Python). `python-pipx` comes from the official repos:

```
sudo pacman -S --needed python-pipx
pipx install trcli
```

This drops the `trcli` binary in `~/.local/bin` (already on `PATH` via `.zshrc`); verify with `trcli --help`.

### Docker

Docker runs the throwaway local dependencies for work services (Kafka, Postgres, Pact stub servers) via `docker compose`. Add yourself to the `docker` group so it works without `sudo`. A group added after login only applies after you log out and back in, so on a rebuild put it in the `useradd -G` list instead. Its data root lives on scratch (`/etc/docker/daemon.json`, see [Scratch and data drives](#scratch-and-data-drives)):

```
pacman -S docker docker-buildx docker-compose
sudo systemctl enable --now docker.socket
sudo usermod -aG docker $USER
```

### Neovim language toolchains

The Neovim config installs language servers, formatters and linters automatically
via `mason` on first launch. A few of those are thin clients that need a language
runtime present on the system (mason installs the server, not the runtime):

- `jdk-openjdk` - required by the Java language server (`jdtls`)
- `dotnet-sdk` - required by the C# server (`roslyn`) and formatter (`csharpier`)
- `elixir` - required by the Elixir server (`lexical`) and `mix format` (pulls Erlang/OTP)

```
pacman -S jdk-openjdk dotnet-sdk elixir
```

The DT Java/Maven microservices (e.g. `apk-fetch-service`) build and test against **JDK 21** (the CI image is `maven:3.9.11-amazoncorretto-21`); the latest `jdk-openjdk` is too new for them (ByteBuddy/Mockito break). Install `jdk21-openjdk` alongside the default and point a build at it without changing the system default:

```
pacman -S jdk21-openjdk
# per-build, leaves jdtls et al. on the default JDK:
JAVA_HOME=/usr/lib/jvm/java-21-openjdk mvn ...
# or switch the system default if you prefer: archlinux-java set java-21-openjdk
```

Rust tooling (`rust-analyzer`, `rustfmt`, `clippy`) comes from the `rustup` install
later in this guide. Everything else (`gopls`, `lua-language-server`, `biome`,
`prettier`, `markdown_oxide`, `markdownlint`, etc.) is handled entirely by mason.

### Game development (Godot / C#)

The DET-33 game port (`~/Sites/det33-godot`) is a Godot 4 / C# project, so it needs
the **Mono/.NET build** of Godot - the plain `godot` package can't build or run C#
scripts. The `godot-mono` package ships the editor binary at `/usr/bin/godot-mono`,
which is the binary the `det33`/`gym`/`compass` aliases in `.zshrc` and the project's
build commands call (note: **not** `godot`). The `dotnet-sdk` it needs to compile the
C# is already installed in the step above.

- `godot-mono` - Godot 4 engine with C#/.NET support (binary: `godot-mono`)

```
pacman -S godot-mono
```

Arch's `godot-mono` links the system Embree, whose AVX-512 path segfaults in occlusion culling on the Ryzen 9800X3D, so day to day the official builds run instead, unpacked under `/scratch/godot` (the package stays for its dependencies and as a fallback):

```
mkdir -p /scratch/godot/std-4.7.2 && cd /scratch/godot
curl -LO https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_mono_linux_x86_64.zip
curl -LO https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
unzip Godot_v4.7.2-stable_mono_linux_x86_64.zip && unzip -d std-4.7.2 Godot_v4.7.2-stable_linux.x86_64.zip && rm *.zip
```

`./install.sh -s` puts the `godot` and `godot-mono` launchers (`usr/local/bin/` in this repo) in `/usr/local/bin`, ahead of `/usr/bin/godot-mono` on PATH and visible to Switchyard's units. 4.7.2 sometimes aborts on its way out of `--headless --import` after the import has finished (`ERROR: Parameter "singleton" is null`, at `is_cmdline_mode`, exit 134). The launchers turn core dumps off for `--import` runs only, so each of those leaves one journal line instead of a 60-270 MB dump; game and test crashes keep theirs. Switchyard's game tasks retry the import when it dies by signal.

To build release exports (`godot-mono --headless --export-release`) you also need the
matching export templates, which are AUR-only:

```
paru -S godot-mono-export-templates-linux
```

Windows exports shell out to `rcedit` (a Windows tool) through Wine to stamp the exe icon and version info, the same way the `release.yml` workflow does in CI. `steamcmd` (the stowed `~/.local/bin/steamcmd`, see `det33-godot/docs/steam.md`) is a 32-bit binary and needs the 32-bit C runtime from `multilib`. `icoutils` provides `icotool`/`wrestool` for building and inspecting Windows `.ico` icons.

```
pacman -S wine wine-mono lib32-gcc-libs icoutils
```

The project lives in `~/Sites/det33-godot` (it moved off the `~/Rime` SMB share on 2026-11-06; SMB has no exec bits and was slow for git). The art source folders such as `~/Rime/DET-33` are still on the share.

For 3D asset work, Blender is in the official repos:

- `blender` - 3D modeling/animation suite; runs natively on Wayland/Hyprland, and Cycles GPU rendering (OptiX) works out of the box with the `nvidia-open`/`nvidia-utils` driver installed above (install `cuda` additionally only if CUDA-specific rendering is needed)

```
pacman -S blender
```

- `oxipng` - lossless PNG compression optimizer; the DET-33 spritesheet renderers (`render_sprites.py` in `~/Rime/DET-33/props/` and `~/Rime/DET-33/enemies/`) shell out to it to shrink each finished sheet without altering a pixel

```
pacman -S oxipng
```

- `potrace`, `librsvg`, `imagemagick`, `python-numpy` - the DET-33 icon vectorizer (`tools/vectorize-icon.py` in the game repo) that replaced the Illustrator image-trace step: numpy snaps a raw generated icon to two inks, `potrace` traces each ink to SVG paths, `rsvg-convert` (from `librsvg`) renders the SVG master to the 1024px PNG, and `magick` decodes the source and builds the 4-up pick sheet

```
pacman -S potrace librsvg imagemagick python-numpy
```

For capturing marketing assets of the game (Steam screenshots, trailer footage):

- `gpu-screen-recorder` (**AUR**) - low-overhead screen recorder that feeds NVENC directly, so recording gameplay costs almost nothing; its replay-buffer mode keeps a rolling last-N-seconds in memory and a hotkey flushes it to disk (shadowplay-style), so a good moment is never missed. `wf-recorder` (installed with the Hyprland line above) is screencopy-based and drops frames under game load, so prefer this for gameplay capture
- `mpv` - media player used to scrub the captured footage; its `s` key exports the current frame as a PNG, which is how still screenshots are harvested out of 1440p60 recordings instead of chasing live screenshots of a moving game
- `kdenlive` - non-linear video editor for cutting the trailer

```
pacman -S mpv kdenlive
paru -S gpu-screen-recorder
```

### MUD development (PLOS:Origins)

PLOS:Origins (`~/Sites/plos-origins`) is a Rust MUD server played over telnet, TLS and WebSocket, so it needs a MUD client for playtesting. Agents drive TinTin++ inside tmux (`send-keys` to type, `capture-pane` or a `#log` file to read) so they see exactly what a player sees.

- `tmux` - terminal multiplexer that hosts the scripted TinTin++ sessions
- `tintin` (**AUR**) - TinTin++ console MUD client (binary: `tt++`); speaks GMCP through `#event` scripts

```
pacman -S tmux
paru -S tintin
```

### Android development (Kotlin / Jetpack Compose)

The DT `Launchpad` app (`~/Sites/LaunchPad`) is a Kotlin + Jetpack Compose Android
project built with Gradle. Most of what it needs is already installed elsewhere in
this guide, so the only genuinely Android-specific addition is the SDK manager:

- **JDK 17+** - already satisfied by `jdk21-openjdk` from the Neovim language toolchains
  section (the build's `sourceCompatibility`/`jvmTarget` is 17, and AGP runs fine on 21)
- **`adb`/`fastboot`** - already present via `android-tools`, which `scrcpy` pulls in
- **No system `gradle` or `kotlin` needed** - the repo ships a `./gradlew` wrapper pinned
  to its own Gradle version, which in turn drives the Kotlin compiler; never install a
  standalone one
- `android-sdk-cmdline-tools-latest` - the AUR package that provides `sdkmanager` and
  `avdmanager` (the runners that download the rest of the SDK). As of `22.0` it installs
  them read-only under `/opt/android-sdk` (root-owned, no writable `android-sdk` group),
  and `sdkmanager` warns that it's deprecated in favour of `android sdk` but still works

```
paru -S android-sdk-cmdline-tools-latest
```

Because `/opt/android-sdk` is root-owned, keep the actual SDK components in a
user-writable root under `$HOME` instead (this also lets Gradle self-install anything
missing). Add these to `~/.zshenv` so every shell and Gradle see them:

```
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export PATH=$PATH:/opt/android-sdk/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
```

Then accept the licenses and install the platform + build-tools the project targets
(`compileSdk`/`targetSdk = 36`, so API 36; `minSdk = 24`) into that home root with
`--sdk_root`:

```
yes | sdkmanager --sdk_root="$ANDROID_HOME" --licenses
sdkmanager --sdk_root="$ANDROID_HOME" "platform-tools" "platforms;android-36" "build-tools;36.0.0"
```

Gradle reads the SDK path from a per-project `local.properties` (git-ignored, never
committed). Create it once per checkout:

```
echo "sdk.dir=$HOME/Android/Sdk" > ~/Sites/LaunchPad/local.properties
```

Build and test from the repo root with the wrapper (never a system `gradle`):

```
./gradlew :app:assembleDebug   # build the debug APK
./gradlew test                 # run unit tests
```

To run it, deploy to a physical device over USB with debugging enabled - `adb install`
the APK, then mirror/control it with `scrcpy` (already installed). If you'd rather use an
emulator instead of hardware, install `android-emulator` plus a system image
(`sdkmanager --sdk_root="$ANDROID_HOME" "system-images;android-36;google_apis;x86_64"`)
and create an AVD with `avdmanager`.

### First-run authentication for the service CLIs

The pattern for both `jira` and `trcli` is the same: **secrets (API tokens, passwords) live in [broker](https://github.com/NathanielInman/credential-broker)**, while non-secret config (servers, default projects) lives in each tool's own config directory. Both tools only read credentials from environment variables, so `.zshrc` wraps them in `jira()` and `trcli()` functions that run them through `broker exec --request` (a desktop window asks for the vault unlock when there's no live grant). Nothing is exported from `~/.zshenv`, so no shell or agent carries them around. Placeholders like `<token>` are stand-ins; substitute real values locally.

**TestRail (`trcli`)** has no login step - it reads everything from `TR_CLI_`-prefixed environment variables (its `auto_envvar_prefix`). Store them in broker (`set` prompts for each value):

```
broker set TR_CLI_HOST --public --desc "TestRail host URL, read by trcli"
broker set TR_CLI_USERNAME --public --desc "TestRail username (email), read by trcli"
broker set TR_CLI_PASSWORD --desc "TestRail password, read by trcli"   # or TR_CLI_KEY if the instance requires API keys
```

Every command then picks them up automatically; you only add `--project "<name>"` per run. Confirm auth with a read-only API call (expect `200`):

```
broker exec --request TR_CLI_HOST TR_CLI_USERNAME TR_CLI_PASSWORD -- sh -c \
  'curl -s -o /dev/null -w "%{http_code}\n" -u "$TR_CLI_USERNAME:$TR_CLI_PASSWORD" "$TR_CLI_HOST/index.php?/api/v2/get_projects"'
```

**Jira (`jira-cli`)** splits auth in two. The API token comes from the `JIRA_API_TOKEN` environment variable - the *only* secret it reads, and note there is **no** env var for the server URL - while server, login, default project and board are written to `~/.config/.jira/.config.yml` by the `jira init` wizard.

1. Generate a token. Jira Cloud: <https://id.atlassian.com/manage-profile/security/api-tokens>. Self-hosted Server/DC: a Personal Access Token from your Jira profile (basic auth there also still accepts your account password - Cloud does not, it requires a token).
2. Store it in broker:

   ```
   broker set JIRA_API_TOKEN --desc "Atlassian API token, read by jira-cli"
   ```

3. Run `jira init` (the `jira()` wrapper in `.zshrc` supplies the token, which `init` needs): choose `cloud` or `local`, enter the server URL, login email, auth type (`basic` for Cloud, `bearer` for a Server/DC PAT), and a default project/board.
4. Verify with `jira me` or `jira issue list`.

Validate that under `core` of `.gitconfig` the `pager` value is set to `delta` to reflect `git-delta` package.

Screen locking is handled by `hyprlock` and idle management by `hypridle`. Both configs live in `~/.config/hypr/` (installed via the hyprland stow package) and still use hyprlang `.conf` files (only the compositor config moved to lua). Lock screen is triggered manually via SUPER+Escape.

Now for installing vim package manager

```
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```

Now that Vundler is installed, we can install all the plugins.

```
vim +PluginInstall +qall
```

Now for configuring the shell. Don't use the oh-my-zsh installer script: it replaces the stowed `~/.zshrc`. `~/.oh-my-zsh` is a stow symlink into `packages/zsh/.oh-my-zsh`, which tracks only `custom/` (the `.gitignore` ignores the rest), so clone oh-my-zsh into it around the tracked files:

```
cd ~/.oh-my-zsh && git init -q && git remote add origin https://github.com/ohmyzsh/ohmyzsh.git \
  && git fetch -q --depth=1 origin master && git checkout -q -f -B master FETCH_HEAD
broot --install    # the `br` launcher .zshrc sources
```

Lets ensure that zsh will have fish-like syntax highlighting & autocompletion

```
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

Install the node package manager pnpm. It also manages extra node versions instead of `nvm` or `n`; the system `nodejs` stays the default `node` on `PATH`.

```
paru -S pnpm
pnpm env use --global lts
pnpm env ls
```

Now we'll install Rust via the `rustup` toolchain manager (the `rustup` package, not the curl installer):

```
pacman -S rustup
rustup default stable
```

> If `paru` was built from source earlier, remove the `rust` package it pulled in first (`sudo pacman -R rust`); it **conflicts with `rustup`**.

Now some rust utils:

- `rusti-cal` is a better calendar
- `melt` is a way of easily extracting zip, gz, Z, bz2, tar, etc
- `tidy-viewer` or "tv" is an easy way to preview csv files
- `pueue` is a tool that helps manage a queue of shell commands (daemon is pueued)
- `cargo-update` adds `cargo install-update -a` to upgrade every cargo-installed binary (topgrade calls this too)
- `cargo-cache` adds `cargo cache` to inspect and prune the `~/.cargo` caches (registry sources, git checkouts, build artifacts)

```
cargo install rusti-cal melt tidy-viewer pueue cargo-update cargo-cache
```

### topgrade (upgrade everything)

`topgrade` is a single command that walks every package manager and tool on this
machine and updates each one - `pacman`/AUR (via `paru`), `rustup` + `cargo`
binaries, `pnpm`, oh-my-zsh and its plugins, `vim`/`nvim` plugins, and more. It
replaces having to remember the individual `pacman -Syyu`, `cargo install-update`,
`pnpm update`, etc. invocations. It's an AUR package (not in the official repos):

```
paru -S topgrade
```

Its config is the stowed `topgrade` package, a small `~/.config/topgrade.toml`
that pins the choices made elsewhere in this guide: `paru` as the AUR helper,
cache cleanup after upgrades, skipping `gcloud` (pacman owns it), ignoring
container images that can't be pulled, rebuilding the Blender MCP venv, and
restarting waybar afterwards so it doesn't keep stale libraries mapped. topgrade
auto-detects everything else. Run it any time with:

```
topgrade
```

## Voxtype (Push-to-Talk Voice-to-Text)

- `voxtype-bin` - push-to-talk voice-to-text tool for Linux, optimized for Wayland
- `wtype` - keyboard simulation for Wayland (recommended by voxtype)

```
paru -S voxtype-bin wtype
```

Run the initial setup to download the Whisper model and configure GPU acceleration:

```
voxtype setup
voxtype setup gpu --enable  # optional, requires vulkan-icd-loader
```

Enable the daemon as a user service so it starts with the session and comes back if PipeWire restarts under it (the `hyprland` package stows a `voxtype.service.d/10-restart.conf` drop-in that sets `Restart=always`):

```
systemctl --user enable --now voxtype
```

Voxtype is bound to F13 (code:191) as push-to-talk in `~/.config/hypr/binds.lua`. [Logbook](https://github.com/NathanielInman/logbook)'s lamp in waybar shows when it listens. Logbook also records meetings to 15-minute WAV chunks and transcribes them with `voxtype transcribe` when they stop, toggled with F14 (code:192); Shift+F14 marks a moment.

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
- `fastfetch` cli system info tool (actively maintained neofetch replacement)
- `sdcv` cli dictionary
- `xsv` is a cli for splitting/joining/analyzing csv files
- `obsidian` is a note-taking application leveraging zettelkasten
- `cronie` cron service to help sync any `notes` and `todo` repo changes automatically, and to run the [nightly `~/Sites` backup](./sites-nightly-backup.md)
- `dog` is a DNS lookup cli info tool
- `bind` provides the standard `dig` (plus `host`/`nslookup`) DNS tools that scripts and tooling reach for; the `named` server it ships stays disabled
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
- `nordic-theme` is a Nord-colored GTK dark theme (matches the Nord palette used across this setup)
- `gtk-engine-murrine` helps with backwards-compatibility themes for gtk2
- `kooha` is a Wayland-native screen recorder (replaces peek)
- `gthumb` is the best tiny app for browsing images
- `vscode-langservers-extracted` unlocks all lsp servers for neovim
- `inxi` is a system information tool that shows everything in one place, like HWiNFO for windows
- `vfox` is a version management tool for multiple programming languages
- `yazi` a faster version of `nnn` with simple controls (file viewer on cli)
- `fselect` is a SQL-like querying tool for the filesystem

```
paru -S slack-desktop discord file-roller ttf-joypixels ncdu lazygit glow glances procs tokei zoxide fzf didyoumean translate-shell fastfetch sdcv xsv obsidian cronie dog bind sd onefetch okular usbutils kooha thunar thunar-volman thunar-archive-plugin ffmpegthumbnailer gvfs gvfs-smb tumbler libgsf galculator nordic-theme gtk-engine-murrine gthumb vscode-langservers-extracted inxi vfox yazi fselect
```

Now set the GTK theme to `Nordic` with the `PragmataPro 11` font and `Adwaita` icons (or use the `nwg-look` GUI from the AUR):

```
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Nordic'
gsettings set org.gnome.desktop.interface font-name 'PragmataPro 11'
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
```

`color-scheme` is the one that matters for Electron/Chromium apps (T3 Code, Slack, Discord): they ask xdg-desktop-portal for the color scheme, the portal reads it from dconf, and without `prefer-dark` their native right-click menus render white. The Hyprland autostart re-applies `color-scheme` and `gtk-theme` on every login, so this is covered even if the step above gets skipped. Check what the portal reports with:

```
busctl --user call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop org.freedesktop.portal.Settings ReadOne ss org.freedesktop.appearance color-scheme
```

`v u 1` means prefer dark, `v u 0` means no preference (light menus).

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

Tasks live in Taskwarrior 3 with `vit` as the TUI. The data is the
`taskchampion.sqlite3` database in its own git repo, cloned into Sites:

```
sudo pacman -S task vit
cd ~/Sites
git clone https://github.com/nathanielinman/tasks.git
```

The `task` stow package (above) points Taskwarrior at it through
`~/.config/task/taskrc` (`data.location=~/Sites/tasks`) and gives vit a
`~/.config/vit/config.ini`, which also keeps vit's first-run "create config?"
prompt from blocking autostart. Hyprland opens vit on workspace 6 at login
(`kitty --class vit -e vit`, pinned by a window rule on class `vit`). Check
with `task next`; vit's own keys are listed with `?` inside it, plus `o` (ours)
to open the task's long-form note.

How tasks are organized (projects, tags, `ref` markers, notes, per-visit
annotations) is a Claude skill kept in the tasks repo. Link it in so every
project's agent sessions pick it up:

```
ln -sfn ~/Sites/tasks/skills/tasks ~/.claude/skills/tasks
```

Taskwarrior 3 can't read the old 2.x `*.data` files. If a clone ever has them
again (history before Oct 2026 does), `task import-v2` moves them into the
database, then delete the `*.data` files to silence the upgrade warning.

Now enable the cronie cron service for systemd and start immediately

```
sudo systemctl enable cronie.service --now
```

cron workfiles are stored under `/var/spool/cron` and `/etc/cron*`. You can edit crontab with `crontab -e`. Go ahead and add those cron actions now to keep things synced:

```
# `crontab -e` then add the following lines to update both automatically hourly
@hourly /home/nate/Sites/dot-files/scripts/cron-git-notes-auto-update.sh
@hourly /home/nate/Sites/dot-files/scripts/cron-git-tasks-auto-update.sh
# nightly safety net so no uncommitted ~/Sites work is ever lost to a dead disk
0 3 * * * /home/nate/Sites/dot-files/scripts/cron-sites-nightly-backup.sh
# refresh pkglist/ so the 3am backup commits any package changes
55 2 * * * /home/nate/Sites/dot-files/scripts/pkglist-refresh.sh
```

The nightly backup is documented in full in [`docs/sites-nightly-backup.md`](./sites-nightly-backup.md): owned repos get an atomic conventional commit + push on the current branch, every other dirty repo is snapshotted non-destructively to a `backup/auto/<host>/<branch>` ref on its remote.

### Network storage: Rime (TrueNAS SMB share)

The TrueNAS box at `192.168.1.51` exposes a `private` SMB share, mounted at `~/Rime` via a systemd **automount** (mounts on first access, not at boot, so a powered-off NAS never blocks boot). Credentials live in a root-only file. In `/etc/fstab`:

```
//192.168.1.51/private  /home/nate/Rime  cifs  credentials=/etc/cifs-credentials/rime,uid=1000,gid=982,file_mode=0664,dir_mode=0775,iocharset=utf8,nofail,_netdev,x-systemd.automount,noauto  0 0
```

```
# /etc/cifs-credentials/rime  (chmod 600, root-owned)
username=ninman
password=<smb-password>
```

The password is the shared ops password stored in broker as `CLAUDE_OPS_PWD`. Write the file without the secret ever hitting a command line, then verify the login before relying on the automount. The `tee` has to run inside `broker exec`, since anything piped out of it gets the value redacted:

```
broker exec --request CLAUDE_OPS_PWD -- sh -c 'printf "username=ninman\npassword=%s\n" "$CLAUDE_OPS_PWD" | sudo tee /etc/cifs-credentials/rime >/dev/null'
sudo chmod 600 /etc/cifs-credentials/rime
sudo smbclient //192.168.1.51/private -A /etc/cifs-credentials/rime -c ls
```

A rejected password shows as `mount error(13): Permission denied` / `NT_STATUS_LOGON_FAILURE`. After enough failures the automount unit itself goes `failed`, so after fixing the credentials run `sudo systemctl reset-failed home-nate-Rime.mount home-nate-Rime.automount && sudo systemctl start home-nate-Rime.automount`.

**Shutdown hang fix.** CIFS mounts hang shutdown: systemd tears the network down before unmounting the share, so the kernel blocks ~180s waiting on the now-unreachable server (`CIFS: VFS: \\192.168.1.51 has not responded in 180 seconds`) before force-killing every other mount - a multi-minute freeze. The fix is a oneshot service that force-lazy-unmounts the share early in shutdown, while the network is still up. It's tracked at [`etc/systemd/system/rime-umount.service`](../etc/systemd/system/rime-umount.service) and installed + enabled by `install.sh`'s system-config step:

```
sudo install -Dm644 etc/systemd/system/rime-umount.service /etc/systemd/system/rime-umount.service
sudo systemctl daemon-reload
sudo systemctl enable rime-umount.service
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

## Claude Code

Install it as `nate` with the native installer, which puts a self-updating binary at `~/.local/bin/claude` (versions under `~/.local/share/claude/versions`, not restored by a migration, so reinstall):

```
curl -fsSL https://claude.ai/install.sh | bash
```

To skip the login on the live ISO entirely, run `rebuild/save-claude-token.sh` on the old machine before wiping it. It stores a one-year `claude setup-token` on Rime, encrypted to the YubiKey, and `rebuild/bootstrap.sh` decrypts it with one touch. The 2026-11-06 rebuild typed the login code three times (live USB as root, first boot as root, then as `nate`), because the backup leaves out `.credentials.json` on purpose: its refresh token rotates, so copies used by several sessions knock each other out.

Don't use `npm install -g` as root: the 2026-11-06 install did that from the chroot, and the root-owned `/usr/bin/claude` could never auto-update. The live ISO is the exception: `npm install -g` is fine there, since it's thrown away. `~/.local/bin` comes before `/usr/bin` on `PATH`, including for T3 Code. Sign in with `claude auth login`. A text-only console can't open the login URL, so render it as a QR code to scan with a phone. Install the helpers with `pacman -S tmux qrencode terminus-font` and run `setfont ter-112n` so the code fits on screen. Then run `claude` inside `tmux`, and in a second pane:

```
tmux capture-pane -p -t :0 | tr -d ' \n' | grep -o 'https://claude\.com/cai/oauth.*Paste' | sed 's/Paste$//' | qrencode -t ansi
```

## Claude Code statusline

The repo ships `scripts/statusline-command.sh` - a custom Claude Code statusline (dir · git branch · model · context % · usage window · cost · session duration). It uses only `jq` plus a cached, bounded call to Anthropic's usage API with your own OAuth token, and honors `CLAUDE_CONFIG_DIR` so the personal and work profiles each read their own credentials/cache.

Wire it into each Claude config dir's `settings.json`. A running session won't pick up a newly-added `statusLine` - start a fresh `claude` to see it.

```bash
for dir in ~/.claude ~/.claude-work; do
  mkdir -p "$dir"; f="$dir/settings.json"; [ -f "$f" ] || echo '{}' > "$f"
  jq --arg cmd "$HOME/Sites/dot-files/scripts/statusline-command.sh" \
     '.statusLine = {type:"command", command:$cmd}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done
```

The `claude` shell function (`.zshrc`) routes work repos (gitlab.com/digitalturbine) to the `~/.claude-work` profile and everything else to personal, each with its own subscription login - see the function for details.

## T3 Code (agent session GUI)

[T3 Code](https://github.com/pingdotgg/t3code) is a desktop front end for the coding agents already installed on the machine: a sidebar of threads grouped by project, each thread driving the real `claude` CLI (plus Codex, OpenCode, etc. if present). It autostarts on workspace 4 (`autostart.lua`).

```
paru -S t3code-bin
```

It never asks for a Claude login of its own. It spawns the installed `claude`, which uses the subscription login from `claude auth login`, so it stays inside Anthropic's subscription terms (unlike tools that lift the OAuth token and call the API directly). Settings > Providers should show Claude as authenticated with the Max plan.

- **One window only.** The app holds Electron's single-instance lock, so a second launch exits immediately (`T3CODE_HOME` and `--user-data-dir` don't get around it). Run sessions in parallel as threads inside the one window instead.
- **Work profile.** T3 Code runs `claude` directly, so the `.zshrc` `claude` function and its digitalturbine routing never fire and every thread uses the personal `~/.claude` login. For DT repos, add a second Claude provider instance in Settings > Providers with `CLAUDE_CONFIG_DIR path` set to `~/.claude-work`, and pick that instance for those threads.
- State lives in `~/.t3` (threads, worktrees) and `~/.config/t3code` (Electron profile).

## Hyprland Plugin Setup

No plugins are needed anymore: the scrolling/column-based layout (like
PaperWM) that used to come from the `hyprscrolling` plugin is built into
Hyprland core since 0.55, configured via the `scrolling` table in
`~/.config/hypr/options.lua`. `hyprpm` is no longer part of the `hyprland`
package (it is `extra/hyprpm` since 0.57), so it isn't installed. If a plugin is
ever wanted again, `pacman -S hyprpm` and rerun `./install.sh -s`, which offers a
pacman hook (`hyprpm.hook`) that reruns `hyprpm update` after Hyprland upgrades;
lua configs load plugins via `hl.plugin`.

## Stow Packages

The package list and descriptions live in the [README](../README.md#available-packages).
`./install.sh -l` shows which ones are currently stowed.

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

## ZSA keyboard (Oryx flashing and live training)

Oryx flashes and live-trains the ZSA keyboard from Chrome over WebHID, which needs the board's `hidraw` nodes to be user-accessible. In `sudo vim /etc/udev/rules.d/50-zsa.rules`:

```
# Rules for Oryx web flashing and live training
KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev", TAG+="uaccess"
KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev", TAG+="uaccess"
```

then add yourself to `plugdev` (`sudo groupadd -f plugdev && sudo usermod -aG plugdev $USER`), `sudo udevadm control --reload-rules`, and log out and back in. ZSA's full rule set (including the legacy webusb rules for firmware older than v21) is at <https://github.com/zsa/wally/wiki/Linux-install>.

## Credentials (broker + YubiKey)

Secrets live in [`broker`](https://github.com/NathanielInman/credential-broker), not in the environment. Its vault is wrapped to a YubiKey over PIV, which needs the smart card stack (`pcsclite`/`ccid` plus the `pcscd` socket), `age`, and `age-plugin-yubikey`. `yubikey-manager` provides `ykman` for PIN/PUK/management-key setup and `libfido2` covers FIDO2 use of the same key. Build/install broker itself from its README.

```
pacman -S age age-plugin-yubikey pcsclite ccid yubikey-manager libfido2
sudo systemctl enable --now pcscd.socket
```

The vault lives in `~/.local/share/broker` on `@home`, so it is **not** in this repo and not in any snapshot. To move it to a new machine, write a passphrase-encrypted backup on the old one and restore it on the new one with the same YubiKey:

```
broker backup -o ~/broker.backup --generate-passphrase   # old machine (touch)
broker restore ~/broker.backup --identity ~/.config/broker/yubikey-identity.txt --force   # new machine
```

Keep the backup file somewhere off the machine and the passphrase in a password manager. The nightly `~/Sites` backup cron also needs `~/.git-credentials` (plaintext HTTPS tokens for github.com and gitlab.com) recreated on a new machine, see [sites-nightly-backup.md](sites-nightly-backup.md#install).

## OpenVPN (DigitalTurbine CloudConnexa)

The work VPN is OpenVPN CloudConnexa, which needs the browser-based SSO login only `openvpn3` supports. NetworkManager isn't installed (networking is `systemd-networkd`), so `nmcli` isn't an option here.

> **Build note:** openvpn3's test suite fails inside makepkg's sandbox: the dbus `request-queue-test` aborts (SIGABRT) because there's no session bus. The build itself is fine, so skip the checks with `--nocheck`. The web/SSO auth step then opens the login in your existing browser session (where you're already signed into your IdP), so it completes automatically.

```bash
# install openvpn3 (skip the dbus test that fails in the build sandbox)
paru -S openvpn3 --nocheck

# show sessions
openvpn3 sessions-list

# make connection
openvpn3 session-start --config ~/dt.ovpn

# disconnect from session
openvpn3 session-manage --disconnect --config ~/dt.ovpn
```

`openvpn3` doesn't apply the VPN-pushed DNS to `tun0`, so internal hosts won't resolve without the `openvpn3-tun-dns` hook that `./install.sh -s` installs. Full write-up: [openvpn3-vpn-dns.md](./openvpn3-vpn-dns.md).

If the VPN stops connecting after a `pacman -Syu` ("New tunnel did not respond"), a `protobuf` soname bump has orphaned the AUR build. Rebuild it with `paru -S --rebuild openvpn3 --nocheck`.
