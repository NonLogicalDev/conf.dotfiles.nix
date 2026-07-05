#!/usr/bin/env bash
#
# Function:
#   Print all bookmarks reachable from the current change.
# Inputs:
#   No positional inputs; reads the current JJ repository state.
# Outputs:
#   Writes zero or more bookmark names separated by newlines.

set -euo pipefail

jj --ignore-working-copy log \
  -n 1 -G \
  -r 'bookmarks() & ::@' \
  -T 'stringify(self.bookmarks().join("\n")) ++ "\n"'
