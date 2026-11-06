#!/usr/bin/env bash
# Phase 4: after the only reboot, as the user in a kitty terminal inside
# Hyprland (not inside T3 Code: the restore replaces T3's state).
#
#   bash ~/Sites/dot-files/rebuild/40-first-boot.sh
#
# Finishes what needs a running session (user services, D-Bus bits), then
# restores from the backup set in $RESTORE_DIR: secrets (YubiKey), ~/Sites,
# home files, Claude and T3 history, ~/.local and ~/.config state. Rerun after
# a critical stop; finished steps are skipped.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(dirname "$HERE")"
# shellcheck source=lib.sh
source "$HERE/lib.sh"
# shellcheck source=config.sh
source "$HERE/config.sh"

M="$RESTORE_DIR"
YK_ID="${XDG_RUNTIME_DIR:-/tmp}/yk-identity.txt"
trap 'rm -f "$YK_ID"' EXIT

yk_identity() {
    [[ -s "$YK_ID" ]] && return 0
    echo "Plug in the YubiKey; touch it each time it blinks."
    age-plugin-yubikey --identity > "$YK_ID"
}

# decrypt <archive> <dir> [tar args...]
decrypt_into() {
    local archive="$1" dir="$2"
    shift 2
    yk_identity
    (cd "$dir" && age -d -i "$YK_ID" "$archive" | tar -xf - "$@")
}

do_session() {
    [[ $EUID -ne 0 ]] || { echo "run as $RB_USER, not root"; return 1; }
    systemctl --user is-system-running &>/dev/null || systemctl --user status >/dev/null \
        || { echo "no user systemd manager; run this from a terminal inside Hyprland"; return 1; }
}

do_user_units() {
    systemctl --user daemon-reload
    command -v elephant >/dev/null && elephant service enable
    systemctl --user enable --now waybar.service
    systemctl --user enable headset-autoswitch.service
}

do_system_files() {
    # Picks up what the chroot deferred (openvpn3 DNS needs D-Bus).
    "$SRC/install.sh" -y -s
}

do_theme() {
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Nordic'
    gsettings set org.gnome.desktop.interface font-name 'PragmataPro 11'
    gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
}

do_snapshot_menu() {
    sudo limine-snapper-sync
}

# ---- restore

do_restore_ready() {
    [[ -d "$M" ]] || { echo "no backup set at $M (Rime not mounted?). Set RESTORE_DIR, or REBUILD_RESTORE=0 to skip the restore."; return 1; }
    if pgrep -f '[t]3code' >/dev/null; then
        echo "T3 Code is running. Quit it (the restore replaces its state) and run this from kitty."
        return 1
    fi
    yk_identity
}

do_secrets() {
    local f
    decrypt_into "$M/frostyarch-secrets.tar.age" "$HOME"
    for f in frostyarch-secrets-extra frostyarch-secrets-extra2; do
        if [[ -f "$M/$f.tar.age" ]]; then
            decrypt_into "$M/$f.tar.age" "$HOME" --exclude=.claude.json
        fi
    done
    chmod 700 "$HOME/.ssh" "$HOME/.gnupg"
    chmod 600 "$HOME/.ssh/id_ed25519" "$HOME/.git-credentials"
}

do_git_access() {
    # GitLab goes through `glab auth git-credential`, and a restored glab token
    # can sit in a GNOME keyring still locked with the old machine's password.
    local url
    url=$(awk -F'\t' '$1 == "repo" && $4 ~ /gitlab\.com/ { print $4; exit }' "$M/sites-manifest.tsv")
    git ls-remote -q https://github.com/NathanielInman/dotfiles.git HEAD >/dev/null
    if [[ -n "$url" ]] && ! GIT_TERMINAL_PROMPT=0 timeout 30 git ls-remote -q "$url" HEAD >/dev/null; then
        echo "GitLab access fails for $url."
        echo "Unlock the restored keyring in Seahorse (or blank its password), or run \`glab auth login\`, then rerun."
        return 1
    fi
}

do_sites() {
    bash "$M/restore-sites.sh" 2>&1 | tee "$RB_DIR/restore-sites.out"
    if grep -qE '^(FAIL|WARN)' "$RB_DIR/restore-sites.out"; then
        followup "restore-sites.sh reported problems: $(grep -cE '^(FAIL|WARN)' "$RB_DIR/restore-sites.out") FAIL/WARN lines in \`$RB_DIR/restore-sites.out\`. Missing branch commits can often be fetched from GitLab by SHA."
    fi
}

