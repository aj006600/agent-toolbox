#!/usr/bin/env bash
# Add an entry to this marketplace and a row to the matching README table.
#
#   ./add.sh skills/<name> --desc "<sentence>"     own standalone skill (the folder must already exist)
#   ./add.sh plugins/<name>                        own plugin (the folder must already exist)
#   ./add.sh <git url> [<path>]                    external plugin, at the repo root or in a subfolder
#   ./add.sh <git url> [<path>] --desc "<sentence>"   external standalone skill
#
# Options (after the arguments above):
#   --desc <sentence>  one-line English description. Required for standalone skills;
#                      plugins default to the description in their plugin.json.
#   --name <entry>     entry name for an external entry, when the detected one is taken
#
# The script detects the kind, pins externals to upstream's latest commit, puts the
# entry in the right group, and leaves a （待填） placeholder in the README row for
# you to fill in. On a name clash it stops without changing anything. It does not
# commit. Requires git and jq.
set -euo pipefail
cd "$(dirname "$0")"

MANIFEST=".claude-plugin/marketplace.json"
README="README.md"
TODO="（待填）"

usage() { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; }
die() { echo "add.sh: $*" >&2; exit 1; }
has_entry() { jq -e --arg n "$1" 'any(.plugins[]; .name == $n)' "$MANIFEST" >/dev/null; }

# insert_entry <group> <entry json>: group is own-skill, own-plugin, or external
insert_entry() {
  local tmp
  tmp=$(mktemp)
  jq --arg g "$1" --argjson e "$2" '
    def group: if (.source | type) == "object" then "external"
      elif (.source | startswith("./plugins/")) then "own-plugin"
      else "own-skill" end;
    .plugins = (
      [.plugins[] | select(group == "own-skill")] + (if $g == "own-skill" then [$e] else [] end)
      + [.plugins[] | select(group == "own-plugin")] + (if $g == "own-plugin" then [$e] else [] end)
      + [.plugins[] | select(group == "external")] + (if $g == "external" then [$e] else [] end)
    )' "$MANIFEST" >"$tmp"
  cat "$tmp" >"$MANIFEST"
  rm "$tmp"
}

# add_row <README heading> <row>: append the row to the table under that heading
add_row() {
  local tmp
  tmp=$(mktemp)
  awk -v heading="$1" -v row="$2" '
    function flush() { if (in_section && !done) { print row; done = 1 } }
    /^## / {
      if (in_section && !done) { flush(); print "" }
      in_section = ($0 == heading)
    }
    in_section && !done && seen_table && !/^\|/ { flush() }
    in_section && /^\|/ { seen_table = 1 }
    { print }
    END { flush() }
  ' "$README" >"$tmp"
  grep -qF -- "$2" "$tmp" || die "could not find the table under '$1' in $README"
  cat "$tmp" >"$README"
  rm "$tmp"
}

case "${1:-}" in
  "") usage; exit 1 ;;
  -h | --help) usage; exit 0 ;;
esac
target=$1
shift
subpath=""
if [ $# -ge 1 ] && [[ $1 != --* ]]; then
  subpath=${1%/}
  shift
fi
name_override=""
desc_override=""
while [ $# -gt 0 ]; do
  case $1 in
    --name) name_override=${2:?--name needs a value}; shift 2 ;;
    --desc) desc_override=${2:?--desc needs a value}; shift 2 ;;
    *) die "unknown option: $1" ;;
  esac
done
need_desc() { [ -n "$desc_override" ] || die "a standalone skill needs --desc \"<one English sentence>\""; }

owner=$(jq -r '.owner.name' "$MANIFEST")

