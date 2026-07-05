#!/usr/bin/env bash
#
# Function:
#   Select one local bookmark interactively and publish it through `jj send`.
# Inputs:
#   No required positional inputs.
# Outputs:
#   Writes the bookmark picker and any `jj send` output to the terminal.
# Side effects:
#   Delegates to `jj send`, which may force-push a Git ref.
jji() { jj --ignore-working-copy "$@"; }

jj_local_bookmarks=$(jji log -GT 'json(self.bookmarks())' -r 'bookmarks() & mine()' | jq -r '.[]|.name' | grep -v "/jj-publish/")

bookmark_empty="---"
bookmark_selected=$({ echo "$bookmark_empty"; echo "$jj_local_bookmarks"; } | gum choose --header "Select a bookmark to push" --limit 1)
if [ "$bookmark_selected" = "$bookmark_empty" ]; then
  echo >&2 "Aborting: no bookmarks selected"
  exit 1
fi

jj send "$bookmark_selected"
