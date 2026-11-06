# Rebuild scripts

These scripts reinstall this desktop from a blank OS disk with one reboot. They
follow the order in [Rebuild order (one reboot)](../docs/setting-up-archlinux.md#rebuild-order-one-reboot).
The guide explains each piece. The scripts do it.

| Script | Where it runs | What it does |
|---|---|---|
| `save-claude-token.sh` | old machine, before wiping | Stores a one-year `claude setup-token` on Rime, encrypted to the YubiKey |
| `bootstrap.sh` | live ISO, root | Installs live tools, mounts Rime, decrypts the Claude token (one touch), writes `claude-rebuild` |
| `10-live.sh` | live ISO, root | Asks for the password and wipe confirmation, then runs unattended: disks, pacstrap, fstab, `20-chroot.sh` |
| `20-chroot.sh` | chroot, root (started by 10) | Locale, Limine, NVIDIA initramfs, network, user, services, snapper, then `30-chroot-user.sh` |
| `30-chroot-user.sh` | chroot, user (started by 20) | Stow, oh-my-zsh, rustup, paru, AUR list, cargo tools, Claude, crontab, `install.sh -y -s` |
| `40-first-boot.sh` | Hyprland kitty, user | User services, theme, then restore from the backup set (YubiKey, `~/Sites`, home, Claude/T3) |

`config.sh` holds the machine settings (disks, user, hostname, Rime). Every value can be overridden from the environment.

## Running it

On the old machine, while it still works: refresh the backup set (its `refresh-before-switch.sh`). Run `save-claude-token.sh` if the token on Rime is missing or close to its expiry (`~/Rime/rebuild/claude-oauth-token.age.expires`).

On the new machine, boot the Arch ISO in UEFI mode, then:

```
curl -fsSL https://raw.githubusercontent.com/NathanielInman/dotfiles/master/rebuild/bootstrap.sh -o bootstrap.sh
bash bootstrap.sh
tmux new -s rebuild
bash /root/dot-files/rebuild/10-live.sh
```

In a second tmux pane (`Ctrl-b %`), `claude-rebuild` starts Claude already signed in. `10-live.sh` asks its questions at the start and then needs nobody. When it finishes: `umount -R /mnt && reboot`. tty1 logs in and starts Hyprland. Close T3 Code if it opened, and in kitty run `bash ~/Sites/dot-files/rebuild/40-first-boot.sh`.

The OS disk is always wiped. Scratch and data are kept unless `WIPE_SCRATCH=1` / `WIPE_DATA=1`, and a kept disk must already carry its `scratch` / `data` label.

## Critical and minor steps

Every step is marked one or the other:

- **critical**: the machine won't boot or work without it, or later steps depend on it (disks, pacstrap, Limine, initramfs, network, the user, stowing zsh and hyprland, secrets, git access). The phase stops at once. It prints the end of the log and how to resume. Fix the cause, or decide to skip it, and rerun the same command. Finished steps are skipped.
- **minor**: anything that can be fixed after first boot (one AUR package, cargo tools, the theme, a stow conflict, a missing repo package). It is recorded in the followups file and the phase carries on.

Steps also add notes for partial problems, such as one package in a list of thirty.

Controls, as environment variables on any phase:

- `REBUILD_SKIP=id,id` skips steps and records the skip as a followup.
- `REBUILD_RETRY_MINOR=1` retries minor steps that failed on an earlier run (they are otherwise left for later).
- `REBUILD_REDO=id,id` reruns steps that already finished.
- `REBUILD_CONFIRM=wipe` and `REBUILD_PASS_HASH=<openssl passwd -6 hash>` run `10-live.sh` without its prompts.
- `REBUILD_RESTORE=0` skips the restore half of `40-first-boot.sh`.

## Logs and followups (for Claude after first boot)

- `/var/log/rebuild/followups.md`: every failed minor step with its log tail, plus notes from steps. **Work through this file after first boot.** Delete each entry once it is handled.
- `/var/log/rebuild/<phase>.log`: full output of each phase. `<phase>.state` records each step as done or failed-minor.
- `/var/log/rebuild/live/`: the live ISO phase's logs and the live Claude session transcripts (`claude-projects/`). Before rebooting, `bash /root/dot-files/rebuild/10-live.sh --save-logs` copies them again, so the transcript includes everything said after the script ended.
- Rime keeps a copy of all of it under `rebuild/logs/<date>-<host>/`.

## Not covered

Steps that need a person: YubiKey touches, the SMB password (asked once and reused for the installed system), Bluetooth pairing, and sign-ins (Slack, Steam, `gcloud`, `aws sso`). The restore still needs `claude auth login` once in Hyprland, which is a browser click. Project setup (the Android SDK, Steam library at `/data/steam`) stays in the guide.
