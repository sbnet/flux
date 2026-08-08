#!/usr/bin/env bash
# flux-doctor: diagnose, and optionally repair, a stale flux install.
#
# Claude Code pins every installed plugin in
# <config>/plugins/installed_plugins.json, each entry carrying a version and
# an installPath into <config>/plugins/cache/<marketplace>/<plugin>/<version>.
# The session runs the pinned copy. Updating the marketplace clone does not
# always move that pin, and re-installing does not always move it either: the
# clone goes to the new version while the session keeps serving the old one.
# When a release renames a skill, the drift surfaces as
# "Unknown command: /flux:<name>" rather than as a version problem.
#
# This is a Claude Code behavior flux works around. The script does not fix
# the plugin manager; it repairs the state the plugin manager left behind.
#
# Usage: flux-doctor.sh [--fix]
#   (no flag)  compare the marketplace clone with the pinned install and report
#   --fix      copy the marketplace plugin into the versioned cache path and
#              rewrite the pin, after backing up installed_plugins.json
#
# Exit 0: marketplace and install agree (or --fix made them agree).
# Exit 1: they drift (report mode only).
# Exit 2: nothing could be diagnosed or repaired: missing marketplace clone,
#         missing pin entry, missing dependency, or bad usage.
# Dependency: yq v4 (mikefarah).

set -uo pipefail

MARKETPLACE="flux"
PLUGIN="flux"
PIN_KEY="${PLUGIN}@${MARKETPLACE}"

fix=0
case "${1:-}" in
  "") ;;
  --fix) fix=1 ;;
  -h|--help) sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "usage: $(basename "$0") [--fix]" >&2; exit 2 ;;
esac

# Absolute path to this script, so the repair hint stays copy-pasteable
# whatever the working directory it was invoked from.
self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
plugins_dir="$config_dir/plugins"
pin_file="$plugins_dir/installed_plugins.json"
mkt_dir="$plugins_dir/marketplaces/$MARKETPLACE"
mkt_plugin="$mkt_dir/plugins/$PLUGIN"
mkt_manifest="$mkt_plugin/.claude-plugin/plugin.json"

# Shorten $HOME to ~ for display only; every real path stays absolute.
short() { printf '%s' "${1/#$HOME/\~}"; }

fail() { printf '%s\n' "$@" >&2; exit 2; }

