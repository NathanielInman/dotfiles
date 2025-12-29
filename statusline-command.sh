#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')

# ============================================
# Usage API with caching (30 second refresh)
# ============================================
USAGE_CACHE="$HOME/.claude/.usage_cache.json"
CACHE_MAX_AGE=30

get_usage_data() {
    local now=$(date +%s)
    local cache_time=0

    # Check cache age
    if [ -f "$USAGE_CACHE" ]; then
        cache_time=$(stat -c %Y "$USAGE_CACHE" 2>/dev/null || stat -f %m "$USAGE_CACHE" 2>/dev/null || echo 0)
    fi

    local age=$((now - cache_time))

    # Refresh cache if older than CACHE_MAX_AGE seconds
    if [ $age -gt $CACHE_MAX_AGE ] || [ ! -f "$USAGE_CACHE" ]; then
        local token=$(jq -r '.claudeAiOauth.accessToken // empty' "$HOME/.claude/.credentials.json" 2>/dev/null)
        if [ -n "$token" ]; then
            curl -s --max-time 2 \
                -H "Accept: application/json" \
                -H "Authorization: Bearer $token" \
                -H "anthropic-beta: oauth-2025-04-20" \
                "https://api.anthropic.com/api/oauth/usage" > "$USAGE_CACHE.tmp" 2>/dev/null

            # Only update cache if we got valid JSON
            if jq -e . "$USAGE_CACHE.tmp" >/dev/null 2>&1; then
                mv "$USAGE_CACHE.tmp" "$USAGE_CACHE"
            else
                rm -f "$USAGE_CACHE.tmp"
            fi
        fi
    fi

    cat "$USAGE_CACHE" 2>/dev/null || echo '{}'
}

# Shared function to format duration in seconds as #w#d#h#m, skipping zero values
format_duration() {
    local total_secs="$1"
    local show_weeks="${2:-false}"

    [ "$total_secs" -le 0 ] && echo "now" && return

    local weeks=$((total_secs / 604800))
    local days=$(((total_secs % 604800) / 86400))
    local hours=$(((total_secs % 86400) / 3600))
    local mins=$(((total_secs % 3600) / 60))

    local result=""
    [ "$show_weeks" = "true" ] && [ "$weeks" -gt 0 ] && result+="${weeks}w"
    [ "$days" -gt 0 ] && result+="${days}d"
    [ "$hours" -gt 0 ] && result+="${hours}h"
    [ "$mins" -gt 0 ] && result+="${mins}m"

    # Fallback if less than a minute
    [ -z "$result" ] && result="<1m"

    echo "$result"
}

