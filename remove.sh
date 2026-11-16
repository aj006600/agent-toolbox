#!/usr/bin/env bash
# Remove an entry from this marketplace and its row from README.
#
#   ./remove.sh <entry>
#
# For own content the folder is deleted too; it stays in git history.
# It does not commit and does not uninstall anything. Requires git and jq.
set -euo pipefail
cd "$(dirname "$0")"

MANIFEST=".claude-plugin/marketplace.json"
HOLDS=".claude-plugin/holds.json"
README="README.md"

usage() { sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; }
case "${1:-}" in
  -h | --help) usage; exit 0 ;;
esac
[ $# -eq 1 ] || { usage; exit 1; }
name=$1

source=$(jq -r --arg n "$name" '.plugins[] | select(.name == $n) | .source | if type == "string" then . else "" end' "$MANIFEST")
jq -e --arg n "$name" 'any(.plugins[]; .name == $n)' "$MANIFEST" >/dev/null ||
  { echo "remove.sh: no entry named '$name'" >&2; exit 1; }

tmp=$(mktemp)
jq --arg n "$name" 'del(.plugins[] | select(.name == $n))' "$MANIFEST" >"$tmp"
cat "$tmp" >"$MANIFEST"

if [ -f "$HOLDS" ]; then
  jq --arg n "$name" 'del(.[$n])' "$HOLDS" >"$tmp"
  cat "$tmp" >"$HOLDS"
fi

# README rows start with "| <entry> |" (external) or "| [<entry>](" (own).
awk -v n="$name" 'index($0, "| " n " |") != 1 && index($0, "| [" n "](") != 1' "$README" >"$tmp"
cat "$tmp" >"$README"
rm "$tmp"

echo "Removed entry '$name' from $MANIFEST and $README."
if [ -n "$source" ]; then
  dir=${source#./}
  case $dir in
    skills/?* | plugins/?*)
      if [ -n "$(git status --porcelain -- "$dir")" ]; then
        echo "$dir has changes that were never committed, so it was not deleted."
        echo "If you no longer want them: git rm -r -f --ignore-unmatch $dir; rm -rf $dir"
      else
        git rm -r -q -- "$dir"
        echo "Deleted $dir (it stays in git history)."
      fi
      ;;
  esac
fi
echo "Remind the owner to run on every machine that has it installed:"
echo "  /plugin uninstall $name@oh-my-skills"
