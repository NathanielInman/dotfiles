#!/usr/bin/env zsh

if [[ "$USER" == "root" ]]; then USERCOLOR="red"; else USERCOLOR="blue"; fi

local W="%{$fg_bold[white]%}"
local R="%{$fg_bold[red]%}"
local r="%{$reset_color%}"
local B="%{$fg[blue]%}"
local b="%{$FG[008]%}"
local Y="%{$fg_bold[yellow]%}"
local y="%{$fg[yellow]%}"
local G="%{$fg_bold[green]%}"
local g="%{$fg_no_bold[green]%}"
local C="%{$fg_bold[cyan]%}"
local M="%{$fg_bold[magenta]%}"
local U="%{$fg_bold[$USERCOLOR]%}"

# Git sometimes goes into a detached head state. git_prompt_info doesn't
# return anything in this case. So wrap it in another function and check
# for an empty string.
function check_git_prompt_info() {
  if git rev-parse --git-dir > /dev/null 2> /dev/null; then
    if [[ -z $(_omz_git_prompt_info) ]]; then
      echo "${B}detached-head${r}) $(_omz_git_prompt_status)
${y}╰ "
    else
      echo "$(_omz_git_prompt_info) $(_omz_git_prompt_status)
%(?,${G}╰,${R}╰) "
    fi
  else
    echo "${C}➡  "
  fi
}

function check_git_prompt_lambda() {
  if git rev-parse --git-dir > /dev/null 2> /dev/null; then
    echo "%(?,${G}╭,${R}╭)"
  else
    echo "%(?,${G},${R})"
  fi
}

function get_right_prompt() {
  local date_str="${B}%D{%Y/%m/%d}"
  local time_str="${B}%D{%H:%M}"
  local datetime_str="${date_str}${b}@${time_str}"
  local full_str="${b}[${datetime_str}${b}]${r}"
  if git rev-parse --git-dir > /dev/null 2> /dev/null; then
    echo -n "$(git_prompt_short_sha)${full_str}"
  else
    echo -n $full_str
  fi
}

function timer_current_time() {
  perl -MTime::HiRes=time -e'print time'
}

function timer_format_duration() {
  local mins=$(printf '%.0f' $(($1 / 60)))
  local secs=$(printf "%.${TIMER_PRECISION:-1}f" $(($1 - 60 * mins)))
  local duration_str=$(echo "${mins}m${secs}s")
  local format="\x1b[1;90m⬅ took \x1b[3;90m${TIMER_FORMAT:-%d}"
  echo "
${format//\%d/${duration_str#0m}}"
}

function timer_save_time_preexec() {
  __timer_cmd_start_time=$(timer_current_time)
}

function timer_display_timer_precmd() {
  if [ -n "${__timer_cmd_start_time}" ]; then
    local cmd_end_time=$(timer_current_time)
    local tdiff=$((cmd_end_time - __timer_cmd_start_time))
    unset __timer_cmd_start_time
    local tdiffstr=$(timer_format_duration ${tdiff})
    local cols=$((COLUMNS - ${#tdiffstr} - 1))
    echo -e "\033[1A\033[${cols}C ${tdiffstr}"
  fi
}

preexec_functions+=(timer_save_time_preexec)
precmd_functions+=(timer_display_timer_precmd)

PROMPT='$(check_git_prompt_lambda) ${U}%n ${g}[%3~] $(check_git_prompt_info)${r}'
RPROMPT='$(get_right_prompt)'

# Format for git_prompt_info()
ZSH_THEME_GIT_PROMPT_PREFIX="${B}"
ZSH_THEME_GIT_PROMPT_SUFFIX="${r}"
ZSH_THEME_GIT_PROMPT_DIRTY=" ${Y}"
ZSH_THEME_GIT_PROMPT_CLEAN=" ${G}"

# Format for git_prompt_status()
ZSH_THEME_GIT_PROMPT_ADDED="${G} "
ZSH_THEME_GIT_PROMPT_MODIFIED="${C} "
ZSH_THEME_GIT_PROMPT_DELETED="${R} "
ZSH_THEME_GIT_PROMPT_RENAMED="${Y} "
ZSH_THEME_GIT_PROMPT_UNMERGED="${y} "
ZSH_THEME_GIT_PROMPT_UNTRACKED="${M} "

# Format for git_prompt_ahead()
ZSH_THEME_GIT_PROMPT_AHEAD="${W} "
ZSH_THEME_GIT_PROMPT_BEHIND="${W} "

# Format for git_prompt_long_sha() and git_prompt_short_sha()
ZSH_THEME_GIT_PROMPT_SHA_BEFORE=" ${b}[${B}"
ZSH_THEME_GIT_PROMPT_SHA_AFTER="${b}]"
