#!/usr/bin/env bash
# Manage the pinned versions of the external entries in this marketplace.
#
#   ./update.sh                   show each external entry's pinned and latest commit
#   ./update.sh --all             pin every external entry to its latest commit
#   ./update.sh <entry>           pin one entry to its latest commit
#   ./update.sh <entry> <ref>     pin one entry to a branch, tag, or full 40-char sha
#   ./update.sh --sync            only bring this machine's installs in line with the pins
#
# Changing a pin commits and pushes the manifest, then updates the matching installs
# in Claude Code. Nothing runs unless you invoke it. Requires git, jq, and the claude CLI.
set -euo pipefail
cd "$(dirname "$0")"

MARKETPLACE="oh-my-skills"
MANIFEST=".claude-plugin/marketplace.json"

externals() { jq -r '.plugins[] | select(.source | type == "object") | .name' "$MANIFEST"; }
field() { jq -r --arg n "$1" ".plugins[] | select(.name == \$n) | $2 // empty" "$MANIFEST"; }

# resolve <url> [ref] -> full commit sha
resolve() {
  local url=$1 ref=${2:-HEAD} sha
  if [[ $ref =~ ^[0-9a-f]{40}$ ]]; then
    echo "$ref"
    return
  fi
  sha=$(git ls-remote "$url" "$ref" "$ref^{}" | tail -1 | cut -f1)
  if [ -z "$sha" ]; then
    echo "Cannot resolve '$ref' in $url (use a branch, tag, or full 40-char sha)" >&2
    return 1
  fi
  echo "$sha"
}

status() {
  local name url pinned latest state
  printf '%-24s %-9s %-9s %s\n' ENTRY PINNED LATEST STATUS
  for name in $(externals); do
    url=$(field "$name" .source.url)
    pinned=$(field "$name" .source.sha)
    latest=$(resolve "$url")
    if [ -z "$pinned" ]; then
      state="not pinned"
    elif [ "$pinned" = "$latest" ]; then
      state="up to date"
    else
      state="update available"
      if [[ $url == https://github.com/* ]]; then
        state="$state  ${url%.git}/compare/${pinned:0:7}...${latest:0:7}"
      fi
    fi
    printf '%-24s %-9s %-9s %s\n' "$name" "${pinned:0:7}" "${latest:0:7}" "$state"
  done
}

# sync_installed [entry...] -> update the named installed entries, or all of them
sync_installed() {
  local installed name failed=0
  if ! claude plugin marketplace list --json |
    jq -e --arg m "$MARKETPLACE" 'any(.[]; .name == $m)' >/dev/null; then
    echo "Marketplace '$MARKETPLACE' is not added in Claude Code; nothing to update on this machine."
    return 0
  fi
  claude plugin marketplace update "$MARKETPLACE"
  installed=$(claude plugin list --json |
    jq -r --arg m "@$MARKETPLACE" '.[].id | select(endswith($m)) | rtrimstr($m)' | sort -u)
  for name in ${*:-$installed}; do
    if echo "$installed" | grep -qx "$name"; then
      claude plugin update "$name@$MARKETPLACE" || failed=1
      reinstall_if_stale "$name" || failed=1
    fi
  done
  return $failed
}

# Claude Code skips an update when the upstream version number is unchanged, even if
# the pinned commit moved. Reinstalling fetches the pinned commit regardless.
reinstall_if_stale() {
  local name=$1 pinned scope
  pinned=$(field "$name" '(.source | objects | .sha)')
  [ -n "$pinned" ] || return 0
  for scope in $(jq -r --arg id "$name@$MARKETPLACE" --arg s "$pinned" --arg d "$PWD" \
    '.plugins[$id][]? | select(.gitCommitSha != $s) | select(.scope == "user" or .projectPath == $d) | .scope' \
    "$HOME/.claude/plugins/installed_plugins.json"); do
    echo "$name: installed commit differs from the pin; reinstalling (scope: $scope)"
    claude plugin uninstall "$name@$MARKETPLACE" --scope "$scope" >/dev/null
    claude plugin install "$name@$MARKETPLACE" --scope "$scope" || return 1
  done
}

case "${1:-}" in
  "") status; exit 0 ;;
  -h | --help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  --sync) sync_installed; exit $? ;;
  --all) targets=$(externals); ref="" ;;
  *)
    targets=$1
    ref=${2:-}
    if [ -z "$(field "$1" '(.source | objects | .url)')" ]; then
      echo "Not an external entry: $1" >&2
      exit 1
    fi
    ;;
esac

# 1. GitHub: move the pins in the manifest, commit, and push.
# OMS_NO_GIT=1 skips every git step (for trying the script against a local marketplace).
if [ -z "${OMS_NO_GIT:-}" ]; then
  if [ -n "$(git status --porcelain -- "$MANIFEST")" ]; then
    echo "$MANIFEST has uncommitted changes; commit or discard them first." >&2
    exit 1
  fi
  git pull -q --ff-only
fi

changed=""
for name in $targets; do
  old=$(field "$name" .source.sha)
  new=$(resolve "$(field "$name" .source.url)" "$ref")
  if [ "$old" = "$new" ]; then
    echo "$name: already pinned to ${new:0:7}"
    continue
  fi
  tmp=$(mktemp)
  jq --arg n "$name" --arg s "$new" \
    '(.plugins[] | select(.name == $n) | .source.sha) = $s' "$MANIFEST" >"$tmp"
  cat "$tmp" >"$MANIFEST"
  rm "$tmp"
  echo "$name: ${old:0:7} -> ${new:0:7}"
  [ -z "$old" ] || echo "  roll back with: ./update.sh $name $old"
  changed="$changed $name"
done

if [ -n "$changed" ] && [ -z "${OMS_NO_GIT:-}" ]; then
  git commit -q -m "Bump$changed" -- "$MANIFEST"
  git push -q
  echo "Pushed: Bump$changed"
fi

# 2. Claude Code: update the installs of the entries just handled.
# shellcheck disable=SC2086
sync_installed $targets
