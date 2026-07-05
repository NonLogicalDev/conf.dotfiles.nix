#!/usr/bin/env bash
#
# Function:
#   Compare two bookmark-backed stacks by diffing from the first bookmark's fork
#   point to the second bookmark's change id.
# Inputs:
#   $1 - Required first bookmark name or revset.
#   $2 - Required second bookmark name or revset.
# Outputs:
#   Writes a JJ diff to stdout, or an error message if either bookmark cannot
#   be resolved.
_jji () { jj --ignore-working-copy "$@"; }

jj_bm_a="$1" jj_bm_b="$2"
if [[ -z "$jj_bm_a" ]] || [[ -z "$jj_bm_b" ]]; then
  echo "Error: must specify a bookmark as an argument (e.g. 'jj diff-bw <bookmark1> <bookmark2>')"
  exit 1
fi
jj_change_id_a=$(_jji log -n 1 -r "$jj_bm_a" -GT "self.change_id()")
if [[ -z "$jj_change_id_a" ]]; then
  echo "Error: Could not find change_id for bookmark [$jj_bm_a] (bug)"
  exit 1
fi
jj_change_id_b=$(_jji log -n 1 -r "$jj_bm_b" -GT "self.change_id()")
if [[ -z "$jj_change_id_b" ]]; then
  echo "Error: Could not find change_id for bookmark [$jj_bm_b] (bug)"
  exit 1
fi
_jji diff -f "fork_point(@|$jj_change_id_a)" -t "$jj_change_id_b"
