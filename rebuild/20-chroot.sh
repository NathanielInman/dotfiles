#!/usr/bin/env bash
# Phase 2, run by 10-live.sh as root inside `arch-chroot /mnt`. Configures the
# system (locale, Limine, NVIDIA initramfs, network, user, services) and then
# runs 30-chroot-user.sh as the user. Settings come from config.sh plus
# /root/rebuild.env written by 10-live.sh.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(dirname "$HERE")"
# shellcheck source=lib.sh
source "$HERE/lib.sh"
# shellcheck source=config.sh
source "$HERE/config.sh"
# shellcheck disable=SC1091
[[ -f /root/rebuild.env ]] && source /root/rebuild.env

U="$RB_USER"
H="/home/$U"
: "${HOSTS_BLOCK:=yandex.ru cdn.dzen.ru yabs.yandex.ru}"

do_locale() {
    sed -i "s/^#\s*\(${RB_LOCALE//./\\.} UTF-8\)/\1/" /etc/locale.gen
    locale-gen
    echo "LANG=$RB_LOCALE" > /etc/locale.conf
    echo "KEYMAP=$RB_KEYMAP" > /etc/vconsole.conf
    ln -sf "/usr/share/zoneinfo/$RB_TIMEZONE" /etc/localtime
    hwclock --systohc || echo "hwclock failed (harmless in some chroots)"
    echo "$RB_HOSTNAME" > /etc/hostname
    {
        echo "127.0.0.1 localhost"
        echo "::1 localhost"
        echo "127.0.1.1 $RB_HOSTNAME"
        local h
        for h in $HOSTS_BLOCK; do echo "127.0.0.1 $h"; done
    } > /etc/hosts
    # limine-snapper-sync matches the boot entry by machine-id, so it has to
    # exist now rather than be generated on first boot.
    [[ -s /etc/machine-id ]] || systemd-machine-id-setup
}

do_bootloader() {
    local disk root_uuid mid
    disk=$(readlink -f "$OS_DISK")
    root_uuid=$(blkid -s UUID -o value "$OS_DISK-part2")
    mid=$(cat /etc/machine-id)
    [[ -n "$root_uuid" && -n "$mid" ]] || { echo "missing root UUID or machine-id"; return 1; }

    install -Dm644 /usr/share/limine/BOOTX64.EFI /boot/EFI/limine/BOOTX64.EFI
    # Fallback path some boards boot first.
    install -Dm644 /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI

    # Drop stale "Limine" entries from an earlier install, then add ours.
    local n
    for n in $(efibootmgr | sed -nE 's/^Boot([0-9A-F]{4})\*? Limine\b.*/\1/p'); do
        efibootmgr -q -b "$n" -B
    done
    efibootmgr --create --disk "$disk" --part 1 --label Limine --loader '\EFI\limine\BOOTX64.EFI' --unicode

    # Keep this nested shape at the ESP root: limine-snapper-sync manages
    # $ESP/limine.conf, finds the entry by the machine-id comment and fills
    # //Snapshots. default_entry uses a path because an index that lands on a
    # directory disables autoboot.
    rm -f /boot/limine/limine.conf
    cat > /boot/limine.conf <<EOF
timeout: 3
default_entry: Arch Linux/Linux

/+Arch Linux
comment: machine-id=$mid

    //Linux
    protocol: linux
    kernel_path: boot():/vmlinuz-linux
    kernel_cmdline: root=UUID=$root_uuid rootflags=subvol=@ $KERNEL_CMDLINE
    module_path: boot():/$MICROCODE.img
    module_path: boot():/initramfs-linux.img

    //Snapshots
EOF
    cat /boot/limine.conf
}

do_limine_hook() {
    install -Dm644 /dev/stdin /etc/pacman.d/hooks/99-limine.hook <<'EOF'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = limine

[Action]
Description = Deploying Limine EFI binary to the ESP
When = PostTransaction
Exec = /bin/sh -c 'cp /usr/share/limine/BOOTX64.EFI /boot/EFI/limine/BOOTX64.EFI && cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI'
EOF
}

