#!/usr/bin/env bash
# Sync Claude's local skills, global CLAUDE.md, and home memory index into T3
# Code's Antigravity provider customization roots so Gemini/Neon sessions share
# the same skills (waybill, broker, homelab, ...) and house rules as Claude Code.
#
# Skills are materialized with rsync -aL (not symlinked) because Antigravity's
# file-read sandbox resolves symlinks and rejects targets outside config/skills.
# Idempotent; safe to re-run after editing CLAUDE.md, memories, or skills, or
# after signing into Antigravity on a fresh install.
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
CLAUDE_SKILLS="$CLAUDE_DIR/skills"
CLAUDE_HOME_MEM="$CLAUDE_DIR/projects/-home-nate/memory/MEMORY.md"
AGY_BASE="$HOME/.t3/userdata/providers/antigravity"

# Ensure repo-backed Claude skill symlinks exist when their repos are present.
mkdir -p "$CLAUDE_SKILLS"
for pair in \
    "tasks:$HOME/Sites/tasks/skills/tasks" \
    "homelab:$HOME/Sites/tasks/skills/homelab" \
    "broker:$HOME/Sites/credential-broker/skills/broker" \
    "switchyard:$HOME/Sites/switchyard/skills/switchyard"
do
    name="${pair%%:*}"
    target="${pair#*:}"
    if [[ -d "$target" ]]; then
        ln -sfn "$target" "$CLAUDE_SKILLS/$name"
    fi
done

shopt -s nullglob
providers=("$AGY_BASE"/*)
if [[ ${#providers[@]} -eq 0 ]]; then
    echo "sync-agent-skills: no Antigravity provider under $AGY_BASE yet; sign in to Antigravity in T3 Code and re-run."
    exit 0
fi

for provider in "${providers[@]}"; do
    [[ -d "$provider" ]] || continue
    cfg="$provider/config"
    skills_dst="$cfg/skills"
    rules_dst="$cfg/rules"
    mkdir -p "$skills_dst" "$rules_dst"

    # Build a fresh staging list of skill names synced from ~/.claude/skills.
    declare -A wanted=()
    synced=0
    for skill_dir in "$CLAUDE_SKILLS"/*; do
        [[ -d "$skill_dir" ]] || continue
        skill_name="$(basename "$skill_dir")"
        [[ "$skill_name" == "synced" ]] && continue
        [[ -f "$skill_dir/SKILL.md" ]] || continue
        wanted["$skill_name"]=1
        # Replace any legacy symlink before syncing as a real directory.
        [[ -L "$skills_dst/$skill_name" ]] && rm -f "$skills_dst/$skill_name"
        mkdir -p "$skills_dst/$skill_name"
        rsync -aL --delete "$skill_dir/" "$skills_dst/$skill_name/"
        synced=$((synced + 1))
    done

    # Remove skills previously synced here that no longer exist in ~/.claude/skills.
    if [[ -f "$skills_dst/.synced-from-claude" ]]; then
        while IFS= read -r prev; do
            [[ -n "$prev" ]] || continue
            if [[ -z "${wanted[$prev]+x}" ]]; then
                rm -rf "${skills_dst:?}/$prev"
            fi
        done < "$skills_dst/.synced-from-claude"
    fi
    printf '%s\n' "${!wanted[@]}" | sort > "$skills_dst/.synced-from-claude"
    unset wanted

    # Always-on rule: Nate's global CLAUDE.md (kept under Antigravity's 24 KB rule cap).
    if [[ -f "$CLAUDE_DIR/CLAUDE.md" ]]; then
        {
            cat <<'HDR'
---
trigger: always_on
description: Nate's global CLAUDE.md conventions (git, lowprio, disk layout, broker, deploys)
---

HDR
            cat "$CLAUDE_DIR/CLAUDE.md"
        } > "$rules_dst/claude-global.md"
    fi

    # Always-on rule: Claude home memory index + per-repo memory discovery.
    {
        cat <<'HDR'
---
trigger: always_on
description: Bridge to Nate's Claude Code home and per-repo persistent memories
---

# Shared Claude memories

Nate uses Claude Code and Gemini/Antigravity interchangeably in T3 Code and expects consistent nomenclature and habits across models.

## Home memory index

HDR
        if [[ -f "$CLAUDE_HOME_MEM" ]]; then
            cat "$CLAUDE_HOME_MEM"
        else
            echo "(No home MEMORY.md found at $CLAUDE_HOME_MEM.)"
        fi
        cat <<'FTR'

## Per-repo Claude memories

Claude stores repo-scoped memories under `~/.claude/projects/<encoded-path>/memory/MEMORY.md`, where slashes and dots in the repo's absolute path are replaced with hyphens (for example, `/home/nate/Sites/dot-files` -> `-home-nate-Sites-dot-files`, `/home/nate/Sites/layover` -> `-home-nate-Sites-layover`).

- At the start of substantive work in a repo, check whether `~/.claude/projects/<encoded-path>/memory/MEMORY.md` exists and read relevant linked memory files (use a shell command if `view_file` is workspace-sandboxed).
- Use the synced `tasks` (`waybill`), `broker`, and `homelab` skills whenever tasks, secrets, or homelab infrastructure come up.
FTR
    } > "$rules_dst/claude-memories.md"

    echo "sync-agent-skills: synced $synced skills and 2 rules into $cfg"
done
