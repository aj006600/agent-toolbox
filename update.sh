#!/usr/bin/env bash
# Update the entries installed on this machine from the oh-my-skills marketplace.
#
#   ./update.sh              update every installed entry
#   ./update.sh <entry>...   update only the named entries
#
# It runs Claude Code's own update, then checks the result. Claude Code skips an
# update when upstream did not change its version number, so an external entry that
# is still behind is uninstalled and installed again. An external entry follows
# upstream's latest commit unless its "source" in the manifest has a "sha".
# Restart Claude Code afterwards. Requires git, jq, and the claude CLI.
set -uo pipefail
cd "$(dirname "$0")"

MARKETPLACE="oh-my-skills"
MANIFEST=".claude-plugin/marketplace.json"
INSTALLED="$HOME/.claude/plugins/installed_plugins.json"

case "${1:-}" in
  -h | --help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac

# The manifest in this clone says where each entry comes from, so bring it up to date.
git pull -q --ff-only 2>/dev/null || echo "Warning: could not pull this repo; using the manifest as it is here." >&2

if ! claude plugin marketplace list --json | jq -e --arg m "$MARKETPLACE" 'any(.[]; .name == $m)' >/dev/null; then
  echo "Marketplace '$MARKETPLACE' is not added in Claude Code. Add it first:" >&2
  echo "  /plugin marketplace add aj006600/oh-my-skills" >&2
  exit 1
fi
claude plugin marketplace update "$MARKETPLACE"

installed=$(claude plugin list --json |
  jq -r --arg m "@$MARKETPLACE" '.[].id | select(endswith($m)) | rtrimstr($m)' | sort -u)

failed=0
for name in ${*:-$installed}; do
  if ! echo "$installed" | grep -qx "$name"; then
    echo "$name: not installed on this machine; skipped"
    continue
  fi
  if ! jq -e --arg n "$name" 'any(.plugins[]; .name == $n)' "$MANIFEST" >/dev/null; then
    echo "$name: no longer in the marketplace; skipped. To remove it: /plugin uninstall $name@$MARKETPLACE"
    continue
  fi
  claude plugin update "$name@$MARKETPLACE" || failed=1

  # Own entries have no upstream to compare against; Claude Code's update is enough.
  url=$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .source | objects | .url // empty' "$MANIFEST")
  [ -n "$url" ] || continue
  want=$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .source.sha // empty' "$MANIFEST")
  [ -n "$want" ] || want=$(git ls-remote "$url" HEAD 2>/dev/null | cut -f1)
  if [ -z "$want" ]; then
    echo "$name: could not reach $url to check whether the update took effect"
    failed=1
    continue
  fi
  for scope in $(jq -r --arg id "$name@$MARKETPLACE" --arg s "$want" --arg d "$PWD" \
    '.plugins[$id][]? | select(.gitCommitSha != $s) | select(.scope == "user" or .projectPath == $d) | .scope' \
    "$INSTALLED"); do
    echo "$name: not at the expected commit after the update; reinstalling (scope: $scope)"
    claude plugin uninstall "$name@$MARKETPLACE" --scope "$scope" >/dev/null
    claude plugin install "$name@$MARKETPLACE" --scope "$scope" || failed=1
  done
done
exit $failed
