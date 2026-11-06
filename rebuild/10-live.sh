#!/usr/bin/env bash
# Phase 1 of the one-reboot rebuild. Run as root on the Arch live ISO after
# bootstrap.sh:
#
#   bash /root/dot-files/rebuild/10-live.sh
#   bash /root/dot-files/rebuild/10-live.sh --save-logs   # copy logs again before reboot
#
# Asks for the user's password and a wipe confirmation first, then runs
# unattended: partitions and mounts the disks, pacstraps the whole package
# list, and runs 20-chroot.sh (system config, user, dot-files, AUR) inside the
# new system. Ends ready to reboot into Hyprland. Rerun after a critical stop
# and it carries on where it left off.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$SRC/rebuild/lib.sh"
# shellcheck source=config.sh
source "$SRC/rebuild/config.sh"

LIVE_DIR=/root/rebuild
SECRET_DIR=/root/rebuild-secret
TARGET_LOG_DIR="/mnt$RB_LOG_DIR"
SITES="/mnt/home/$RB_USER/Sites"

# ---------------------------------------------------------------- steps

do_disks_check() {
    local d seen=()
    for d in "$OS_DISK" "$SCRATCH_DISK" "$DATA_DISK"; do
        [[ -b "$d" ]] || { echo "not a block device: $d"; find /dev/disk/by-id -name "nvme-*" ! -name "*-part*" ! -name "nvme-eui*" | sort; return 1; }
        seen+=("$(readlink -f "$d")")
    done
    [[ $(printf '%s\n' "${seen[@]}" | sort -u | wc -l) -eq 3 ]] || { echo "OS, scratch and data must be three different disks: ${seen[*]}"; return 1; }
    local iso
    iso=$(lsblk -no PKNAME "$(findmnt -no SOURCE /run/archiso/bootmnt 2>/dev/null)" 2>/dev/null || true)
    for d in "${seen[@]}"; do
        [[ -n "$iso" && "$d" == "/dev/$iso" ]] && { echo "$d is the boot USB"; return 1; }
    done
    if [[ "$WIPE_SCRATCH" != 1 ]]; then
        [[ "$(blkid -s LABEL -o value "$SCRATCH_DISK-part1" 2>/dev/null)" == scratch ]] \
            || { echo "WIPE_SCRATCH=0 but $SCRATCH_DISK-part1 has no 'scratch' filesystem. Set WIPE_SCRATCH=1 to format it."; return 1; }
    fi
    if [[ "$WIPE_DATA" != 1 ]]; then
        [[ "$(blkid -s LABEL -o value "$DATA_DISK-part1" 2>/dev/null)" == data ]] \
            || { echo "WIPE_DATA=0 but $DATA_DISK-part1 has no 'data' filesystem. Set WIPE_DATA=1 to format it (loses ~/Sites on it)."; return 1; }
    fi
    lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,LABEL "${seen[@]}"
}

wait_for() {
    local _
    udevadm settle
    for _ in $(seq 1 20); do [[ -b "$1" ]] && return 0; sleep 0.5; done
    echo "device did not appear: $1"
    return 1
}

do_os_partition() {
    umount -R /mnt 2>/dev/null || true
    swapoff -a || true
    sgdisk -Z "$OS_DISK"
    sgdisk -n1:0:+"$ESP_SIZE" -t1:ef00 -c1:ESP -n2:0:0 -t2:8304 -c2:root "$OS_DISK"
    wait_for "$OS_DISK-part1"
    wait_for "$OS_DISK-part2"
    mkfs.fat -F32 -n ESP "$OS_DISK-part1"
    mkfs.btrfs -f -L root "$OS_DISK-part2"
    mount "$OS_DISK-part2" /mnt
    local s
    for s in @ @home @snapshots @log @pkg @swap; do btrfs subvolume create "/mnt/$s"; done
    umount /mnt
}

