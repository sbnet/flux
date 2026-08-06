#!/usr/bin/env bash
# flux-gate — hook générique piloté par flux-config.yml
#
# Usage : flux-gate.sh <edit|push|stop|ci>
#   edit  → gates.on_edit   (PostToolUse sur Edit|Write)
#   push  → gates.on_push   (PreToolUse sur Bash, seulement si `git push`)
#   stop  → gates.on_stop   (Stop)
#   ci    → gates.on_push   (appel direct depuis la CI, sans stdin)
#
# Sortie 0 : tout est vert (ou rien à faire). Sortie 2 : au moins un gate
# a échoué — Claude Code bloque l'action et reçoit le rapport sur stderr.
# Dépendance : yq v4 (mikefarah).

set -uo pipefail

event="${1:?usage: flux-gate.sh <edit|push|stop|ci>}"
root="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$root" || exit 0
config="flux-config.yml"
[ -f "$config" ] || exit 0
command -v yq >/dev/null || { echo "[flux-gate] yq introuvable" >&2; exit 0; }

gate_key="$event"
if [ "$event" = "push" ]; then
  # Ne se déclenche que si la commande Bash interceptée est un `git push`.
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
    report+=$'\n'"[flux-gate] gate '$gate' : aucune commande définie dans $config"
    failed=1
    continue
  fi
  out=$(eval "$cmd" 2>&1)
  rc=$?
  if [ $rc -ne 0 ]; then
    failed=1
    report+=$'\n'"[flux-gate] gate '$gate' ÉCHEC (exit $rc) — $cmd"
    report+=$'\n'"$(printf '%s' "$out" | tail -30)"
  fi
done

if [ $failed -ne 0 ]; then
  printf '%s\n' "$report" >&2
  printf '\n[flux-gate] corrige les erreurs ci-dessus avant de continuer.\n' >&2
  exit 2
fi
exit 0
