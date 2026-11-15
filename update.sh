#!/usr/bin/env bash
# Update plugins installed from the oh-my-skills marketplace.
#   ./update.sh                    update every installed plugin
#   ./update.sh <plugin> [...]     update only the named plugins
set -euo pipefail

MARKETPLACE="oh-my-skills"

claude plugin marketplace update "$MARKETPLACE"

if [ $# -gt 0 ]; then
  plugins="$*"
else
  plugins=$(claude plugin list --json |
    jq -r --arg m "@$MARKETPLACE" '.[].id | select(endswith($m)) | rtrimstr($m)' | sort -u)
fi

if [ -z "$plugins" ]; then
  echo "No plugins installed from $MARKETPLACE."
  exit 0
fi

failed=0
for plugin in $plugins; do
  claude plugin update "$plugin@$MARKETPLACE" || failed=1
done
exit $failed
