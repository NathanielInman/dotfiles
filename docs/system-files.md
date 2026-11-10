# System files and scripts

Stow only links files into `$HOME`. Everything here lives outside it, so the repo keeps copies under `etc/`, `usr/` and `scripts/` and `./install.sh -s` puts them in place, asking about each one first (`./install.sh -y -s` says yes to all of them). It's safe to run in a chroot: anything that needs udev or D-Bus waits for the first boot.

Most of these exist because something broke on real hardware. The sections below say what broke.

## NVIDIA hoards VRAM under Hyprland

`etc/nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json`

Hyprland's VRAM grew by 10-20 MiB every time a window opened or the config reloaded, and never came back. On the old 4 GB GTX 1650 that added up within a few days. It isn't Hyprland: the NVIDIA driver keeps freed buffers in a reuse pool, and a compositor allocates and frees enough of them to grow that pool for days. Downgrading Hyprland or the driver doesn't help.

The fix comes from an NVIDIA engineer in [Hyprland discussion #10517](https://github.com/hyprwm/Hyprland/discussions/10517): an application profile that matches the `Hyprland` process and sets `GLVidHeapReuseRatio` to `0`. Restart the Hyprland session after installing it. It survives driver updates, and it's harmless once NVIDIA ships a real fix. `install.sh -s` only offers it on machines with the NVIDIA driver.

## Bluetooth headset stutters at full signal

`etc/udev/rules.d/50-bt-adapter-no-autosuspend.rules`, `52-disable-onboard-bt.rules`, `51-bt-force-central.rules`, `etc/systemd/system/bt-force-central.service`, `usr/local/bin/bt-force-central`

Three fixes for one TP-Link UB500 dongle:

- USB autosuspend powered the dongle down after 2 seconds idle and dropped the mouse mid-drag. The first rule keeps it on.
- The board's onboard MediaTek Bluetooth became the default controller and grabbed the mouse. The second rule turns it off so only the UB500 is used.
- When the Arctis headset reconnects on its own it takes the central role, and with the PC as the peripheral A2DP audio stutters even at -20 dBm. On every new link the third rule starts `bt-force-central`, which switches the PC back to central (`hcitool sr <addr> master`) and sets the link policy so the headset can't switch it again.

`sudo hcitool con` should show `CENTRAL`. The [setup guide](setting-up-archlinux.md#first-boot) has the full story.

## Starting Hyprland on tty1

`scripts/hypr-launch` -> `/usr/local/bin/hypr-launch`

`.zshrc` runs this on a tty1 login. It exports the NVIDIA and Wayland variables and then execs Hyprland's own `start-hyprland` crash watchdog. Don't name your launcher `start-hyprland`: since Hyprland 0.55 the package ships a binary by that name, a script in `/usr/local/bin` shadows it, and Hyprland then warns that it was launched without the watchdog. `install.sh -s` also removes a stale `/usr/local/bin/start-hyprland`.

## VPN DNS

`scripts/openvpn3-tun-dns`, `etc/systemd/system/openvpn3-tun-dns@.service`

`openvpn3` doesn't apply the DNS server the VPN pushes, so internal hosts don't resolve. This attaches the resolver to `tun0` on every connect. Write-up: [openvpn3-vpn-dns.md](openvpn3-vpn-dns.md).

## Network share hangs shutdown

`etc/systemd/system/rime-umount.service`

Unmounts the Rime CIFS share early on shutdown, while the network is still up, so shutdown doesn't hang waiting on it.

## hyprpm plugins after an upgrade

`etc/pacman.d/hooks/hyprpm.hook`

Rebuilds hyprpm plugins after every Hyprland upgrade so boot doesn't complain about outdated plugin headers. Only offered when `hyprpm` is installed (a separate package since Hyprland 0.57). No plugins are in use today.

## Hidden desktop entries

`usr/share/applications/` holds `.desktop` overrides, mostly `NoDisplay=true`, to keep unwanted apps out of walker. Copy them to `/usr/share/applications/` by hand.

## Cron jobs and other scripts

`scripts/` holds the cron helpers (add them with `crontab -e`, see the [setup guide](setting-up-archlinux.md)) and a few other tools:

- `cron-git-notes-auto-update.sh` and `cron-git-tasks-auto-update.sh` sync the `notes` and `tasks` repos hourly.
- `cron-sites-nightly-backup.sh` runs at 3am so no uncommitted work in `~/Sites` is ever lost to a dead disk. Repos I own get an atomic commit and push on the current branch. Every other dirty repo is snapshotted to a `backup/auto/<host>/<branch>` ref on its remote without touching the working tree. Write-up: [sites-nightly-backup.md](sites-nightly-backup.md).
- `pkglist-refresh.sh` rewrites `pkglist/` from `pacman -Qqe` at 2:55am, just before the backup commits it.
- `statusline-command.sh` is a Claude Code statusline: directory, branch, model, context, usage window, cost and session length. See the [setup guide](setting-up-archlinux.md#claude-code-statusline).

The rebuild installs two more udev rules, `etc/udev/rules.d/50-zsa.rules` (ZSA keyboard flashing) and `70-titan-key.rules` (Titan security key).
