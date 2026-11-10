#!/bin/bash
# Helper steps for the LaunchPad task (tasks.d/launchpad.toml).
#
#   launchpad.sh emulator   boot the AVD in its own unit if no device is online
#   launchpad.sh install    wait for boot, install the APK, launch, focus the emulator
#   launchpad.sh logcat     follow the app's logcat (the task's run phase)

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

APP_ID="com.dti.launchpad"
ACTIVITY="$APP_ID/$APP_ID.app.MainActivity"
AVD="launchpad_api36"
APK="${PWD}/app/build/outputs/apk/debug/app-debug.apk"

device_online() {
  adb devices 2>/dev/null | awk 'NR>1 && $2=="device"{found=1} END{exit !found}'
}

# The emulator gets a unit of its own: anything started inside the build's
# unit is killed when the build finishes.
ensure_emulator() {
  device_online && { echo "device online"; return 0; }
  echo "no device online, booting emulator $AVD"
  systemctl --user reset-failed launchpad-emulator.service 2>/dev/null
  systemd-run --user --quiet --collect --unit=launchpad-emulator \
    --description="LaunchPad emulator $AVD" \
    --setenv=PATH="$PATH" --setenv=WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
    --setenv=XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" --setenv=DISPLAY="${DISPLAY:-}" \
    "$ANDROID_HOME/emulator/emulator" -avd "$AVD" -gpu auto -no-snapshot-save -no-boot-anim
}

wait_for_boot() {
  timeout 150 adb wait-for-device || return 1
  local i
  for i in $(seq 1 60); do
    [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && return 0
    sleep 2
  done
  return 1
}

# Pull both emulator windows onto the active workspace and focus the device.
focus_emulator() {
  command -v hyprctl >/dev/null 2>&1 || return 0
  local ws
  ws=$(hyprctl activeworkspace -j 2>/dev/null | sed -n 's/.*"id": *\([0-9-]*\).*/\1/p' | head -1)
  [ -z "$ws" ] && return 0
  dispatch() {
    [ "$(hyprctl dispatch $1 2>/dev/null)" = "ok" ] || hyprctl dispatch "$2" >/dev/null 2>&1
  }
  dispatch "movetoworkspacesilent $ws,title:Android Emulator - $AVD" \
    "hl.dsp.window.move({ workspace = $ws, window = \"title:Android Emulator - $AVD\", follow = false })"
  dispatch "movetoworkspacesilent $ws,title:^Emulator\$" \
    "hl.dsp.window.move({ workspace = $ws, window = \"title:^Emulator\$\", follow = false })"
  dispatch "focuswindow title:Android Emulator - $AVD" \
    "hl.dsp.focus({ window = \"title:Android Emulator - $AVD\" })"
}

case "${1:-}" in
  emulator)
    ensure_emulator
    ;;
  install)
    wait_for_boot || { echo "error: the emulator did not finish booting in time"; exit 1; }
    adb install -r "$APK" || exit 1
    # LaunchPad is a launcher: without Usage Access it opens on a Settings
    # screen on first run. Grant it up front so the app itself opens.
    adb shell appops set "$APP_ID" android:get_usage_stats allow || true
    adb shell am start -n "$ACTIVITY"
    focus_emulator
    ;;
  logcat)
    pid=""
    for _ in $(seq 1 30); do
      pid=$(adb shell pidof -s "$APP_ID" 2>/dev/null | tr -d '\r')
      [ -n "$pid" ] && break
      sleep 1
    done
    [ -z "$pid" ] && { echo "the app is not running"; exit 0; }
    echo "(logcat for pid $pid)"
    exec adb logcat --pid="$pid"
    ;;
  *)
    sed -n '2,7p' "$0"
    exit 2
    ;;
esac
