#!/usr/bin/env bash
# Manage the pinned versions of the external entries in this marketplace.
#
#   ./update.sh                   show each external entry's pinned and latest commit
#   ./update.sh --all             pin every external entry to its latest commit
#   ./update.sh <entry>           pin one entry to its latest commit
#   ./update.sh <entry> <ref>     pin one entry to a branch, tag, or full 40-char sha
#   ./update.sh --sync            pull this repo, then bring this machine's installs in line with the pins
#   ./update.sh --hold <entry> [reason]   keep an entry at its pinned commit; --all skips it
#   ./update.sh --unhold <entry>          let it move again
#
# Changing a pin commits and pushes the manifest, then updates the matching installs
# in Claude Code. Nothing runs unless you invoke it. Requires git, jq, and the claude CLI.
set -euo pipefail
cd "$(dirname "$0")"

MARKETPLACE="oh-my-skills"
MANIFEST=".claude-plugin/marketplace.json"
HOLDS=".claude-plugin/holds.json"

externals() { jq -r '.plugins[] | select(.source | type == "object") | .name' "$MANIFEST"; }
field() { jq -r --arg n "$1" ".plugins[] | select(.name == \$n) | $2 // empty" "$MANIFEST"; }

# hold_reason <entry> -> the reason it is held, or nothing if it is not held
hold_reason() {
  [ -f "$HOLDS" ] || return 0
  jq -r --arg n "$1" '.[$n] // empty' "$HOLDS"
}

# set_hold <entry> [reason]: an empty reason releases the hold. Commits and pushes.
set_hold() {
  local name=$1 reason=${2:-} tmp verb
  if [ -z "$(field "$name" '(.source | objects | .url)')" ]; then
    echo "Not an external entry: $name" >&2
    exit 1
  fi
  if [ -z "${OMS_NO_GIT:-}" ]; then
    if [ -n "$(git status --porcelain -- "$HOLDS")" ]; then
      echo "$HOLDS has uncommitted changes; commit or discard them first." >&2
      exit 1
    fi
    git pull -q --ff-only
  fi
  [ -f "$HOLDS" ] || echo '{}' >"$HOLDS"
  tmp=$(mktemp)
  if [ -n "$reason" ]; then
    verb="hold"
    jq --arg n "$name" --arg r "$reason" '.[$n] = $r' "$HOLDS" >"$tmp"
  else
    verb="unhold"
    jq --arg n "$name" 'del(.[$n])' "$HOLDS" >"$tmp"
  fi
  if cmp -s "$tmp" "$HOLDS"; then
    rm "$tmp"
    echo "$name: nothing to change"
    return 0
  fi
  cat "$tmp" >"$HOLDS"
  rm "$tmp"
  echo "$name: $verb${reason:+ ($reason)}"
  if [ -z "${OMS_NO_GIT:-}" ]; then
    git add -- "$HOLDS"
    git commit -q -m "chore: $verb $name" -- "$HOLDS"
    git push -q
    echo "Pushed: chore: $verb $name"
  fi
}

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
  local name url pinned latest state held
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
    held=$(hold_reason "$name")
    [ -z "$held" ] || state="held ($held); $state"
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
      if [ -z "$(field "$name" .name)" ]; then
        # Installed here but removed from the manifest: leave it for the owner to uninstall.
        echo "$name: no longer in the marketplace; skipped. To remove it from this machine:"
        claude plugin list --json |
          jq -r --arg id "$name@$MARKETPLACE" \
            '.[] | select(.id == $id) | "  claude plugin uninstall \($id) --scope \(.scope)"'
        continue
      fi
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
  -h | --help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  --hold)
    [ $# -ge 2 ] || { echo "Usage: ./update.sh --hold <entry> [reason]" >&2; exit 1; }
    name=$2
    shift 2
    set_hold "$name" "${*:-held}"
    exit 0
    ;;
  --unhold)
    [ $# -eq 2 ] || { echo "Usage: ./update.sh --unhold <entry>" >&2; exit 1; }
    set_hold "$2"
    exit 0
    ;;
  --sync)
    # Pull first: the reinstall check reads the pins from this clone's manifest.
    [ -n "${OMS_NO_GIT:-}" ] || git pull -q --ff-only
    sync_installed
    exit $?
    ;;
  --all)
    ref=""
    targets=""
    for name in $(externals); do
      held=$(hold_reason "$name")
      if [ -n "$held" ]; then
        echo "$name: held ($held); skipped"
      else
        targets="$targets $name"
      fi
    done
    ;;
  *)
    targets=$1
    ref=${2:-}
    if [ -z "$(field "$1" '(.source | objects | .url)')" ]; then
      echo "Not an external entry: $1" >&2
      exit 1
    fi
    held=$(hold_reason "$1")
    if [ -n "$held" ] && [ -z "$ref" ]; then
      echo "$1 is held ($held). Name a version to move it anyway, or release it first:" >&2
      echo "  ./update.sh --unhold $1" >&2
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
  if [ -n "$ref" ] && [ -z "$(hold_reason "$name")" ]; then
    echo "  to keep --all from moving it: ./update.sh --hold $name <reason>"
  fi
  changed="$changed $name"
done

if [ -n "$changed" ] && [ -z "${OMS_NO_GIT:-}" ]; then
  git commit -q -m "chore: bump$changed" -- "$MANIFEST"
  git push -q
  echo "Pushed: chore: bump$changed"
fi

# 2. Claude Code: update the installs of the entries just handled.
# shellcheck disable=SC2086
sync_installed $targets
