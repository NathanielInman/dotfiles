#!/bin/bash
#
# Waybar game build/launch buttons for det33, gym, eversparkforge.
#
# Click a button and the build runs headless in the background; the button
# itself becomes the status light. No terminal is spawned. If the build
# fails the button turns red, a critical notification fires, and the last
# build log is one right-click away. On success Godot launches in its own
# window. Output is always saved to /tmp/game-build-<game>.log.
#
# Actions:
#   status <game>   emit waybar JSON for one game button   (exec)
#   build  <game>   start (or restart) a build + launch     (left-click)
#   log    <game>   open the last build log in a float term  (right-click)
#   _run   <game>   internal: the actual headless build, detached

OK_FLASH=6  # seconds to keep the green check before reverting to idle

game_dir() {
  case "$1" in
    det33|gym)      echo "$HOME/Rime/det33-godot" ;;
    eversparkforge) echo "$HOME/Sites/everspark-forge-godot" ;;
  esac
}

game_scene() {
  case "$1" in
    det33)          echo "res://Scenes/Main/Boot.tscn" ;;
    gym)            echo "res://Scenes/Test/AbilityTest.tscn" ;;
    eversparkforge) echo "res://Scenes/Main/Boot.tscn" ;;
  esac
}

game_label() {
  case "$1" in
    det33)          echo "det33" ;;
    gym)            echo "gym" ;;
    eversparkforge) echo "forge" ;;
  esac
}

state_file() { echo "/tmp/game-build-$1.state"; }
log_file()   { echo "/tmp/game-build-$1.log"; }

# state file holds "state|epoch"; state is idle|building|failed|ok
get_state() {
  local f; f="$(state_file "$1")"
  [ -f "$f" ] && cat "$f" || echo "idle|0"
}
set_state() { echo "$2|$(date +%s)" > "$(state_file "$1")"; }

# resolve the live state, collapsing a stale "ok" flash back to idle
current_state() {
  local st ts
  IFS='|' read -r st ts <<< "$(get_state "$1")"
  if [ "$st" = "ok" ] && [ $(( $(date +%s) - ts )) -ge "$OK_FLASH" ]; then
    st=idle
  fi
  echo "$st"
}

case "${1:-}" in
  status)
    game="$2"
    label="$(game_label "$game")"
    case "$(current_state "$game")" in
      building)
        frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
        i=$(( $(date +%s) % ${#frames[@]} ))
        printf '{"text":"%s %s","class":"building","tooltip":"%s: building…"}\n' "${frames[$i]}" "$label" "$game"
        ;;
      failed)
        printf '{"text":" %s","class":"failed","tooltip":"%s: BUILD FAILED — right-click to open the log"}\n' "$label" "$game"
        ;;
      ok)
        printf '{"text":" %s","class":"ok","tooltip":"%s: built & launched"}\n' "$label" "$game"
        ;;
      *)
        printf '{"text":" %s","class":"idle","tooltip":"%s: click to build & launch · right-click for last log"}\n' "$label" "$game"
        ;;
    esac
    ;;

  build)
    game="$2"
    st="$(current_state "$game")"
    if [ "$st" = "building" ]; then
      notify-send "$game" "Build already in progress" -i dialog-information
      exit 0
    fi
    set_state "$game" building
    setsid -f "$0" _run "$game" >/dev/null 2>&1
    ;;

  log)
    game="$2"
    lf="$(log_file "$game")"
    if [ ! -f "$lf" ]; then
      notify-send "$game" "No build log yet" -i dialog-information
      exit 0
    fi
    setsid -f kitty --class float-term --hold -e bat --style=plain --paging=never "$lf" >/dev/null 2>&1
    ;;

  _run)
    game="$2"
    dir="$(game_dir "$game")"
    scene="$(game_scene "$game")"
    lf="$(log_file "$game")"

    if [ ! -d "$dir" ]; then
      set_state "$game" failed
      echo "Project dir not found: $dir" > "$lf"
      notify-send "$game build failed" "Project dir not found: $dir" -u critical -i dialog-error
      exit 1
    fi

    cd "$dir" || exit 1
    if { dotnet build && godot-mono --headless --import; } > "$lf" 2>&1; then
      set_state "$game" ok
      notify-send "$game" "Build OK — launching" -i dialog-information
      setsid -f godot-mono --path "$dir" "$scene" >/dev/null 2>&1
    else
      set_state "$game" failed
      err="$(grep -m1 -E ': error|error CS|: error|Error:' "$lf")"
      [ -z "$err" ] && err="$(tail -n 3 "$lf" | tr '\n' ' ')"
      notify-send "$game build failed" "$err" -u critical -i dialog-error
    fi
    ;;

  *)
    echo "usage: game-build.sh {status|drawer-status|build|log|_run} [game]" >&2
    exit 1
    ;;
esac
