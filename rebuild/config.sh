# shellcheck shell=bash
# Machine settings for the rebuild phases. Every value can be overridden from
# the environment (OS_DISK=... bash rebuild/10-live.sh). Defaults describe
# FROSTYARCH as built on 2026-11-06 (see docs/setting-up-archlinux.md).

: "${RB_USER:=nate}"
: "${RB_UID:=1000}"
: "${RB_HOSTNAME:=FROSTYARCH}"
: "${RB_TIMEZONE:=America/Chicago}"
: "${RB_LOCALE:=en_US.UTF-8}"
: "${RB_KEYMAP:=us}"

: "${DOTFILES_URL:=https://github.com/NathanielInman/dotfiles.git}"

# Disks, by /dev/disk/by-id so NVMe enumeration order can't pick the wrong one.
# The OS disk is always wiped. Scratch and data are only wiped when asked:
# data holds ~/Sites, so a rebuild of the same machine keeps it by default.
: "${OS_DISK:=/dev/disk/by-id/nvme-Sabrent_296E0799133700049444}"
: "${SCRATCH_DISK:=/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S7L9NJ0L206326Y}"
: "${DATA_DISK:=/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S7L9NJ0L206355B}"
: "${WIPE_SCRATCH:=0}"
: "${WIPE_DATA:=0}"
# limine-snapper-sync keeps a kernel + ~100 MB NVIDIA initramfs per snapshot
# boot entry; 2 GB held about a dozen, the tool recommends 4 GB.
: "${ESP_SIZE:=4G}"
: "${SWAP_SIZE:=16g}"

: "${KERNEL_CMDLINE:=rw quiet nvidia_drm.modeset=1 nvidia_drm.fbdev=1 zswap.enabled=0}"
: "${MICROCODE:=amd-ucode}"

# Always installed, even if missing from pkglist/repo.txt.
: "${CORE_PACKAGES:=base base-devel linux linux-firmware amd-ucode btrfs-progs limine efibootmgr \
nvidia-open nvidia-utils zram-generator snapper snap-pac sudo git stow zsh openssh cifs-utils}"

: "${STOW_PACKAGES:=hyprland waybar swaync walker kitty zsh git nvim starship vim topgrade task chrome pipewire cargo}"

: "${SYSTEM_UNITS:=systemd-networkd systemd-resolved systemd-timesyncd sshd pcscd.socket bluetooth \
cronie docker.socket fstrim.timer paccache.timer systemd-oomd \
snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer btrfs-scrub@data.timer}"

# Rime (TrueNAS SMB share): Claude token, backups, rebuild logs.
: "${RIME_SHARE:=//192.168.1.51/private}"
: "${RIME_USER:=ninman}"
: "${RIME_LIVE_MNT:=/run/rime}"
: "${RIME_REBUILD_DIR:=rebuild}"

# YubiKey 5C (serial 39616611) PIV recipient that the backup archives and the
# Claude token are encrypted to. Public key, safe to commit.
: "${AGE_RECIPIENT:=age1yubikey1q2yaj54k5tsgxpj453spf246ymrh0yqu72kgx4daakydy9y90qvjwxzdt8e}"

# Backup set that 40-first-boot.sh restores from (made by its
# refresh-before-switch.sh on the old machine). Missing: restore is skipped.
: "${RESTORE_DIR:=/home/$RB_USER/Rime/frostyarch-migration-2026-11-04}"

# Where the chroot and first-boot phases log (on the installed system).
: "${RB_LOG_DIR:=/var/log/rebuild}"
