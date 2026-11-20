#!/usr/bin/env bash
# flux-gate: generic quality-gate hook driven by flux-config.yml
#
# Usage: flux-gate.sh <edit|push|stop|ci>
#   edit  → gates.on_edit   (PostToolUse on Edit|Write)
#   push  → gates.on_push   (PreToolUse on Bash, only for `git push`)
#   stop  → gates.on_stop   (Stop)
#   ci    → gates.on_push   (direct call from CI, no stdin)
#
# A gate command may contain the {file} placeholder: on the edit event it
# is replaced by the edited file (tool_input.file_path, shell-quoted), so
# the gate checks only that file. When no file is known (push, ci, stop),
# a command containing {file} is skipped.
#
# Exit 0: everything green (or nothing to do). Exit 2: at least one gate
# failed; Claude Code blocks the action and receives the report on stderr.
# Dependency: yq v4 (mikefarah).

set -uo pipefail

event="${1:?usage: flux-gate.sh <edit|push|stop|ci>}"
root="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$root" || exit 0
config="flux-config.yml"
[ -f "$config" ] || exit 0
command -v yq >/dev/null || { echo "[flux-gate] yq not found" >&2; exit 0; }

gate_key="$event"
file=""
if [ "$event" = "edit" ]; then
  input="$(cat 2>/dev/null || true)"
  file=$(printf '%s' "$input" | yq -p json -r '.tool_input.file_path // ""' 2>/dev/null || true)
elif [ "$event" = "push" ]; then
  # Only trigger when the intercepted Bash command is a `git push`.
  input="$(cat 2>/dev/null || true)"
  cmd_str=$(printf '%s' "$input" | yq -p json -r '.tool_input.command // ""' 2>/dev/null || true)
  case "$cmd_str" in
    *"git push"*) ;;
    *) exit 0 ;;
  esac
elif [ "$event" = "ci" ]; then
  gate_key="push"
fi

mapfile -t gates < <(yq -r ".gates.on_${gate_key}[]?" "$config")
[ ${#gates[@]} -eq 0 ] && exit 0

failed=0
report=""
for gate in "${gates[@]}"; do
  cmd=$(yq -r ".commands.\"$gate\" // \"\"" "$config")
  if [ -z "$cmd" ]; then
    report+=$'\n'"[flux-gate] gate '$gate': no command defined in $config"
    failed=1
    continue
  fi
  case "$cmd" in
    *"{file}"*)
      [ -n "$file" ] || continue
      quoted=$(printf '%q' "$file")
      cmd=${cmd//"{file}"/"$quoted"}
      ;;
  esac
  out=$(eval "$cmd" 2>&1)
  rc=$?
  if [ $rc -ne 0 ]; then
    failed=1
    report+=$'\n'"[flux-gate] gate '$gate' FAILED (exit $rc): $cmd"
    report+=$'\n'"$(printf '%s' "$out" | tail -30)"
  fi
done

if [ $failed -ne 0 ]; then
  printf '%s\n' "$report" >&2
  printf '\n[flux-gate] fix the failures above before continuing.\n' >&2
  exit 2
fi
exit 0