# ---------- own content ----------
if [[ $target != *://* && $target != git@* ]]; then
  target=${target#./}
  target=${target%/}
  name=$(basename "$target")
  [ -z "$name_override" ] || die "--name is not supported for own content; rename the folder instead"
  has_entry "$name" && die "an entry named '$name' already exists; nothing was changed. Ask the owner how to resolve the clash"

  case $target in
    skills/*)
      [ -f "$target/SKILL.md" ] || die "$target/SKILL.md not found"
      need_desc
      entry=$(jq -n --arg n "$name" --arg d "$desc_override" --arg a "$owner" --arg s "./$target" \
        '{name: $n, description: $d, author: {name: $a}, source: $s, strict: false, skills: ["./"]}')
      insert_entry own-skill "$entry"
      add_row "## Own Skills" "| [$name]($target/SKILL.md) | $TODO | $TODO |"
      ;;
    plugins/*)
      pj="$target/.claude-plugin/plugin.json"
      [ -f "$pj" ] || die "$pj not found"
      [ "$(jq -r '.name' "$pj")" = "$name" ] || die "the name in $pj must equal the folder name '$name'"
      [ "$(jq -r 'has("version")' "$pj")" = "false" ] || die "$pj must not set a version"
      desc=${desc_override:-$(jq -r '.description // empty' "$pj")}
      [ -n "$desc" ] || die "no description in $pj; pass --desc"
      entry=$(jq -n --arg n "$name" --arg d "$desc" --arg a "$owner" --arg s "./$target" \
        '{name: $n, description: $d, author: {name: $a}, source: $s}')
      insert_entry own-plugin "$entry"
      skills=$(find "$target/skills" -mindepth 2 -maxdepth 2 -name SKILL.md 2>/dev/null |
        sed -e 's|/SKILL.md$||' -e 's|.*/||' | sort | paste -sd, - | sed 's/,/, /g')
      add_row "## Own Plugins" "| [$name]($target/) | $TODO | ${skills:-$TODO} |"
      ;;
    *) die "own content must be under skills/ or plugins/ (got '$target')" ;;
  esac
  echo "Added own entry '$name'."
  echo "Next: fill in the $TODO cells in $README, git add $target, then run ./test-entry.sh $name and ./check.sh."
  exit 0
fi

# ---------- external content ----------
url=${target%/}
if [[ $url == git@*:* ]]; then
  # git@host:account/repo(.git) -> https://host/account/repo for links
  rest=${url#git@}
  rest=${rest%.git}
  web="https://${rest%%:*}/${rest#*:}"
else
  if [[ $url == http* && $url != *.git ]]; then url="$url.git"; fi
  web=${url%.git}
fi
account=$(basename "$(dirname "$web")")
repo=$(basename "$web")

clone=$(mktemp -d)
trap 'rm -rf "$clone"' EXIT
git clone -q --depth 1 "$url" "$clone" || die "could not clone $url"
sha=$(git -C "$clone" rev-parse HEAD)
branch=$(git -C "$clone" rev-parse --abbrev-ref HEAD)

dir="$clone${subpath:+/$subpath}"
[ -d "$dir" ] || die "'$subpath' does not exist in $url"

if [ -f "$dir/.claude-plugin/plugin.json" ]; then
  kind="plugin"
  upstream_name=$(jq -r '.name' "$dir/.claude-plugin/plugin.json")
  author=$(jq -r '.author.name // empty' "$dir/.claude-plugin/plugin.json")
  desc=${desc_override:-$(jq -r '.description // empty' "$dir/.claude-plugin/plugin.json")}
  [ -n "$desc" ] || die "upstream plugin.json has no description; pass --desc"
elif [ -f "$dir/SKILL.md" ]; then
  kind="散裝 skill"
  upstream_name=$(basename "${subpath:-$repo}")
  author=""
  need_desc
  desc=$desc_override
else
  echo "add.sh: no .claude-plugin/plugin.json or SKILL.md at '${subpath:-the repo root}' of $url." >&2
  echo "Folders in that repo that can be added (pass one as the second argument):" >&2
  (cd "$clone" && find . -maxdepth 4 \( -path '*/.claude-plugin/plugin.json' -o -name SKILL.md \) -not -path './.git/*' |
    sed -e 's|^\./||' -e 's|/\.claude-plugin/plugin\.json$||' -e 's|/SKILL\.md$||' | sort -u | sed 's/^/  /') >&2
  exit 1
fi
author=${author:-$account}

name=${name_override:-$upstream_name}
if has_entry "$name"; then
  echo "add.sh: an entry named '$name' already exists; nothing was changed." >&2
  echo "Ask the owner, then rerun with a different name, for example: --name $account-$upstream_name" >&2
  if [ "$kind" = "plugin" ]; then
    echo "Tell the owner: a renamed plugin still installs its skills under the prefix '$upstream_name:'," >&2
    echo "so if both plugins are installed their skills overwrite each other." >&2
  fi
  exit 1
fi

if [ -n "$subpath" ]; then
  source=$(jq -n --arg u "$url" --arg p "$subpath" --arg s "$sha" \
    '{source: "git-subdir", url: $u, path: $p, sha: $s}')
  homepage="$web/tree/$branch/$subpath"
  link="$account/$repo/$subpath"
else
  source=$(jq -n --arg u "$url" --arg s "$sha" '{source: "url", url: $u, sha: $s}')
  homepage="$web"
  link="$account/$repo"
fi

entry=$(jq -n --arg n "$name" --arg d "$desc" --arg a "$author" --argjson src "$source" \
  '{name: $n, description: $d, author: {name: $a}, source: $src}')
if [ "$kind" != "plugin" ]; then
  entry=$(jq '. + {strict: false, skills: ["./"]}' <<<"$entry")
fi
if [[ $homepage == http* ]]; then
  entry=$(jq --arg h "$homepage" '. + {homepage: $h}' <<<"$entry")
fi

insert_entry external "$entry"
add_row "## External" "| $name | $kind | [$link]($homepage) | $TODO | |"
echo "Added external $kind '$name' pinned to ${sha:0:7}."
echo "Next: fill in the $TODO cell in $README, then run ./test-entry.sh $name and ./check.sh."
