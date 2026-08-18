#!/bin/bash
#
# Waybar build/launch button for the DT LaunchPad Android app (the "app agent"
# we iterate on). Lives in the games drawer next to the Godot build buttons and
# behaves the same way: click and the build runs headless in the background, the
# button itself is the status light. No terminal is spawned. On failure the
# button turns red, a critical notification fires, and the log is one right-click
# away. On success the APK is installed to the emulator (booting it first if none
# is running), the app is launched, and the emulator window is pulled onto the
# current Hyprland workspace and focused so it "just opens". App logcat is then
# appended to the same log, so right-click live-tails build + runtime output in
# ~/Downloads/launchpad-build.log.
#
# Actions:
#   status   emit waybar JSON for the button            (exec)
#   build    start (or restart) a build + launch        (left-click)
#   log      live-tail the build+app log in a term       (right-click)
#   _run     internal: the actual headless build, detached
#
# Kept intentionally parallel to game-build.sh (same state-file/flash pattern).

OK_FLASH=6  # seconds to keep the green check before reverting to idle

# --- toolchain (waybar runs us with a bare environment) ---------------------
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
# Pin JDK 21: the build targets 17 and AGP 8.13 does not support JDK 26, so we
# do not want to inherit whatever archlinux-java default happens to be set.
[ -d /usr/lib/jvm/java-21-openjdk ] && export JAVA_HOME=/usr/lib/jvm/java-21-openjdk

PROJECT_DIR="$HOME/Sites/LaunchPad"
APP_ID="com.dti.launchpad"
ACTIVITY="$APP_ID/$APP_ID.app.MainActivity"
AVD="launchpad_api36"
APK="$PROJECT_DIR/app/build/outputs/apk/debug/app-debug.apk"
LABEL="launchpad"

state_file() { echo "/tmp/launchpad-build.state"; }
log_file()   { echo "$HOME/Downloads/launchpad-build.log"; }
emu_log()    { echo "/tmp/launchpad-emulator.log"; }

# state file holds "state|epoch"; state is idle|building|failed|seen|ok
# ("seen" is written by game-build.sh drawer-toggled: failure acknowledged by a
# drawer click, button stays red until the next click. Same as the games.)
get_state() { local f; f="$(state_file)"; [ -f "$f" ] && cat "$f" || echo "idle|0"; }
set_state() { echo "$1|$(date +%s)" > "$(state_file)"; }

# resolve the live state, collapsing a stale "ok" flash back to idle
current_state() {
  local st ts
  IFS='|' read -r st ts <<< "$(get_state)"
  if [ "$st" = "ok" ] && [ $(( $(date +%s) - ts )) -ge "$OK_FLASH" ]; then
    st=idle
  fi
  echo "$st"
}

# --- emulator / device helpers ---------------------------------------------

# True if an emulator/device is online (adb "device" state, not "offline").
device_online() {
  adb devices 2>/dev/null | awk 'NR>1 && $2=="device"{found=1} END{exit !found}'
}

# Boot our AVD detached if nothing is online. Returns immediately; the caller
# overlaps the build with the ~30s cold boot and waits with wait_for_boot.
ensure_emulator() {
  device_online && return 0
  echo ">>> no device online, booting emulator $AVD" >> "$(log_file)"
  setsid -f "$ANDROID_HOME/emulator/emulator" -avd "$AVD" \
    -gpu auto -no-snapshot-save -no-boot-anim >> "$(emu_log)" 2>&1
}

# Block until a device is fully booted (sys.boot_completed=1), ~2min cap.
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
  # Try the legacy keyword form first, then the lua-config (Hyprland 0.55+) form
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

fail() {
  set_state failed
  local err
  err="$(grep -m1 -iE 'FAILURE:|error:|> Task .* FAILED|Installation failed' "$(log_file)")"
  [ -z "$err" ] && err="${1:-$(tail -n 3 "$(log_file)" | tr '\n' ' ')}"
  notify-send "launchpad build failed" "$err" -u critical -i dialog-error
  exit 1
}