do_initramfs() {
    # Load the NVIDIA modules early and drop the kms hook (it pulls in nouveau).
    sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    sed -i '/^HOOKS=/ s/ kms//' /etc/mkinitcpio.conf
    grep -E '^(MODULES|HOOKS)=' /etc/mkinitcpio.conf
    printf 'options nvidia_drm modeset=1 fbdev=1\noptions nvidia NVreg_PreserveVideoMemoryAllocations=1\n' > /etc/modprobe.d/nvidia.conf
    echo 'blacklist nouveau' > /etc/modprobe.d/nouveau-blacklist.conf
    mkinitcpio -P
}

do_memory() {
    printf '[zram0]\nzram-size = ram / 4\n' > /etc/systemd/zram-generator.conf
    # /tmp is the scratch disk (see fstab); clean anything untouched for 7 days.
    echo 'Q /tmp 1777 root root 7d' > /etc/tmpfiles.d/tmp.conf
}

do_network() {
    install -Dm644 /dev/stdin /etc/systemd/network/20-ethernet.network <<'EOF'
[Match]
Type=ether
Kind=!*

[Network]
DHCP=yes
MulticastDNS=yes

[DHCPv4]
RouteMetric=100

[IPv6AcceptRA]
RouteMetric=100
EOF
}

do_user() {
    groupadd -f plugdev
    local groups=wheel g
    for g in users docker plugdev; do
        if getent group "$g" >/dev/null; then
            groups+=",$g"
        else
            followup "Group \`$g\` did not exist, so $U is not in it. Install its package, then \`sudo usermod -aG $g $U\` and log out and back in."
        fi
    done
    if ! id "$U" &>/dev/null; then
        # ~/Sites is already a mountpoint, so useradd finds the home dir and
        # skips /etc/skel; copy it by hand below.
        useradd -m -u "$RB_UID" -G "$groups" -s /bin/zsh "$U"
        local f
        for f in /etc/skel/.[!.]*; do
            [[ -e "$f" ]] || continue
            cp -rn "$f" "$H/"
            chown -R "$U:$U" "$H/${f##*/}"
        done
    else
        usermod -aG "$groups" "$U"
    fi
    chown "$U:$U" "$H"
    [[ -n "${RB_PASS_HASH:-}" ]] && usermod -p "$RB_PASS_HASH" "$U"
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/10-wheel-nopasswd
    chmod 440 /etc/sudoers.d/10-wheel-nopasswd
    visudo -cf /etc/sudoers.d/10-wheel-nopasswd
    id "$U"
}

do_home() {
    chown "$U:$U" "$H/Sites" /data /scratch /scratch/{gradle,vms,avd}
    chown -R "$U:$U" "$H/Sites/dot-files"
    # A nested subvolume, so @home snapshots skip the cache.
    if [[ ! -e "$H/.cache" ]]; then
        btrfs subvolume create "$H/.cache"
    fi
    chown "$U:$U" "$H/.cache"
    install -d -o "$U" -g "$U" "$H/Rime"
}

do_login() {
    install -Dm644 /dev/stdin /etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $U --noclear %I \$TERM
EOF
    echo 'export EDITOR=vim' > /etc/profile.d/editor.sh
    ln -sf /usr/bin/vim /usr/bin/vi
    # No display manager, so PAM unlocks the GNOME keyring at tty login.
    if ! grep -q pam_gnome_keyring /etc/pam.d/login; then
        sed -i '/^auth\s\+include\s\+system-local-login/a auth       optional     pam_gnome_keyring.so' /etc/pam.d/login
        sed -i '/^session\s\+include\s\+system-local-login/a session    optional     pam_gnome_keyring.so auto_start' /etc/pam.d/login
    fi
    # /etc/hosts wins over DNS, so its block list works.
    sed -i 's/^hosts:.*/hosts: files mymachines resolve [!UNAVAIL=return] myhostname dns/' /etc/nsswitch.conf
    passwd -l root
}

do_rime() {
    local gid
    gid=$(getent group users | cut -d: -f3)
    sed -i '\|/home/'"$U"'/Rime|d' /etc/fstab
    echo "$RIME_SHARE  /home/$U/Rime  cifs  credentials=/etc/cifs-credentials/rime,uid=$RB_UID,gid=$gid,file_mode=0664,dir_mode=0775,iocharset=utf8,nofail,_netdev,x-systemd.automount,noauto  0 0" >> /etc/fstab
    [[ -s /etc/cifs-credentials/rime ]] || followup "No /etc/cifs-credentials/rime. Write it (see Network storage in docs/setting-up-archlinux.md)."
}

