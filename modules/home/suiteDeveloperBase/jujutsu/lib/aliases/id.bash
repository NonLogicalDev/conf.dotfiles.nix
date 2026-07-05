#!/usr/bin/env bash
#
# Function:
#   Print the Jujutsu change id for a revision.
# Inputs:
#   $1 - Optional JJ revset or revision. Defaults to the working copy change.
# Outputs:
#   Writes the full change id to stdout.
jj --ignore-working-copy log -n 1 -GT 'self.change_id()' -r "${1:-@}"