case "${1:-}" in
  status)
    case "$(current_state)" in
      building)
        frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
        i=$(( $(date +%s) % ${#frames[@]} ))
        printf '{"text":"%s %s","class":"building","tooltip":"launchpad: building & installing…"}\n' "${frames[$i]}" "$LABEL"
        ;;
      failed|seen)
        printf '{"text":" %s","class":"failed","tooltip":"launchpad: BUILD FAILED - right-click to open the log"}\n' "$LABEL"
        ;;
      ok)
        printf '{"text":" %s","class":"ok","tooltip":"launchpad: built, installed & launched"}\n' "$LABEL"
        ;;
      *)
        printf '{"text":" %s","class":"idle","tooltip":"launchpad: click to build, install & launch on the emulator · right-click for last log"}\n' "$LABEL"
        ;;
    esac
    ;;

  build)
    if [ "$(current_state)" = "building" ]; then
      notify-send "launchpad" "Build already in progress" -i dialog-information
      exit 0
    fi
    set_state building
    setsid -f "$0" _run >/dev/null 2>&1
    ;;

  log)
    lf="$(log_file)"
    if [ ! -f "$lf" ]; then
      notify-send "launchpad" "No build log yet" -i dialog-information
      exit 0
    fi
    setsid -f kitty --class float-term -e tail -n +1 -f "$lf" >/dev/null 2>&1
    ;;

  _run)
    lf="$(log_file)"

    if [ ! -d "$PROJECT_DIR" ]; then
      set_state failed
      echo "Project dir not found: $PROJECT_DIR" > "$lf"
      notify-send "launchpad build failed" "Project dir not found: $PROJECT_DIR" -u critical -i dialog-error
      exit 1
    fi

    cd "$PROJECT_DIR" || exit 1
    {
      echo "===== launchpad build $(date '+%F %T') ====="
      echo "JAVA_HOME=${JAVA_HOME:-<default>}  ANDROID_HOME=$ANDROID_HOME"
    } > "$lf"

    # Start the emulator (if needed) so its ~30s cold boot overlaps the build.
    ensure_emulator

    # Build the APK (no device required for assembleDebug).
    if ! ./gradlew :app:assembleDebug >> "$lf" 2>&1; then
      fail
    fi

    # Now we do need a booted device to install onto.
    if ! wait_for_boot; then
      fail "emulator did not finish booting in time"
    fi

    if ! adb install -r "$APK" >> "$lf" 2>&1; then
      fail
    fi

    # LaunchPad is a launcher: without Usage Access it dumps you on a Settings
    # screen on first run. Grant it up front so the app itself actually opens.
    adb shell appops set "$APP_ID" android:get_usage_stats allow >> "$lf" 2>&1 || true

    adb shell am start -n "$ACTIVITY" >> "$lf" 2>&1
    set_state ok
    notify-send "launchpad" "Built & installed — launching" -i dialog-information
    focus_emulator

    # Append the live app session to the same log and notify on the first crash
    # (then throttle 15s), so right-click shows build output AND runtime errors.
    printf '\n===== app session %s =====\n' "$(date '+%F %T')" >> "$lf"
    setsid -f bash -c '
      app="$1"; lf="$2"; last=0; pid=""
      for i in $(seq 1 30); do
        pid=$(adb shell pidof -s "$app" 2>/dev/null | tr -d "\r")
        [ -n "$pid" ] && break; sleep 1
      done
      [ -z "$pid" ] && exit 0
      printf "(logcat for pid %s)\n" "$pid" >> "$lf"
      adb logcat --pid="$pid" 2>&1 | while IFS= read -r line; do
        printf "%s\n" "$line" >> "$lf"
        case "$line" in
          *"FATAL EXCEPTION"*|*"AndroidRuntime"*" E "*)
            now=$(date +%s)
            if [ $(( now - last )) -ge 15 ]; then
              last=$now
              notify-send "launchpad runtime error" "$line" -u critical -i dialog-error
            fi ;;
        esac
      done
    ' _ "$APP_ID" "$lf" >/dev/null 2>&1
    ;;

  *)
    echo "usage: launchpad-build.sh {status|build|log|_run}" >&2
    exit 1
    ;;
esac