do_dev_vars() {
    decrypt_into "$M/repo-dev-vars.tar.age" "$HOME/Sites"
}

do_home_files() {
    local d
    for d in Videos Pictures Documents Downloads signet-589-discovery det-33-bucket-backup; do
        [[ -d "$M/home/$d" ]] && rsync -rt "$M/home/$d" "$HOME/"
    done
    [[ -d "$M/home/Sites-loose" ]] && rsync -rt "$M/home/Sites-loose/" "$HOME/Sites/"
    return 0
}

do_claude_t3() {
    (cd "$HOME" && zstd -dc "$M/home/claude-and-t3.tar.zst" | tar -xf -)
    mkdir -p "$HOME/.t3/userdata"
    zstd -dcf "$M/home/t3-statev2-snapshot.sqlite.zst" -o "$HOME/.t3/userdata/statev2.sqlite"
    zstd -dcf "$M/home/t3-state-snapshot.sqlite.zst" -o "$HOME/.t3/userdata/state.sqlite"
    ln -sfn "$HOME/Sites/tasks/skills/tasks" "$HOME/.claude/skills/tasks"
}

do_extra_home() {
    # ~/.local and ~/.config state, .zsh_history, .zshenv... The archive's
    # .claude.json is merged with the current one, so the sign-in survives.
    local cur="$RB_DIR/claude.json.current"
    [[ -s "$HOME/.claude.json" ]] && cp "$HOME/.claude.json" "$cur"
    yk_identity
    (cd "$HOME" && age -d -i "$YK_ID" "$M/home/frostyarch-extra-home.tar.zst.age" | zstd -dc | tar -xf -)
    if [[ -s "$cur" ]]; then
        # The backup's projects, MCP servers and settings; this machine's account fields.
        jq -s '.[0] * (.[1] | {oauthAccount, userID} | with_entries(select(.value != null)))' \
            "$HOME/.claude.json" "$cur" > "$HOME/.claude.json.new"
        mv "$HOME/.claude.json.new" "$HOME/.claude.json"
        rm -f "$cur"
    fi
    systemctl --user daemon-reload
}

do_broker() {
    command -v broker >/dev/null && return 0
    local p="$HOME/Sites/credential-broker/packaging/aur/credential-broker-bin"
    (cd "$p" && makepkg -si --noconfirm)
    broker ls >/dev/null
}

do_crontab_restore() {
    [[ -f "$M/crontab.txt" ]] || return 0
    crontab "$M/crontab.txt"
    crontab -l
}

# ---------------------------------------------------------------- main

rb_init first-boot "$RB_LOG_DIR"
step critical session "Running as $RB_USER inside the desktop session" do_session
step minor user_units "Enable waybar, elephant, headset-autoswitch" do_user_units
step minor system_files "install.sh -y -s (deferred bits)" do_system_files
step minor theme "GTK theme and dark mode" do_theme
step minor snapshot_menu "First limine-snapper-sync run" do_snapshot_menu

# REBUILD_RESTORE=0 for a machine with no backup set to restore.
if [[ "${REBUILD_RESTORE:-1}" == 1 ]]; then
    step critical restore_ready "Backup set present, T3 closed, YubiKey present" do_restore_ready
    step critical secrets "Decrypt the secrets archives" do_secrets
    step critical git_access "GitHub and GitLab reachable with the restored credentials" do_git_access
    step minor sites "Restore ~/Sites (restore-sites.sh)" do_sites
    step minor dev_vars "Restore .dev.vars files" do_dev_vars
    step minor home_files "Copy home folders" do_home_files
    step minor claude_t3 "Restore Claude and T3 history" do_claude_t3
    step minor extra_home "Restore ~/.local and ~/.config state" do_extra_home
    step minor broker "Build and check broker" do_broker
    step minor crontab_restore "Restore the old crontab" do_crontab_restore
fi

rb_summary
cat <<EOF

Next: open T3 Code (or restart claude) so it loads the restored history, then ask:
  "Work through $RB_FOLLOWUPS"
Sign in to Claude with \`claude auth login\` if it asks; in Hyprland that is a
browser click, no code to type.
EOF