do_docker() {
    install -Dm644 /dev/stdin /etc/docker/daemon.json <<< '{"data-root": "/scratch/docker"}'
}

do_snapper() {
    if [[ ! -f /etc/snapper/configs/root ]]; then
        # create-config refuses while /.snapshots exists; let it make its own
        # subvolume, swap that for the @snapshots mount, remount.
        mountpoint -q /.snapshots && umount /.snapshots
        [[ -d /.snapshots ]] && rmdir /.snapshots
        snapper --no-dbus -c root create-config /
        btrfs subvolume delete /.snapshots
        mkdir /.snapshots
        mount /.snapshots
        chmod 750 /.snapshots
    fi
    if [[ ! -f /etc/snapper/configs/sites ]]; then
        local s="$H/Sites/.snapshots" kept=0
        # A kept data drive already has the subvolume: park it so
        # create-config can run, then put the old snapshots back.
        if [[ -e "$s" ]]; then mv "$s" "$s.keep"; kept=1; fi
        snapper --no-dbus -c sites create-config "$H/Sites"
        if (( kept )); then
            btrfs subvolume delete "$s"
            mv "$s.keep" "$s"
        fi
    fi
    grep SNAPPER_CONFIGS /etc/conf.d/snapper
}

do_units() {
    local u bad=()
    for u in $SYSTEM_UNITS; do
        systemctl enable "$u" 2>&1 | grep -v '^Created symlink' || true
        systemctl is-enabled -q "$u" 2>/dev/null || bad+=("$u")
    done
    if (( ${#bad[@]} )); then
        followup "These units did not enable: ${bad[*]}. Check that their packages are installed, then \`sudo systemctl enable --now\` them."
    fi
}

do_udev_rules() {
    local f
    for f in 50-zsa.rules 70-titan-key.rules; do
        install -Dm644 "$SRC/etc/udev/rules.d/$f" "/etc/udev/rules.d/$f"
    done
}

do_user_phase() {
    # The user phase appends to the same log dir and followups file.
    chown -R "$U:$U" "$RB_LOG_DIR"
    # runuser -l starts from a clean environment, so pass the controls along.
    local envs
    envs=$(printf 'REBUILD_SKIP=%q REBUILD_RETRY_MINOR=%q REBUILD_REDO=%q RB_LOG_DIR=%q STOW_PACKAGES=%q' \
        "${REBUILD_SKIP:-}" "${REBUILD_RETRY_MINOR:-0}" "${REBUILD_REDO:-}" "$RB_LOG_DIR" "$STOW_PACKAGES")
    runuser -l "$U" -s /bin/bash -c "$envs bash '$HERE/30-chroot-user.sh'"
}

do_limine_snapper() {
    pacman -Q limine-snapper-sync >/dev/null || { echo "limine-snapper-sync is not installed (AUR step)"; return 1; }
    printf 'ESP_PATH="/boot"\nSNAPPER_CONFIG_NAME="root"\n' > /etc/default/limine
    systemctl enable limine-snapper-sync.service
}

# ---------------------------------------------------------------- main

rb_init chroot "$RB_LOG_DIR"
step critical locale "Locale, time, hostname, hosts, machine-id" do_locale
step critical bootloader "Install Limine and write /boot/limine.conf" do_bootloader
step minor limine_hook "Pacman hook that redeploys Limine" do_limine_hook
step critical initramfs "NVIDIA early KMS and mkinitcpio" do_initramfs
step minor memory "zram and /tmp cleanup" do_memory
step critical network "Wired network (systemd-networkd)" do_network
step critical user "Create $U with all groups, password, sudo" do_user
step critical home "Own ~/Sites, /data, /scratch; ~/.cache subvolume" do_home
step minor login "tty1 autologin, editor, PAM keyring, nsswitch, lock root" do_login
step minor rime "Rime automount in fstab" do_rime
step minor docker "Docker data root on scratch" do_docker
step minor snapper "Snapper configs for / and ~/Sites" do_snapper
step minor units "Enable system services" do_units
step minor udev_rules "Titan key and ZSA keyboard udev rules" do_udev_rules
step critical user_phase "Dot-files, shell, AUR as $U (30-chroot-user.sh)" do_user_phase
step minor limine_snapper "Snapshots in the boot menu" do_limine_snapper
chown -R "$U:$U" "$RB_LOG_DIR"
rb_summary
