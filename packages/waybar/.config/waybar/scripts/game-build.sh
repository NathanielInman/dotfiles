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
    det33|gym|compass|benchmark) echo "$HOME/Rime/det33-godot" ;;
    eversparkforge)              echo "$HOME/Sites/everspark-forge-godot" ;;
  esac
}

game_scene() {
  case "$1" in
    det33)          echo "res://Scenes/Main/Boot.tscn" ;;
    gym)            echo "res://Scenes/Test/Workbench.tscn" ;;
    compass)        echo "res://Scenes/Test/CompassTest.tscn" ;;
    eversparkforge) echo "res://Scenes/Main/Boot.tscn" ;;
    benchmark)      echo "" ;;  # not a scene launch — see the _run branch
  esac
}

game_label() {
  case "$1" in
    det33)          echo "det33" ;;
    gym)            echo "gym" ;;
    compass)        echo "compass" ;;
    eversparkforge) echo "forge" ;;
    benchmark)      echo "bench" ;;
  esac
}

state_file() { echo "/tmp/game-build-$1.state"; }
# Log lives in ~/Downloads so it is easy to open or point another tool at.
log_file()   { echo "$HOME/Downloads/game-$1.log"; }
# Same reasoning for HitchWatch reports: analyze-hitch.py wants a path you can
# paste, not one buried in app_userdata.
hitch_dir()  { echo "$HOME/Downloads/hitches-$1"; }

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
        # &amp;, not & — the tooltip is parsed as Pango markup, and a bare
        # ampersand makes every poll log "Entity did not end with a semicolon".
        printf '{"text":" %s","class":"idle","tooltip":"%s: click to build &amp; launch · right-click for last log"}\n' "$label" "$game"
        ;;
    esac
    ;;

  # Aggregate state across all games for the drawer toggle button, so builds
  # stay visible after click-to-reveal collapses the drawer on click.
  drawer-status)
    building=(); failed=(); okg=()
    for g in det33 gym compass eversparkforge benchmark; do
      case "$(current_state "$g")" in
        building) building+=("$g") ;;
        failed)   failed+=("$g") ;;
        ok)       okg+=("$g") ;;
      esac
    done
    # The LaunchPad Android build lives in launchpad-build.sh but shares the
    # same "state|epoch" file format, so fold it into the collapsed-drawer light.
    if [ -f /tmp/launchpad-build.state ]; then
      IFS='|' read -r lst lts < /tmp/launchpad-build.state
      if [ "$lst" = "ok" ] && [ $(( $(date +%s) - lts )) -ge "$OK_FLASH" ]; then lst=idle; fi
      case "$lst" in
        building) building+=("launchpad") ;;
        failed)   failed+=("launchpad") ;;
        ok)       okg+=("launchpad") ;;
      esac
    fi
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
    # setsid escapes the controlling terminal but NOT waybar.service's cgroup,
    # and waybar runs with the default KillMode=control-group. So a waybar
    # restart (config edit, Hyprland reload, its own Restart=on-failure) SIGTERMs
    # the running game along with the bar. Godot exits silently on SIGTERM, so it
    # looks exactly like a game crash: window gone, no log line, no coredump.
    # Wrapping here rather than around the godot call puts the whole chain -
    # dotnet build, --headless --import, run-local.sh mirror, benchmark gate,
    # notify-send, the error watcher - in a transient unit with its own cgroup.
    # No --unit name, so systemd auto-names it and relaunches never collide.
    systemd-run --user --quiet --collect \
      --description="game-build $game" \
      --setenv=PATH="$PATH" \
      --setenv=WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
      --setenv=XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
      --setenv=DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
      --setenv=XDG_CURRENT_DESKTOP="$XDG_CURRENT_DESKTOP" \
      "$0" _run "$game" >/dev/null 2>&1
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

    # ---- benchmark: a quality gate, not a play session -------------------
    #
    # Runs the seeded high-load scenario (tools/load-bench.sh) and judges the
    # result against the committed baseline. The button light IS the verdict:
    # green = performance held, red = it regressed or could not be judged.
    #
    # This exists because a solo dev has no other check that stops an accidental
    # performance regression reaching players. It takes the screen for ~3
    # minutes and quits itself, so press it when stepping away.
    #
    # Deliberately thin: every parameter and threshold lives in the repo, under
    # version control, so a commit can explain any change to what "PASS" means.
    # This script only decides WHEN to run it.
    if [ "$game" = "benchmark" ]; then
      : > "$lf"
      printf '===== benchmark %s =====\n' "$(date '+%F %T')" >> "$lf"
      if ! bash tools/load-bench.sh clean >> "$lf" 2>&1; then
        set_state "$game" failed
        err="$(grep -m1 -E ': error|error CS|Error:' "$lf" || tail -n 3 "$lf" | tr '\n' ' ')"
        notify-send "benchmark failed to run" "$err" -u critical -i dialog-error
        exit 1
      fi

      csv="$(find profiles -name 'loadbench-*.csv' -newermt '-30 minutes' 2>/dev/null \
             | sort | tail -1)"
      if [ -z "$csv" ]; then
        set_state "$game" failed
        notify-send "benchmark produced no CSV" \
          "The run did not reach gameplay — right-click for the log." \
          -u critical -i dialog-error
        exit 1
      fi

      verdict="$(python3 tools/analyze-loadbench.py --gate "$csv" 2>&1)"
      rc=$?
      printf '\n%s\n' "$verdict" >> "$lf"
      head="$(printf '%s' "$verdict" | head -1)"
      body="$(printf '%s' "$verdict" | sed -n '2,6p')"

      # exit 2 (no baseline / scenario mismatch) is NOT a pass. A gate that
      # cannot judge must never show green, or it silently stops gating.
      if [ "$rc" -eq 0 ]; then
        set_state "$game" ok
        notify-send "benchmark PASS" "$body" -i dialog-information
      else
        set_state "$game" failed
        notify-send "benchmark $head" "$body" -u critical -i dialog-error
      fi
      exit 0
    fi

    if { dotnet build && godot-mono --headless --import; } > "$lf" 2>&1; then
      # det33 plays from a local-disk mirror rather than the CIFS repo: paging
      # the game over SMB mid-session caused ~130ms off-CPU frame stalls (see
      # docs/perf-status.md, 2026-08-14). tools/run-local.sh prints the mirror
      # dir; a mirror failure is a build failure, never a silent CIFS fallback.
      # gym/compass stay on the repo because Workbench authoring writes to res://.
      rundir="$dir"
      if [ "$game" = "det33" ]; then
        if ! rundir="$(bash tools/run-local.sh mirror 2>>"$lf")"; then
          set_state "$game" failed
          notify-send "$game build failed" "local mirror failed — right-click for the log" -u critical -i dialog-error
          exit 1
        fi
      fi
      set_state "$game" ok
      notify-send "$game" "Build OK — launching" -i dialog-information
      # Append the live game session to the same log so right-click shows
      # build output AND any runtime errors/print() from actual play. A
      # detached watcher also notifies on the first genuine runtime error
      # (then throttles 15s) so you do not have to keep the log open.
      printf '\n===== game session %s =====\n' "$(date '+%F %T')" >> "$lf"

      # HitchWatch (det33 only): point reports at ~/Downloads so a dump is
      # easy to find, but do NOT arm auto-trip or abort - this button is a
      # normal play session. Hitch hunting is a runtime choice now: Shift+F4
      # in-game toggles "hunt mode" (auto-trip at 24ms + quit after 3 dumps,
      # freezing the repro), and F4 still dumps the last 4s manually any time.
      # Sampling is always on in a debug build - which this is, since we run
      # the project directly rather than an exported template.
      if [ "$game" = "det33" ]; then
        hd="$(hitch_dir "$game")"
        mkdir -p "$hd"
        export DET33_HITCH_DIR="$hd"
      fi

      setsid -f bash -c '
        dir="$1"; scene="$2"; lf="$3"; game="$4"; last=0; lasth=0
        printf "===== running from %s =====\n" "$dir" >> "$lf"
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
            # Hunt-mode toggle acknowledgment (Shift+F4): immediate desktop
            # feedback without opening the log. Not throttled, it only prints
            # on a deliberate keypress.
            "[hitch] hunt"*)
              notify-send "$game" "${line#\[hitch\] }" -u low -i dialog-information ;;
            # HitchWatch trip header, e.g. "[hitch] ===== frame 31.2ms over 24ms
            # threshold =====". Notified on its own throttle so a hitch cannot
            # swallow a runtime-error notification or vice versa. Low urgency:
            # this is information to come back to, not something to interrupt
            # play for - the report is already on disk by the time you read it.
            "[hitch] ====="*)
              now=$(date +%s)
              if [ $(( now - lasth )) -ge 15 ]; then
                lasth=$now
                notify-send "$game frame hitch" "${line#\[hitch\] }
report in ~/Downloads/hitches-$game (read it with tools/analyze-hitch.py)" \
                  -u low -i dialog-information
              fi ;;
          esac
        done
      ' _ "$rundir" "$scene" "$lf" "$game" >/dev/null 2>&1
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
