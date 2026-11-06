#!/usr/bin/env bash
# Run first, as root on the Arch live ISO. Gets the tools the rebuild needs,
# mounts Rime, and starts Claude Code without typing a login code:
#
#   curl -fsSL https://raw.githubusercontent.com/NathanielInman/dotfiles/master/rebuild/bootstrap.sh -o bootstrap.sh
#   bash bootstrap.sh
#
# Asks for two things: the Rime SMB password (once; the installed system reuses
# it) and a YubiKey touch to decrypt the stored Claude token. Then it prints
# what to run next. Safe to rerun.
set -uo pipefail

RED=$'\033[0;31m'; YEL=$'\033[0;33m'; GRN=$'\033[0;32m'; OFF=$'\033[0m'
die()  { printf '%sCRITICAL: %s%s\n' "$RED" "$*" "$OFF"; exit 1; }
warn() { printf '%sminor: %s%s\n' "$YEL" "$*" "$OFF"; }
ok()   { printf '%s%s%s\n' "$GRN" "$*" "$OFF"; }

[[ $EUID -eq 0 ]] || die "run as root on the live ISO"
[[ -d /sys/firmware/efi/efivars ]] || die "not booted in UEFI mode; Limine setup needs UEFI. Reboot the USB in UEFI mode."
ping -c1 -W3 archlinux.org &>/dev/null || die "no internet. Wired should DHCP on its own (check: ip -br a). Wi-Fi: iwctl, then station <dev> connect <SSID>."

setfont ter-v24n 2>/dev/null || true

# multilib on the ISO too: pacstrap resolves packages against the host config.
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
fi
sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf

pacman -Sy --noconfirm --needed archlinux-keyring || die "pacman keyring refresh failed"
pacman -S --noconfirm --needed git nodejs npm age age-plugin-yubikey pcsclite ccid \
    cifs-utils tmux qrencode terminus-font jq || die "installing live tools failed"
systemctl start pcscd.socket

SRC=/root/dot-files
if [[ -d $SRC/.git ]]; then
    git -C "$SRC" pull --ff-only -q || warn "could not update $SRC; using what is there"
else
    git clone -q https://github.com/NathanielInman/dotfiles.git "$SRC" || die "cloning dot-files failed"
fi
# shellcheck source=config.sh
source "$SRC/rebuild/config.sh"

# Rime: the stored Claude token, the backup set, and a place to keep logs.
CREDS=/root/rime-credentials
mkdir -p "$RIME_LIVE_MNT"
if ! mountpoint -q "$RIME_LIVE_MNT"; then
    for attempt in 1 2 3; do
        if [[ ! -s $CREDS ]]; then
            read -rsp "Rime SMB password for $RIME_USER: " pw; echo
            printf 'username=%s\npassword=%s\n' "$RIME_USER" "$pw" > "$CREDS"
            chmod 600 "$CREDS"
            unset pw
        fi
        if mount -t cifs "$RIME_SHARE" "$RIME_LIVE_MNT" -o "credentials=$CREDS,uid=0,gid=0,iocharset=utf8"; then
            break
        fi
        rm -f "$CREDS"
        warn "mount failed (attempt $attempt)"
    done
fi
if mountpoint -q "$RIME_LIVE_MNT"; then
    ok "Rime mounted at $RIME_LIVE_MNT"
    mkdir -p "$RIME_LIVE_MNT/$RIME_REBUILD_DIR/logs"
else
    warn "Rime is not mounted: no stored Claude token, no log copies. The install itself does not need it."
fi

npm install -g --silent @anthropic-ai/claude-code || die "installing Claude Code failed"

# The token comes from `claude setup-token` (one year), saved by
# rebuild/save-claude-token.sh on a working machine.
TOKEN_AGE="$RIME_LIVE_MNT/$RIME_REBUILD_DIR/claude-oauth-token.age"
TOKEN=/root/.claude-oauth-token
if [[ ! -s $TOKEN && -f $TOKEN_AGE ]]; then
    echo "Plug in the YubiKey, then touch it when it blinks."
    if age-plugin-yubikey --identity > /root/yk-identity.txt 2>/dev/null \
        && age -d -i /root/yk-identity.txt -o "$TOKEN" "$TOKEN_AGE"; then
        chmod 600 "$TOKEN"
    else
        rm -f "$TOKEN"
        warn "could not decrypt the Claude token (YubiKey missing or not touched). Rerun this script to try again."
    fi
    rm -f /root/yk-identity.txt
fi

cat > /usr/local/bin/claude-rebuild <<'EOF'
#!/usr/bin/env bash
# Claude Code for the rebuild: uses the stored token when there is one.
if [[ -s /root/.claude-oauth-token ]]; then
    CLAUDE_CODE_OAUTH_TOKEN=$(cat /root/.claude-oauth-token)
    export CLAUDE_CODE_OAUTH_TOKEN
fi
cd /root/dot-files && exec claude "$@"
EOF
chmod 755 /usr/local/bin/claude-rebuild

# Fallback login on a console with no browser: show the login URL as a QR code.
cat > /usr/local/bin/claude-login-qr <<'EOF'
#!/usr/bin/env bash
# Run in a second tmux pane while `claude` shows its login URL in pane 0.
tmux capture-pane -p -t :0 | tr -d ' \n' | grep -o 'https://claude\.com/cai/oauth.*Paste' | sed 's/Paste$//' | qrencode -t ansi
EOF
chmod 755 /usr/local/bin/claude-login-qr

echo
ok "Bootstrap done."
if [[ -s $TOKEN ]]; then
    echo "Claude is signed in through the stored token."
else
    echo "No stored token: claude-rebuild will ask you to log in. Run it in tmux and"
    echo "use claude-login-qr in a second pane to scan the login URL."
fi
cat <<EOF

Next:
  tmux new -s rebuild
  bash /root/dot-files/rebuild/10-live.sh      # asks for a password and a wipe confirmation, then runs unattended
  # second pane (Ctrl-b %):
  claude-rebuild                               # say: "Watch the rebuild; read rebuild/README.md"

Disks it will use (override with OS_DISK=... SCRATCH_DISK=... DATA_DISK=...):
  OS      $OS_DISK  (wiped)
  scratch $SCRATCH_DISK  (WIPE_SCRATCH=$WIPE_SCRATCH)
  data    $DATA_DISK  (WIPE_DATA=$WIPE_DATA)
EOF
