#!/usr/bin/env bash
#
# Function:
#   Select one local bookmark interactively and publish it through `jj send`.
# Inputs:
#   No required positional inputs.
#   $JJ_BOOKMARK_EXCLUDE_PATTERN - Optional grep pattern for hidden bookmarks.
# Outputs:
#   Writes the bookmark picker and any `jj send` output to the terminal.
# Side effects:
#   Delegates to `jj send`, which may force-push a Git ref.

set -euo pipefail

jji() { jj --ignore-working-copy "$@"; }

jj_local_bookmarks=$(jji log -GT 'json(self.bookmarks())' -r 'bookmarks() & mine()' | jq -r '.[]|.name')
if [[ -n "${JJ_BOOKMARK_EXCLUDE_PATTERN:-}" ]]; then
  jj_local_bookmarks=$(printf '%s\n' "$jj_local_bookmarks" | grep -v -- "$JJ_BOOKMARK_EXCLUDE_PATTERN" || true)
fi

bookmark_empty="---"
bookmark_selected=$({ echo "$bookmark_empty"; echo "$jj_local_bookmarks"; } | gum choose --header "Select a bookmark to push" --limit 1)
if [ "$bookmark_selected" = "$bookmark_empty" ]; then
  echo >&2 "Aborting: no bookmarks selected"
  exit 1
fi

jj send "$bookmark_selected"
