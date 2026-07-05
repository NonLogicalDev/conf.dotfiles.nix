#!/usr/bin/env bash
#
# Function:
#   Squash the current change into its parent while preserving the parent
#   message.
# Inputs:
#   No positional inputs; operates on the current working copy change.
# Outputs:
#   Writes normal `jj squash` output.
# Side effects:
#   Rewrites the current JJ change and its parent.

jj squash --use-destination-message --from "@" --to "@-"
