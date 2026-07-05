#!/usr/bin/env bash
#
# Function:
#   Show the diff from the fork point of the current change and a bookmark to
#   the current working copy change.
# Inputs:
#   $1 - Required bookmark name or revset used as the comparison base.
# Outputs:
#   Writes a JJ diff to stdout, or an error message when the bookmark is absent.

jj_bm="$1"
if [[ -z "$jj_bm" ]]; then
  echo "Error: must specify a bookmark as an argument (e.g. 'jj diff-to <bookmark>')"
  exit 1
fi
jj --ignore-working-copy diff -f "fork_point(@|$jj_bm)" -t "@"
