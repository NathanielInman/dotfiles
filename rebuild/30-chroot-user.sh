#!/usr/bin/env bash
# Phase 3, run by 20-chroot.sh as the user (runuser -l) inside the chroot:
# stow dot-files, shell plugins, rustup, paru and every AUR package, cargo
# tools and the other per-user installs. Everything that doesn't need a
# running desktop, so first boot lands in a working Hyprland.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(dirname "$HERE")"
# shellcheck source=lib.sh
source "$HERE/lib.sh"
# shellcheck source=config.sh
source "$HERE/config.sh"

MAKEFLAGS="-j$(nproc)"
export MAKEFLAGS
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PNPM_HOME/bin:$PATH"

clone_once() { [[ -d "$2/.git" ]] || git clone -q --depth=1 "$1" "$2"; }

do_stow_core() {
    # zsh's .zshrc is what starts Hyprland on tty1, so without these two the
    # first boot lands at a bare prompt.
    "$SRC/install.sh" zsh hyprland
}

do_stow_rest() {
    local p bad=()
    for p in $STOW_PACKAGES; do
        [[ $p == zsh || $p == hyprland ]] && continue
        "$SRC/install.sh" "$p" || bad+=("$p")
    done
    (( ${#bad[@]} == 0 )) || followup "Stow failed for: ${bad[*]} (usually a file already in the way). Rerun \`./install.sh <pkg>\` and move the conflict aside."
}

do_ohmyzsh() {
    # Not the installer: it replaces the stowed .zshrc. ~/.oh-my-zsh is the
    # stowed packages/zsh/.oh-my-zsh, which tracks only custom/.
    if [[ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
        cd "$HOME/.oh-my-zsh"
        [[ -d .git ]] || git init -q
        git remote get-url origin &>/dev/null || git remote add origin https://github.com/ohmyzsh/ohmyzsh.git
        git fetch -q --depth=1 origin master
        git checkout -q -f -B master FETCH_HEAD
    fi
    clone_once https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    clone_once https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
}

do_vim() {
    git clone -q https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim" 2>/dev/null || true
    timeout 600 vim -E -s +PluginInstall +qall < /dev/null || true
    [[ -d "$HOME/.vim/bundle/Vundle.vim" ]]
}

do_broot() {
    # What `broot --install` does, minus editing the stowed shell rc files.
    mkdir -p "$HOME/.config/broot/launcher/bash"
    broot --print-shell-function bash > "$HOME/.config/broot/launcher/bash/br"
    broot --set-install-state installed
}

do_rustup() {
    # Before any AUR build, so nothing pulls in the conflicting `rust` package.
    rustup default stable
}

do_paru() {
    command -v paru >/dev/null && return 0
    local d
    d=$(mktemp -d)
    git clone -q https://aur.archlinux.org/paru-bin.git "$d/paru-bin"
    (cd "$d/paru-bin" && makepkg -si --noconfirm)
    rm -rf "$d"
}

do_aur() {
    command -v paru >/dev/null || { echo "paru is missing"; return 1; }
    local p flags failed=()
    for p in $(grep -v '^#' "$SRC/pkglist/aur.txt"); do
        [[ $p == paru-bin ]] && continue
        pacman -Q "$p" &>/dev/null && continue
        # --removemake: --noconfirm answers paru's "remove make dependencies?"
        # with no, which left 25 orphans after the 2026-11 reinstall.
        flags=(--needed --noconfirm --skipreview --removemake)
        # openvpn3's dbus test aborts in makepkg's sandbox; the build is fine.
        [[ $p == openvpn3 ]] && flags+=(--mflags --nocheck)
        echo "--- AUR: $p"
        paru -S "${flags[@]}" "$p" || failed+=("$p")
    done
    if (( ${#failed[@]} )); then
        followup "AUR packages that failed: ${failed[*]}. Retry each with \`paru -S <pkg>\` (heavy ones under lowprio) and read the build error."
    fi
}

do_cargo() {
    cargo install --locked rusti-cal melt tidy-viewer pueue cargo-update cargo-cache
}

do_pnpm() {
    pnpm env use --global lts
}

do_sdcv() {
    [[ -d /usr/share/stardict/dic/stardict-dictd_www.dict.org_gcide-2.4.2 ]] && return 0
    local t
    t=$(mktemp)
    curl -fsSL -o "$t" https://web.archive.org/web/20200630200122/http://download.huzheng.org/dict.org/stardict-dictd_www.dict.org_gcide-2.4.2.tar.bz2
    sudo mkdir -p /usr/share/stardict/dic
    sudo tar -xjf "$t" -C /usr/share/stardict/dic/
    rm -f "$t"
}

do_claude() {
    # Native per-user install: self-updating ~/.local/bin/claude.
    [[ -x "$HOME/.local/bin/claude" ]] && return 0
    curl -fsSL https://claude.ai/install.sh | bash
}

do_pipx() {
    pipx install trcli
}

do_mime() {
    local m
    for m in application/javascript application/json application/x-shellscript text/english text/plain \
             text/x-c text/x-c++ text/x-c++hdr text/x-c++src text/x-chdr text/x-csrc text/x-java \
             text/x-makefile text/x-moc text/x-pascal text/x-tcl text/x-text text/xml; do
        xdg-mime default neovide.desktop "$m"
    done
}

do_crontab() {
    crontab -l &>/dev/null && { echo "crontab already set"; return 0; }
    crontab - <<EOF
@hourly $HOME/Sites/dot-files/scripts/cron-git-notes-auto-update.sh
@hourly $HOME/Sites/dot-files/scripts/cron-git-tasks-auto-update.sh
# nightly safety net: back up any dirty ~/Sites repo to its remote
0 3 * * * $HOME/Sites/dot-files/scripts/cron-sites-nightly-backup.sh
# refresh pkglist/ so the 3am backup commits any package changes
55 2 * * * $HOME/Sites/dot-files/scripts/pkglist-refresh.sh
EOF
    crontab -l
}

do_orphans() {
    # Last, so it catches leftovers from every step above: build tools that
    # an AUR package or cargo pulled in and nothing needs any more. Anything
    # wanted for itself belongs in pkglist/, which installs it explicitly.
    local o
    o=$(pacman -Qdtq) || { echo "no orphans"; return 0; }
    echo "removing orphans: $(echo $o)"
    sudo pacman -Rns --noconfirm $o
}

do_system_files() {
    # hypr-launch, NVIDIA profile, Bluetooth fixes, headroom, rime-umount, VPN
    # DNS hook. Chroot-safe; anything needing D-Bus is deferred to first boot.
    "$SRC/install.sh" -y -s
}

# ---------------------------------------------------------------- main

rb_init chroot-user "$RB_LOG_DIR"
step critical stow_core "Stow zsh and hyprland" do_stow_core
step minor stow_rest "Stow the other dot-files packages" do_stow_rest
step minor ohmyzsh "oh-my-zsh and its plugins" do_ohmyzsh
step minor vim "Vundle and vim plugins" do_vim
step minor broot "broot's br launcher" do_broot
step minor rustup "rustup stable toolchain" do_rustup
step minor paru "Build paru-bin" do_paru
step minor aur "AUR packages from pkglist/aur.txt" do_aur
step minor system_files "install.sh -y -s (system-level files)" do_system_files
step minor cargo "cargo tools" do_cargo
step minor pnpm "pnpm LTS node" do_pnpm
step minor sdcv "sdcv dictionary" do_sdcv
step minor claude "Claude Code native install" do_claude
step minor pipx "trcli via pipx" do_pipx
step minor mime "Default apps (xdg-mime)" do_mime
step minor crontab "User crontab" do_crontab
step minor orphans "Remove orphaned build dependencies" do_orphans
rb_summary
