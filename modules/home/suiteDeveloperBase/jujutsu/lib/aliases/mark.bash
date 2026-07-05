#!/usr/bin/env bash
#
# Function:
#   Create a short random bookmark on a selected JJ change.
# Inputs:
#   $1 - Optional bookmark prefix. Prompts with a default when omitted.
#   $2 - Optional target change id or revset. Opens an interactive picker when
#        omitted.
# Outputs:
#   Writes picker prompts, validation errors, and the traced bookmark command.
# Side effects:
#   Creates one JJ bookmark.
gen_suffix() { ( LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom || true ) | head -c 5; }
jji() { jj --ignore-working-copy "$@"; }

prefix="${1:-}"
target="${2:-}"

if [[ -z "$target" ]]; then
  target=$(
    jji log -r 'trunk()..@ & mine()' -GT \
      'separate(" ", self.change_id(), self.author().email().local(), "--", self.bookmarks().join(", "), "--", self.description().first_line()) ++ "\n"' \
    | gum choose --header "Select a target change-id" --limit 1 \
    | cut -d' ' -f1
  )
  if [[ -z "$target" ]]; then
    echo >&2 "Error: Must provide a target change-id as an argument"
    exit 1
  fi
fi
if [[ -z "$prefix" ]]; then
  prefix=$(gum input --placeholder "Bookmark prefix" --value ktlo)
fi

jj_json=$(jji log -n 1 -r "$target" -GT 'json(self)')
if [[ -z "$jj_json" ]]; then
  echo >&2 "Error: Could not find change_id for target [$target]"
  exit 1
fi

jj_change_id=$(echo "$jj_json" | jq -r '.change_id // ""')
if [[ -z "$jj_change_id" ]]; then
  echo >&2 "Error: Could not find change_id for target [$target] (bug)"
  exit 1
fi

jj_bookmark_name="$prefix-$(gen_suffix)"
( set -x; jj bookmark create "$jj_bookmark_name" -r "$jj_change_id" )