do_scratch_format() {
    blkdiscard -f "$SCRATCH_DISK" || sgdisk -Z "$SCRATCH_DISK"
    sgdisk -n1:0:0 -t1:8300 -c1:scratch "$SCRATCH_DISK"
    wait_for "$SCRATCH_DISK-part1"
    mkfs.ext4 -F -L scratch "$SCRATCH_DISK-part1"
}

do_data_format() {
    blkdiscard -f "$DATA_DISK" || sgdisk -Z "$DATA_DISK"
    sgdisk -n1:0:0 -t1:8300 -c1:data "$DATA_DISK"
    wait_for "$DATA_DISK-part1"
    mkfs.btrfs -f -L data "$DATA_DISK-part1"
    local tmp
    tmp=$(mktemp -d)
    mount "$DATA_DISK-part1" "$tmp"
    btrfs subvolume create "$tmp/@data" "$tmp/@sites"
    umount "$tmp"
    rmdir "$tmp"
}

mnt() {
    local opts="$1" dev="$2" dir="$3"
    mountpoint -q "$dir" && return 0
    mount --mkdir -o "$opts" "$dev" "$dir"
}

do_mounts() {
    local o=noatime,compress=zstd:1 root="$OS_DISK-part2"
    mnt "$o,subvol=@" "$root" /mnt
    mnt "$o,subvol=@home" "$root" /mnt/home
    mnt "$o,subvol=@snapshots" "$root" /mnt/.snapshots
    mnt "$o,subvol=@log" "$root" /mnt/var/log
    mnt "$o,subvol=@pkg" "$root" /mnt/var/cache/pacman/pkg
    mnt "noatime,subvol=@swap" "$root" /mnt/swap
    mnt "umask=0077" "$OS_DISK-part1" /mnt/boot
    mnt noatime "$SCRATCH_DISK-part1" /mnt/scratch
    mnt "$o,subvol=@data" "$DATA_DISK-part1" /mnt/data
    mnt "$o,subvol=@sites" "$DATA_DISK-part1" "$SITES"
    install -d -m 1777 /mnt/scratch/tmp
    mkdir -p /mnt/scratch/{gradle,vms,avd,docker}
    findmnt -R /mnt -o TARGET,SOURCE,FSTYPE
}

do_swapfile() {
    [[ -f /mnt/swap/swapfile ]] && return 0
    btrfs filesystem mkswapfile --size "$SWAP_SIZE" /mnt/swap/swapfile
}

do_pacstrap() {
    local avail want missing install p
    avail=$(pacman -Slq | sort -u)
    # shellcheck disable=SC2086  # word-split the package list on purpose
    want=$( { printf '%s\n' $CORE_PACKAGES; grep -v '^#' "$SRC/pkglist/repo.txt"; } | sed '/^\s*$/d' | sort -u)
    missing=$(comm -23 <(echo "$want") <(echo "$avail"))
    for p in $missing; do
        if [[ " $CORE_PACKAGES " == *" $p "* ]]; then
            echo "core package $p is not in the repos"
            return 1
        fi
        followup "Package \`$p\` (pkglist/repo.txt) is not in the repos any more. Find what replaced it and install that."
    done
    install=$(comm -12 <(echo "$want") <(echo "$avail"))
    echo "Installing $(echo "$install" | wc -l) packages."
    # shellcheck disable=SC2086
    if pacstrap -K -P /mnt $install; then
        return 0
    fi
    # Escape hatch: one bad package (a conflict, a broken dependency) fails the
    # whole transaction. Install the core set, then the rest one at a time.
    followup "The one-pass pacstrap failed; fell back to installing packages one at a time. See the log for the first error."
    # shellcheck disable=SC2086
    pacstrap -K -P /mnt $CORE_PACKAGES
    for p in $install; do
        arch-chroot /mnt pacman -S --needed --noconfirm "$p" >/dev/null 2>&1 \
            || followup "Package \`$p\` failed to install (try \`sudo pacman -S $p\` to see why)."
    done
}

