#!/usr/bin/env bash
#
# Function:
#   Remove a local bookmark or forget/untrack a remote bookmark reference.
# Inputs:
#   $1 - Required bookmark reference. Use `name` for local bookmarks or
#        `name@remote` for remote-tracking bookmark cleanup.
# Outputs:
#   Writes detected mode, traced JJ/Git commands, and validation errors.
# Side effects:
#   Deletes local bookmarks, untracks/forgets remote bookmark refs, and removes
#   the matching Git ref when a remote reference is supplied.

set -euo pipefail

jji() { jj --ignore-working-copy "$@"; }

jj_ref="$1"
if [ -z "$jj_ref" ]; then
  echo >&2 "Error: must specify a reference as an argument (e.g. 'jj begone <reference>')"
  exit 1
fi

jj_ref_local=$(echo "$jj_ref" | jq -Rr '(split("@")[0]) // ""')
jj_ref_remote=$(echo "$jj_ref" | jq -Rr '(split("@")[1]) // ""')

if [ -z "$jj_ref_remote" ]; then
  echo "Detected: local bookmark [$jj_ref]"
  (set -x;
    jji bookmark delete "$jj_ref_local"
  ) || true
fi

if [ -n "$jj_ref_remote" ]; then
  (set -x;
    jji bookmark untrack "$jj_ref"
    jji bookmark forget --include-remotes "$jj_ref_local"
    git update-ref -d "refs/heads/$jj_ref_remote/$jj_ref_local"
  ) || true
fi
