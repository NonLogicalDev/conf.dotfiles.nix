#!/usr/bin/env bash
#
# Function:
#   Squash the current stack back into the nearest bookmark while preserving the
#   destination change message.
# Inputs:
#   No positional inputs; operates on the current working copy stack.
# Outputs:
#   Writes normal `jj squash` output.
# Side effects:
#   Rewrites the current JJ stack.

set -euxo pipefail

jj squash --use-destination-message --from "closest_bookmark(@)..@" --to "closest_bookmark(@)"