do_fstab() {
    {
        genfstab -U /mnt \
            | awk -v sites="/home/$RB_USER/Sites" '$2 != "/scratch" && $2 != "/data" && $2 != sites' \
            | sed -E 's/subvolid=[0-9]+,//'
        echo "/swap/swapfile none swap defaults 0 0"
        echo
        echo "# scratch and data: nofail so a dead drive cannot block boot"
        echo "LABEL=scratch  /scratch          ext4   noatime,nofail,x-systemd.device-timeout=10s  0 2"
        echo "LABEL=data     /data             btrfs  noatime,compress=zstd:1,subvol=@data,nofail,x-systemd.device-timeout=10s   0 0"
        echo "LABEL=data     /home/$RB_USER/Sites  btrfs  noatime,compress=zstd:1,subvol=@sites,nofail,x-systemd.device-timeout=10s  0 0"
        echo "/scratch/tmp   /tmp              none   bind,x-systemd.requires-mounts-for=/scratch  0 0"
    } > /mnt/etc/fstab
    cat /mnt/etc/fstab
}

do_rime_creds() {
    [[ -s /root/rime-credentials ]] || { echo "no /root/rime-credentials from bootstrap.sh"; return 1; }
    install -Dm600 /root/rime-credentials /mnt/etc/cifs-credentials/rime
}

do_dotfiles() {
    local dst="$SITES/dot-files"
    if [[ -d "$dst/.git" ]]; then
        echo "kept the existing $dst"
        git -C "$dst" status -sb | head -1
        return 0
    fi
    git clone -q "$SRC" "$dst"
    git -C "$dst" remote set-url origin "$DOTFILES_URL"
    chown -R "$RB_UID:$RB_UID" "$dst"
}

write_chroot_env() {
    local v
    {
        for v in RB_USER RB_UID RB_HOSTNAME RB_TIMEZONE RB_LOCALE RB_KEYMAP DOTFILES_URL OS_DISK \
                 KERNEL_CMDLINE MICROCODE STOW_PACKAGES SYSTEM_UNITS RIME_SHARE RIME_USER AGE_RECIPIENT \
                 RB_LOG_DIR; do
            printf '%s=%q\n' "$v" "${!v}"
        done
        printf 'RB_PASS_HASH=%q\n' "$(cat "$SECRET_DIR/pass.hash")"
        printf 'REBUILD_SKIP=%q\nREBUILD_RETRY_MINOR=%q\nREBUILD_REDO=%q\n' \
            "${REBUILD_SKIP:-}" "${REBUILD_RETRY_MINOR:-0}" "${REBUILD_REDO:-}"
    } > /mnt/root/rebuild.env
    chmod 600 /mnt/root/rebuild.env
}

do_chroot() {
    write_chroot_env
    arch-chroot /mnt /usr/bin/bash "/home/$RB_USER/Sites/dot-files/rebuild/20-chroot.sh"
    rm -f /mnt/root/rebuild.env
}

do_resolv() {
    # arch-chroot bind-mounts over resolv.conf, so this has to happen outside.
    ln -sf ../run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf
}

# Copy this phase's logs, its followups and the live Claude transcripts onto
# the new system and to Rime. Run again (--save-logs) right before rebooting
# to catch anything said after the script finished.
save_logs() {
    local dst="$TARGET_LOG_DIR/live"
    if mountpoint -q /mnt/var/log; then
        mkdir -p "$dst"
        cp -a "$LIVE_DIR/." "$dst/"
        [[ -d /root/.claude/projects ]] && cp -a /root/.claude/projects "$dst/claude-projects"
        if [[ -s "$LIVE_DIR/followups.md" && ! -e "$dst/.followups-merged" ]]; then
            awk 'f; /^## /{ if (!f) { f = 1; print } }' "$LIVE_DIR/followups.md" >> "$TARGET_LOG_DIR/followups.md"
            touch "$dst/.followups-merged"
        fi
        chown -R "$RB_UID:$RB_UID" "$TARGET_LOG_DIR"
        echo "Logs saved to $TARGET_LOG_DIR"
    fi
    if mountpoint -q "$RIME_LIVE_MNT"; then
        local r
        r="$RIME_LIVE_MNT/$RIME_REBUILD_DIR/logs/$(date +%F)-$RB_HOSTNAME"
        mkdir -p "$r"
        if [[ -d "$TARGET_LOG_DIR" ]]; then
            cp -r "$TARGET_LOG_DIR/." "$r/" 2>/dev/null || true
        else
            cp -r "$LIVE_DIR/." "$r/" 2>/dev/null || true
            [[ -d /root/.claude/projects ]] && cp -r /root/.claude/projects "$r/claude-projects"
        fi
        echo "Logs copied to Rime: ${r#"$RIME_LIVE_MNT"/}"
    fi
}

