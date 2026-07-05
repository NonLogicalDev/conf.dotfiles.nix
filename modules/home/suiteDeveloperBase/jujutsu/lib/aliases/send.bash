#!/usr/bin/env bash
#
# Function:
#   Push a single JJ change to Git, either under an existing bookmark selected
#   interactively or under a generated change-id branch name.
# Inputs:
#   $1 - Optional JJ reference to publish. Defaults to the working copy change.
#   $2 - Optional remote name. Defaults to origin. The current implementation
#        validates the value but still pushes to origin; keep this visible until
#        the publishing flow is tightened.
# Outputs:
#   Writes selection prompts, validation errors, and the traced git push command
#   to the terminal.
# Side effects:
#   Force-pushes one Git ref to the selected remote namespace.

set -euo pipefail

jji() { jj --ignore-working-copy "$@"; }

jj_ref="${1:-@}"
jj_remote="${2:-origin}"

if [ -z "$jj_ref" ]; then
  echo >&2 "Error: must specify a reference as an argument (e.g. 'jj send <reference>')"
  exit 1
fi
if [ -z "$jj_remote" ]; then
  echo >&2 "Error: must specify a remote as an argument (e.g. 'jj send <reference> <remote>') (default: origin)"
  exit 1
fi

commit_json=$(jji log -n 1 -r "$jj_ref" -GT 'json(self)')
if [ -z "$commit_json" ]; then
  echo >&2 "Error: Could not find commit for reference [$jj_ref]"
  exit 1
fi

jj_change_id=$(echo "$commit_json" | jq -r '.change_id // ""')
if [ -z "$jj_change_id" ]; then
  echo >&2 "Error: Could not find change_id for bookmark [$jj_ref] (bug)"
  exit 1
fi

jj_change_id_short="${jj_change_id:0:8}"
bookmarks_json=$(jji log -n 1 -r "$jj_change_id" -GT 'json(self.bookmarks())')
bookmarks_found=$(echo "$bookmarks_json" | jq -r --arg ref "$jj_ref" '.[]? | select(.name == $ref) | .name')

bookmark_selected=""
bookmark_empty="(change-id: $jj_change_id_short)"

if [ -z "$bookmark_selected" ] && [ "$(printf "%s" "$bookmarks_found" | wc -l)" -ge 0 ]; then
  bookmark_selected=$({ echo "$bookmark_empty"; echo "$bookmarks_found"; } | gum choose --header "Select a bookmark to push as" --limit 1)
  if [ -z "$bookmark_selected" ]; then
    echo >&2 "Aborting: No bookmark option selected, assuming Ctrl-C was pressed"
    exit 1
  fi
fi
if [ "$bookmark_selected" = "$bookmark_empty" ]; then
  bookmark_selected=""
fi

jj_author=$(echo "$commit_json" | jq -r '.author.email // ""' | cut -d@ -f1)
if [ -z "$jj_author" ]; then
  echo >&2 "Error: Could not find author for bookmark [$jj_ref] (bug)"
  exit 1
fi

git_commit_id=$(echo "$commit_json" | jq -r '.commit_id // ""')
if [ -z "$git_commit_id" ]; then
  echo >&2 "Error: Could not find commit_id for bookmark [$jj_ref] (bug)"
  exit 1
fi

if [ -z "$bookmark_selected" ]; then
  ( set -x;
    git push origin -f "$git_commit_id:refs/heads/$jj_author/jj-change-id/$jj_change_id_short"
  )
fi
if [ -n "$bookmark_selected" ]; then
  ( set -x;
    git push origin -f "$git_commit_id:refs/heads/$jj_author/jj-bookmark/$bookmark_selected"
  )
fi