# Sorted names of the skill directories under $1, one per line.
skill_names() {
  local dir="$1" entry
  [ -d "$dir" ] || return 0
  for entry in "$dir"/*/; do
    [ -d "$entry" ] || continue
    basename "$entry"
  done | sort
}

command -v yq >/dev/null 2>&1 || fail \
  "[flux-doctor] yq not found." \
  "Install yq v4 (mikefarah), which flux needs for the gate hook too:" \
  "  https://github.com/mikefarah/yq/releases"

[ -d "$mkt_plugin" ] || fail \
  "[flux-doctor] no marketplace clone at $(short "$mkt_dir")." \
  "Nothing to compare against, and nothing safe to repair. Add the" \
  "marketplace first, then re-run this script from the clone it creates:" \
  "  claude plugin marketplace add sbnet/flux"

[ -f "$mkt_manifest" ] || fail \
  "[flux-doctor] the marketplace clone has no plugin manifest at" \
  "$(short "$mkt_manifest"). The clone is incomplete; refresh it with:" \
  "  claude plugin marketplace update $MARKETPLACE"

[ -f "$pin_file" ] || fail \
  "[flux-doctor] no $(short "$pin_file")." \
  "The plugin has never been installed. Install it, then re-run:" \
  "  claude plugin install $PIN_KEY"

mkt_version=$(yq -p json -o json -r ".version // \"\"" "$mkt_manifest")
pin_version=$(yq -p json -o json -r ".plugins[\"$PIN_KEY\"][0].version // \"\"" "$pin_file")
pin_path=$(yq -p json -o json -r ".plugins[\"$PIN_KEY\"][0].installPath // \"\"" "$pin_file")

[ -n "$mkt_version" ] || fail \
  "[flux-doctor] the marketplace manifest declares no version:" \
  "$(short "$mkt_manifest")"

[ -n "$pin_version" ] || fail \
  "[flux-doctor] no pin entry for $PIN_KEY in $(short "$pin_file")." \
  "The plugin is not installed for this config directory. Install it," \
  "then re-run:" \
  "  claude plugin install $PIN_KEY"

# --- diagnosis ------------------------------------------------------------

drift=0
notes=""
note() { notes+="$1"$'\n'; }

path_state="missing"
if [ -n "$pin_path" ] && [ -d "$pin_path" ]; then
  path_state="exists"
fi

printf 'flux-doctor\n\n'
printf '  config dir     %s\n' "$(short "$config_dir")"
printf '  marketplace    %s  (%s)\n' "$mkt_version" "$(short "$mkt_dir")"
printf '  installed pin  %s\n' "$pin_version"
printf '  install path   %s  (%s)\n' "$(short "${pin_path:-(none)}")" "$path_state"

if [ "$mkt_version" != "$pin_version" ]; then
  drift=1
  note "  versions       DRIFT: marketplace $mkt_version, installed $pin_version"
fi

if [ "$path_state" = "missing" ]; then
  drift=1
  note "  install path   MISSING: the pin points at a directory that is not there"
else
  # Skill directory names are what a session exposes as /flux:<name>. Comparing
  # them against the marketplace catches a rename even when the versions agree.
  mkt_skills=$(skill_names "$mkt_plugin/skills")
  pin_skills=$(skill_names "$pin_path/skills")
  if [ "$mkt_skills" != "$pin_skills" ]; then
    drift=1
    note "  skills         DRIFT: installed skill names differ from the marketplace"
    only_pin=$(comm -23 <(printf '%s\n' "$pin_skills") <(printf '%s\n' "$mkt_skills") | paste -sd, - | sed 's/,/, /g')
    only_mkt=$(comm -13 <(printf '%s\n' "$pin_skills") <(printf '%s\n' "$mkt_skills") | paste -sd, - | sed 's/,/, /g')
    [ -n "$only_pin" ] && note "                   installed only: $only_pin"
    [ -n "$only_mkt" ] && note "                   marketplace only: $only_mkt"
  else
    printf '  skills         %s match the marketplace\n' "$(printf '%s\n' "$pin_skills" | grep -c .)"
  fi
fi

[ -n "$notes" ] && printf '%s' "$notes"
printf '\n'

if [ "$drift" -eq 0 ]; then
  printf '[flux-doctor] OK: the installed plugin is version %s, same as the marketplace.\n' "$pin_version"
  exit 0
fi

if [ "$fix" -eq 0 ]; then
  printf '[flux-doctor] STALE: the session runs %s while the marketplace has %s.\n' "$pin_version" "$mkt_version"
  printf '[flux-doctor] Repair it with:\n'
  printf '  bash %s --fix\n' "$(short "$self")"
  exit 1
fi

# --- repair ---------------------------------------------------------------

target="$plugins_dir/cache/$MARKETPLACE/$PLUGIN/$mkt_version"

# Never remove anything outside the versioned cache path we are about to write.
case "$target" in
  "$plugins_dir/cache/$MARKETPLACE/$PLUGIN/"?*) ;;
  *) fail "[flux-doctor] refusing to write outside the plugin cache: $target" ;;
esac

stamp=$(date -u +%Y%m%d-%H%M%S)
backup="$pin_file.$stamp.bak"
cp -p "$pin_file" "$backup" || fail "[flux-doctor] could not back up $(short "$pin_file")"

printf '[flux-doctor] backup written: %s\n' "$(short "$backup")"
printf '[flux-doctor] restore it with:\n'
printf '  cp %s %s\n\n' "$backup" "$pin_file"

mkdir -p "$(dirname "$target")" || fail "[flux-doctor] could not create $(short "$(dirname "$target")")"
rm -rf "${target:?}"
cp -R "$mkt_plugin/." "$target/" || fail \
  "[flux-doctor] copy failed: $(short "$mkt_plugin") -> $(short "$target")" \
  "The pin file is untouched; the backup above is redundant and can be removed."
printf '[flux-doctor] copied %s -> %s\n' "$(short "$mkt_plugin")" "$(short "$target")"

sha=""
if [ -d "$mkt_dir/.git" ] && command -v git >/dev/null 2>&1; then
  sha=$(git -C "$mkt_dir" rev-parse HEAD 2>/dev/null || true)
fi
now=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)

if ! yq -p json -o json -i "
  .plugins[\"$PIN_KEY\"][0].installPath = \"$target\" |
  .plugins[\"$PIN_KEY\"][0].version = \"$mkt_version\" |
  .plugins[\"$PIN_KEY\"][0].lastUpdated = \"$now\"
" "$pin_file"; then
  fail \
    "[flux-doctor] rewriting the pin failed. Restore it with:" \
    "  cp $backup $pin_file"
fi

if [ -n "$sha" ]; then
  yq -p json -o json -i ".plugins[\"$PIN_KEY\"][0].gitCommitSha = \"$sha\"" "$pin_file" || fail \
    "[flux-doctor] rewriting gitCommitSha failed. Restore the pin with:" \
    "  cp $backup $pin_file"
fi

printf '[flux-doctor] pin rewritten: version %s, installPath %s\n' "$mkt_version" "$(short "$target")"
printf '\n[flux-doctor] REPAIRED. Restart your Claude Code session now:\n'
printf '  the pin is read at startup, so /reload-plugins is not enough.\n'
exit 0
