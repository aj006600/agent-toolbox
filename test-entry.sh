#!/usr/bin/env bash
# Check that entries really install, without changing the real oh-my-skills marketplace.
#
#   ./test-entry.sh <entry> [<entry>...]
#
# Copies the manifest (uncommitted changes included) into a temporary folder under the
# name oh-my-skills-test, installs the entries there, then removes everything it created.
# An entry passes when the install succeeds and the installed files contain its skills.
# It also asks a headless Claude session whether those skills are visible; that step is
# skipped when something already installed on this machine uses the same skill prefix,
# because the answer could not tell the two apart. Your real marketplace and installs
# are not changed. Requires jq and the claude CLI.
set -uo pipefail
cd "$(dirname "$0")"

MANIFEST=".claude-plugin/marketplace.json"
TEST_NAME="oh-my-skills-test"
repo=$PWD

usage() { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; }
case "${1:-}" in
  "") usage; exit 1 ;;
  -h | --help) usage; exit 0 ;;
esac
for name in "$@"; do
  jq -e --arg n "$name" 'any(.plugins[]; .name == $n)' "$MANIFEST" >/dev/null ||
    { echo "test-entry.sh: no entry named '$name'" >&2; exit 1; }
done

work=$(mktemp -d)
work=$(cd "$work" && pwd -P)

cleanup() {
  cd "$work" 2>/dev/null || return
  for name in "$@"; do
    claude plugin uninstall "$name@$TEST_NAME" --scope local >/dev/null 2>&1
  done
  claude plugin marketplace remove "$TEST_NAME" >/dev/null 2>&1
  cd "$repo"
  rm -rf "$work" "$HOME/.claude/plugins/cache/$TEST_NAME"
}
# A previous run that was killed may have left the test marketplace behind.
claude plugin marketplace remove "$TEST_NAME" >/dev/null 2>&1
trap 'cleanup "$@"' EXIT

mkdir -p "$work/.claude-plugin"
jq --arg n "$TEST_NAME" '.name = $n' "$MANIFEST" >"$work/.claude-plugin/marketplace.json"
for dir in skills plugins; do
  [ -d "$dir" ] && cp -R "$dir" "$work/$dir"
done

cd "$work"

# Skill prefixes already in use on this machine: the name of every installed plugin,
# from its id and from its plugin.json.
taken=$(claude plugin list --json 2>/dev/null | jq -r '.[] | [.id, .installPath] | @tsv' |
  while IFS=$'\t' read -r id path; do
    echo "${id%@*}"
    [ -f "$path/.claude-plugin/plugin.json" ] && jq -r '.name' "$path/.claude-plugin/plugin.json"
  done | sort -u)

claude plugin marketplace add "$work" >/dev/null 2>&1 ||
  { echo "test-entry.sh: could not add the temporary marketplace" >&2; exit 1; }

failed=0
for name in "$@"; do
  if ! out=$(claude plugin install "$name@$TEST_NAME" --scope local 2>&1); then
    echo "FAIL  $name: install failed"
    echo "$out" | tail -3 | sed 's/^/      /'
    failed=1
    continue
  fi
  path=$(claude plugin list --json | jq -r --arg id "$name@$TEST_NAME" '.[] | select(.id == $id) | .installPath' | head -1)
  if [ -z "$path" ] || [ ! -d "$path" ]; then
    echo "FAIL  $name: installed, but its files were not found"
    failed=1
    continue
  fi

  # Plugins are prefixed with their plugin.json name; standalone skills with the entry name.
  if [ -f "$path/.claude-plugin/plugin.json" ]; then
    prefix=$(jq -r '.name' "$path/.claude-plugin/plugin.json")
    count=$(find "$path" -name SKILL.md | wc -l | tr -d ' ')
    if [ "$count" -eq 0 ]; then
      echo "PASS  $name: installed; this plugin has no skills, so there is nothing more to check"
      continue
    fi
  else
    prefix=$name
    if [ ! -f "$path/SKILL.md" ]; then
      echo "FAIL  $name: installed, but there is no SKILL.md at the root of the installed files"
      failed=1
      continue
    fi
    count=1
  fi

  if echo "$taken" | grep -qx "$prefix"; then
    echo "PASS  $name: installed with $count skill file(s). Visibility check skipped: something already installed here uses the prefix '$prefix:'"
    continue
  fi
  seen=$(claude -p --model haiku "Look only at your available skills list. Print every skill name that starts with '$prefix:' exactly as listed, one per line. If none, print NONE. No other text." </dev/null 2>/dev/null | grep "^$prefix:" | sort -u)
  if [ -n "$seen" ]; then
    echo "PASS  $name: installed with $count skill file(s); visible as $(echo "$seen" | head -1)$([ "$(echo "$seen" | wc -l)" -gt 1 ] && echo " and others")"
  else
    echo "FAIL  $name: installed with $count skill file(s), but no skill starting with '$prefix:' is visible"
    failed=1
  fi
done

trap - EXIT
cleanup "$@"
left=$(grep -c "$TEST_NAME" "$HOME/.claude/plugins/installed_plugins.json" "$HOME/.claude/plugins/known_marketplaces.json" "$HOME/.claude/settings.json" 2>/dev/null | grep -v ':0$')
if [ -n "$left" ] || [ -e "$work" ]; then
  echo "WARNING: cleanup left something behind; tell the owner:"
  echo "$left"
  [ -e "$work" ] && echo "$work"
  failed=1
else
  echo "Cleanup done: nothing from the test is left on this machine."
fi
exit $failed
