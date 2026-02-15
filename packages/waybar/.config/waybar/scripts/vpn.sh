#\!/usr/bin/env bash

CONFIG="$HOME/dt.ovpn"

disconnect_all() {
  openvpn3 sessions-list 2>/dev/null | grep 'Path:' | awk '{print $2}' | while read -r path; do
    openvpn3 session-manage --disconnect --path "$path" 2>/dev/null
  done
  openvpn3 session-manage --cleanup 2>/dev/null
}

case "$1" in
  toggle)
    if openvpn3 sessions-list 2>/dev/null | grep -q 'Path:'; then
      disconnect_all
    else
      disconnect_all
      openvpn3 session-start --config "$CONFIG"
    fi
    ;;
  list)
    ghostty --title=float-term -e zsh -c 'openvpn3 sessions-list; sleep 3'
    ;;
  *)
    if openvpn3 sessions-list 2>/dev/null | grep -q 'Path:'; then
      echo '{"text": "", "class": "connected"}'
    else
      echo '{"text": "", "class": "disconnected"}'
    fi
    ;;
esac