format_time_remaining() {
    local reset_at="$1"
    local show_weeks="${2:-false}"
    [ -z "$reset_at" ] || [ "$reset_at" = "null" ] && return

    # Parse ISO timestamp and calculate remaining time
    local reset_epoch=$(date -d "$reset_at" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${reset_at%%.*}" +%s 2>/dev/null)
    [ -z "$reset_epoch" ] && return

    local now=$(date +%s)
    local remaining=$((reset_epoch - now))

    format_duration "$remaining" "$show_weeks"
}

# Change to the current working directory for git commands
cd "$cwd" 2>/dev/null || true

# Color codes (using ANSI-C quoting for proper escape interpretation)
COLOR_RESET=$'\033[0m'
COLOR_CYAN=$'\033[36m'
COLOR_GREEN=$'\033[32m'
COLOR_YELLOW=$'\033[33m'
COLOR_RED=$'\033[31m'
COLOR_MAGENTA=$'\033[35m'
COLOR_BLACK=$'\033[30m'

# Get usage data (cached) and build usage info
usage_data=$(get_usage_data)

# Session (5hr) usage
session_util=$(echo "$usage_data" | jq -r '.five_hour.utilization // empty')
session_reset=$(echo "$usage_data" | jq -r '.five_hour.resets_at // empty')

# Weekly (7 day) usage
weekly_util=$(echo "$usage_data" | jq -r '.seven_day.utilization // empty')
weekly_reset=$(echo "$usage_data" | jq -r '.seven_day.resets_at // empty')

usage_info=""

# Session usage
if [ -n "$session_util" ]; then
    time_left=$(format_time_remaining "$session_reset")

    if [ "${session_util%.*}" -lt 50 ]; then
        usage_color="$COLOR_GREEN"
    elif [ "${session_util%.*}" -lt 80 ]; then
        usage_color="$COLOR_YELLOW"
    else
        usage_color="$COLOR_RED"
    fi

    usage_info=" ${usage_color}󰄛 ${session_util%.*}%${COLOR_RESET}"
    [ -n "$time_left" ] && usage_info+=" (${time_left})"
fi

# Weekly usage
if [ -n "$weekly_util" ]; then
    weekly_time_left=$(format_time_remaining "$weekly_reset" true)

    if [ "${weekly_util%.*}" -lt 50 ]; then
        weekly_color="$COLOR_GREEN"
    elif [ "${weekly_util%.*}" -lt 80 ]; then
        weekly_color="$COLOR_YELLOW"
    else
        weekly_color="$COLOR_RED"
    fi

    usage_info+=" ${weekly_color}󰃭 ${weekly_util%.*}%${COLOR_RESET}"
    [ -n "$weekly_time_left" ] && usage_info+=" (${weekly_time_left})"
fi

# Git branch icon (U+E0A0)
BRANCH_ICON=$'\ue0a0'

# Project name from package.json
project_name=""
if [ -f "$cwd/package.json" ]; then
    project_name=$(jq -r '.name // empty' "$cwd/package.json" 2>/dev/null)
fi
# Fallback to directory name if no package.json
if [ -z "$project_name" ]; then
    project_name=$(basename "$cwd")
fi

# Git branch
git_branch=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        git_branch="$branch"
    fi
fi

# Context window usage
context_info=""
usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$usage" != "null" ]; then
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    size=$(echo "$input" | jq '.context_window.context_window_size')
    pct=$((current * 100 / size))

    # Color based on percentage
    if [ "$pct" -lt 50 ]; then
        ctx_color="$COLOR_GREEN"
    elif [ "$pct" -lt 75 ]; then
        ctx_color="$COLOR_YELLOW"
    else
        ctx_color="$COLOR_RED"
    fi

    context_info=" ${ctx_color}󰧞 ${pct}%${COLOR_RESET}"
fi

# Model info with icon
model_short=$(echo "$model" | sed 's/Claude //')
model_info=" ${COLOR_CYAN}󰧑 ${model_short}${COLOR_RESET}"

# Lines added/removed from cost data
loc_info=""
cost=$(echo "$input" | jq '.cost')
if [ "$cost" != "null" ]; then
    lines_added=$(echo "$cost" | jq '.total_lines_added // 0')
    lines_removed=$(echo "$cost" | jq '.total_lines_removed // 0')
    duration_ms=$(echo "$cost" | jq '.total_duration_ms // 0')

    # Format duration using shared function
    duration_sec=$((duration_ms / 1000))
    duration_formatted=$(format_duration "$duration_sec" true)

    loc_info=" ${COLOR_GREEN}+${lines_added}${COLOR_RESET} ${COLOR_RED}-${lines_removed}${COLOR_RESET} 󱎫 ${duration_formatted}"
fi

# Timestamp
timestamp=$(date '+%Y-%m-%d@%T')

# Build the status line
if [ -n "$git_branch" ]; then
    printf "${COLOR_MAGENTA}%s${COLOR_RESET} on ${COLOR_CYAN}%s %s${COLOR_RESET} with%s%s%s%s ${COLOR_BLACK}%s${COLOR_RESET}" \
        "$project_name" \
        "$BRANCH_ICON" \
        "$git_branch" \
        "$model_info" \
        "$context_info" \
        "$usage_info" \
        "$loc_info" \
        "$timestamp"
else
    printf "${COLOR_MAGENTA}%s${COLOR_RESET} with%s%s%s%s ${COLOR_BLACK}%s${COLOR_RESET}" \
        "$project_name" \
        "$model_info" \
        "$context_info" \
        "$usage_info" \
        "$loc_info" \
        "$timestamp"
fi
