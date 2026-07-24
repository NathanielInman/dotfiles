#!/bin/bash
#
# Waybar game build/launch buttons for det33, gym, compass, eversparkforge.
#
# Click a button and the build runs headless in the background; the button
# itself becomes the status light. No terminal is spawned. If the build
# fails the button turns red, a critical notification fires, and the log is
# one right-click away. On success Godot launches in its own window and its
# runtime output (errors, exceptions, print()) is appended to the same log,
# so right-click live-tails build + gameplay output in /tmp/game-build-<game>.log.
#
# Actions:
#   status <game>   emit waybar JSON for one game button     (exec)
#   build  <game>   start (or restart) a build + launch       (left-click)
#   log    <game>   live-tail the build+game log in a term     (right-click)
#   _run   <game>   internal: the actual headless build, detached

OK_FLASH=6  # seconds to keep the green check before reverting to idle

game_dir() {
  case "$1" in
    det33|gym|compass) echo "$HOME/Rime/det33-godot" ;;
    eversparkforge)    echo "$HOME/Sites/everspark-forge-godot" ;;
  esac
}

game_scene() {
  case "$1" in
    det33)          echo "res://Scenes/Main/Boot.tscn" ;;
    gym)            echo "res://Scenes/Test/Workbench.tscn" ;;
    compass)        echo "res://Scenes/Test/CompassTest.tscn" ;;
    eversparkforge) echo "res://Scenes/Main/Boot.tscn" ;;
  esac
}

game_label() {
  case "$1" in
    det33)          echo "det33" ;;
    gym)            echo "gym" ;;
    compass)        echo "compass" ;;
    eversparkforge) echo "forge" ;;
  esac
}

state_file() { echo "/tmp/game-build-$1.state"; }
# Log lives in ~/Downloads so it is easy to open or point another tool at.
log_file()   { echo "$HOME/Downloads/game-$1.log"; }

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

  # Aggregate state across all games for the drawer toggle button, so builds
  # stay visible after click-to-reveal collapses the drawer on click.
  drawer-status)
    building=(); failed=(); okg=()
    for g in det33 gym compass eversparkforge; do
      case "$(current_state "$g")" in
        building) building+=("$g") ;;
        failed)   failed+=("$g") ;;
        ok)       okg+=("$g") ;;
      esac
    done
    icon="󰐱"
    if [ ${#building[@]} -gt 0 ]; then
      frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
      i=$(( $(date +%s) % ${#frames[@]} ))
      printf '{"text":"%s %s","class":"building","tooltip":"building: %s"}\n' "${frames[$i]}" "$icon" "${building[*]}"
    elif [ ${#failed[@]} -gt 0 ]; then
      printf '{"text":" %s","class":"failed","tooltip":"BUILD FAILED: %s — open drawer, right-click the game for its log"}\n' "$icon" "${failed[*]}"
    elif [ ${#okg[@]} -gt 0 ]; then
      printf '{"text":" %s","class":"ok","tooltip":"built & launched: %s"}\n' "$icon" "${okg[*]}"
    else
      printf '{"text":"%s","class":"idle","tooltip":"Games & shortcuts"}\n' "$icon"
    fi
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
    # Live-follow so it works both for build errors and while the game is
    # running: existing output first, then new lines stream in as you play.
    setsid -f kitty --class float-term -e tail -n +1 -f "$lf" >/dev/null 2>&1
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
      # Append the live game session to the same log so right-click shows
      # build output AND any runtime errors/print() from actual play. A
      # detached watcher also notifies on the first genuine runtime error
      # (then throttles 15s) so you do not have to keep the log open.
      printf '\n===== game session %s =====\n' "$(date '+%F %T')" >> "$lf"
      setsid -f bash -c '
        dir="$1"; scene="$2"; lf="$3"; game="$4"; last=0
        godot-mono --path "$dir" "$scene" 2>&1 | while IFS= read -r line; do
          printf "%s\n" "$line" >> "$lf"
          # Godot prints engine + C# exceptions as a line starting with
          # "ERROR:"/"SCRIPT ERROR:" (C# shows e.g. "ERROR: System.Foo...").
          # Anchor to line start so indented stack-trace frames do not match.
          case "$line" in
            "ERROR:"*|"USER ERROR:"*|"SCRIPT ERROR:"*|"USER SCRIPT ERROR:"*|"Unhandled exception"*|"Unhandled Exception"*)
              now=$(date +%s)
              if [ $(( now - last )) -ge 15 ]; then
                last=$now
                notify-send "$game runtime error" "$line" -u critical -i dialog-error
              fi ;;
          esac
        done
      ' _ "$dir" "$scene" "$lf" "$game" >/dev/null 2>&1
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
