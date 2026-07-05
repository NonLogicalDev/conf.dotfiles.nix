#!/usr/bin/env bash
#
# Function:
#   Print the first bookmark reachable from the current change.
# Inputs:
#   No positional inputs; reads the current JJ repository state.
# Outputs:
#   Writes one bookmark name, or an empty line when none is reachable.

jj --ignore-working-copy log \
  -n 1 -G \
  -r 'bookmarks() & ::@' \
  -T 'stringify(self.bookmarks().join("\n")).first_line() ++ "\n"'
