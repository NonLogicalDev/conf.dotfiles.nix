#!/usr/bin/env bash
#
# Function:
#   Print the Git commit id backing a Jujutsu revision.
# Inputs:
#   $1 - Optional JJ revset or revision. Defaults to the working copy change.
# Outputs:
#   Writes the full Git commit id to stdout.

set -euo pipefail

jj --ignore-working-copy log -n 1 -GT 'self.commit_id()' -r "${1:-@}"