rb_on_critical() { save_logs >/dev/null 2>&1 || true; }

# ---------------------------------------------------------------- main

[[ $EUID -eq 0 ]] || { echo "run as root on the live ISO"; exit 1; }
[[ -d /sys/firmware/efi/efivars ]] || { echo "not booted in UEFI mode"; exit 1; }

rb_init live "$LIVE_DIR"
if [[ "${1:-}" == --save-logs ]]; then
    save_logs
    exit 0
fi

# Everything that needs a person happens here, before the long unattended run.
mkdir -p "$SECRET_DIR" && chmod 700 "$SECRET_DIR"
if [[ ! -s "$SECRET_DIR/pass.hash" ]]; then
    if [[ -n "${REBUILD_PASS_HASH:-}" ]]; then
        printf '%s' "$REBUILD_PASS_HASH" > "$SECRET_DIR/pass.hash"
    else
        pw=""
        rb_ask_secret "Password for $RB_USER (tty login and hyprlock)" pw
        openssl passwd -6 -stdin <<< "$pw" > "$SECRET_DIR/pass.hash"
        unset pw
    fi
fi

step critical disks_check "Check the three disks" do_disks_check

wipes=()
rb_done os_partition || wipes+=("$OS_DISK")
[[ "$WIPE_SCRATCH" == 1 ]] && ! rb_done scratch_format && wipes+=("$SCRATCH_DISK")
[[ "$WIPE_DATA" == 1 ]] && ! rb_done data_format && wipes+=("$DATA_DISK")
if (( ${#wipes[@]} )); then
    echo
    echo "${RB_RED}These disks will be ERASED:${RB_OFF}"
    lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,LABEL "${wipes[@]}"
    if [[ "${REBUILD_CONFIRM:-}" != wipe ]]; then
        read -rp "Type 'wipe' to continue: " answer
        [[ "$answer" == wipe ]] || { echo "Stopped; nothing was changed."; exit 1; }
    fi
fi

echo "From here on it runs unattended. Followups go to $LIVE_DIR/followups.md, then to $RB_LOG_DIR on the new system."
step critical os_partition "Partition and format the OS disk" do_os_partition
[[ "$WIPE_SCRATCH" == 1 ]] && step critical scratch_format "Format the scratch disk" do_scratch_format
[[ "$WIPE_DATA" == 1 ]] && step critical data_format "Format the data disk" do_data_format
rb_forget mounts
step critical mounts "Mount everything under /mnt" do_mounts
step minor swapfile "Create the swapfile" do_swapfile
step critical pacstrap "Install the package list into /mnt" do_pacstrap
step critical fstab "Write /etc/fstab" do_fstab
step minor rime_creds "Reuse the Rime SMB credentials" do_rime_creds
step critical dotfiles "Put dot-files in ~/Sites" do_dotfiles
step critical chroot "Configure the new system (20-chroot.sh)" do_chroot
step critical resolv "Point resolv.conf at systemd-resolved" do_resolv
rb_forget save_logs
step minor save_logs "Save logs to the new system and Rime" save_logs

rb_summary
cat <<EOF

Ready for the only reboot. Before it, if you kept talking to Claude after this
finished, run: bash $SRC/rebuild/10-live.sh --save-logs
Then:  umount -R /mnt && reboot

After the reboot tty1 logs in and starts Hyprland. In a kitty terminal run:
  bash ~/Sites/dot-files/rebuild/40-first-boot.sh
EOF
