#!/usr/bin/env bash
# Check that the manifest, the folders, and README agree with each other.
#
#   ./check.sh
#
# Exits non-zero and lists every problem found. Runs automatically before each
# `git commit` made through Claude Code (.claude/hooks/pre-commit-check.sh).
# Requires jq; also runs `claude plugin validate .` when the claude CLI is present.
set -uo pipefail
cd "$(dirname "$0")"

MANIFEST=".claude-plugin/marketplace.json"
HOLDS=".claude-plugin/holds.json"
README="README.md"
problems=0
problem() { echo "  - $*"; problems=$((problems + 1)); }

jq -e . "$MANIFEST" >/dev/null 2>&1 || { echo "check.sh: $MANIFEST is not valid JSON"; exit 1; }

# Layout: update.sh rewrites the file with jq, so it must already be in jq's layout.
jq . "$MANIFEST" | cmp -s - "$MANIFEST" || problem "$MANIFEST is not in jq layout; run: jq . $MANIFEST > tmp && mv tmp $MANIFEST"

# Names are unique.
dupes=$(jq -r '.plugins[].name' "$MANIFEST" | sort | uniq -d)
[ -z "$dupes" ] || problem "duplicate entry names: $(echo $dupes)"

# Order: own skills, then own plugins, then external.
order=$(jq -r '[.plugins[] | if (.source | type) == "object" then 3
  elif (.source | startswith("./plugins/")) then 2 else 1 end] | . == sort' "$MANIFEST")
[ "$order" = "true" ] || problem "entries must be ordered: own skills, own plugins, external"

# Each entry, by kind.
while IFS=$'\t' read -r name kind source sha strict; do
  case $kind in
    own)
      dir=${source#./}
      case $dir in
        skills/*)
          [ -f "$dir/SKILL.md" ] || problem "$name: $dir/SKILL.md is missing"
          [ "$strict" = "false" ] || problem "$name: an own standalone skill needs \"strict\": false and \"skills\": [\"./\"]"
          [ "$(basename "$dir")" = "$name" ] || problem "$name: entry name must equal the folder name"
          ;;
        plugins/*)
          pj="$dir/.claude-plugin/plugin.json"
          if [ -f "$pj" ]; then
            [ "$(jq -r '.name' "$pj")" = "$name" ] || problem "$name: the name in $pj must equal the entry name"
            [ "$(jq -r 'has("version")' "$pj")" = "false" ] || problem "$name: $pj must not set a version"
          else
            problem "$name: $pj is missing"
          fi
          ;;
        *) problem "$name: own content must live under skills/ or plugins/ (source is $source)" ;;
      esac
      if [ -d "$dir" ] && [ -n "$(git ls-files --others --exclude-standard -- "$dir")" ]; then
        problem "$name: $dir has files that are not in git yet; run: git add $dir"
      fi
      ;;
    external)
      [[ $sha =~ ^[0-9a-f]{40}$ ]] || problem "$name: external entries need a full 40-character sha"
      [ -n "$source" ] || problem "$name: external entries need source.url"
      ;;
  esac
  grep -qE "^\| (\[$name\]\(|$name \|)" "$README" || problem "$name: no row in $README"
done < <(jq -r '.plugins[] | [.name,
  (if (.source | type) == "object" then "external" else "own" end),
  (if (.source | type) == "object" then (.source.url // "") else .source end),
  (if (.source | type) == "object" then (.source.sha // "-") else "-" end),
  (if has("strict") then .strict else true end | tostring)] | @tsv' "$MANIFEST")

# Every own folder that is in git has an entry. A folder that is not in git yet is
# work in progress and is left alone.
for dir in skills/*/ plugins/*/; do
  [ -d "$dir" ] || continue
  dir=${dir%/}
  [ -n "$(git ls-files -- "$dir")" ] || continue
  jq -e --arg s "./$dir" 'any(.plugins[]; .source == $s)' "$MANIFEST" >/dev/null ||
    problem "$dir has no entry; run ./add.sh $dir, or remove the folder with git rm -r $dir"
done

# README rows all belong to an entry, and none is left unfilled.
while IFS= read -r row_name; do
  jq -e --arg n "$row_name" 'any(.plugins[]; .name == $n)' "$MANIFEST" >/dev/null ||
    problem "$README has a row for '$row_name' but there is no such entry"
done < <(awk '
  /^## / { in_tables = ($0 == "## Own Skills" || $0 == "## Own Plugins" || $0 == "## External") }
  in_tables && /^\| / && !/^\| 條目/ && !/^\|---/ {
    cell = $0; sub(/^\| /, "", cell); sub(/ \|.*/, "", cell)
    if (cell ~ /^\[/) { sub(/^\[/, "", cell); sub(/\].*/, "", cell) }
    print cell
  }' "$README")
if grep -q '^|.*（待填）' "$README"; then
  problem "$README still has （待填） cells to fill in"
fi

# Holds only name existing external entries.
if [ -f "$HOLDS" ]; then
  for held in $(jq -r 'keys[]' "$HOLDS"); do
    jq -e --arg n "$held" 'any(.plugins[]; .name == $n and (.source | type) == "object")' "$MANIFEST" >/dev/null ||
      problem "$HOLDS lists '$held', which is not an external entry"
  done
fi

if command -v claude >/dev/null 2>&1; then
  claude plugin validate . >/dev/null 2>&1 || problem "claude plugin validate . failed; run it to see why"
fi

if [ "$problems" -gt 0 ]; then
  echo "check.sh: $problems problem(s) found (listed above)."
  exit 1
fi
echo "check.sh: OK"
