#!/usr/bin/env bash
#
# Function:
#   Inspect a divergent JJ change id and determine whether the divergent Git
#   commits are actually different.
# Inputs:
#   $1 - Optional JJ reference to inspect. Defaults to the working copy change.
# Outputs:
#   Prints the divergent commit candidates, an optional diff summary/full diff,
#   and the repair command when both commits are equivalent.
# Side effects:
#   No repository mutations; this only reads JJ/Git state and may page a diff.
jj_ref="${1:-@}"

jj_commit_ids=$(jj --ignore-working-copy log -r "change_id($(jj id $jj_ref))" -GT 'separate("\t", self.change_id(), commit_timestamp(self), self.commit_id()) ++ "\n"' | sort -n)
echo "$jj_commit_ids"

if [ "$(echo "$jj_commit_ids" | wc -l)" -lt 2 ]; then
  echo >&2 "OK: less than 2 commits found for reference [$jj_ref], reference is not divergent"
  exit 0
fi

declare -a jj_git_shas_map
while IFS=$'\t' read -r jj_commit_id jj_timestamp jj_git_sha; do
  jj_git_shas_array+=( "$jj_git_sha" )
done <<< "$jj_commit_ids"

echo "Diverging commit id options:"
echo "  ${jj_git_shas_array[@]}"

if [ "$(echo "$jj_commit_ids" | wc -l)" -gt 2 ]; then
  echo >&2 "Error: more than 2 commits found for reference [$jj_ref], reference is super divergent"
  exit 1
fi

summary_output=$(git diff-tree --no-commit-id --name-status -r "${jj_git_shas_array[0]}" "${jj_git_shas_array[1]}")
echo "Checking for differences between the commits..."
if [ -n "$summary_output" ]; then
  echo "Showing full diff..."
  echo "================================================"
  echo "$summary_output"
  echo "================================================"
  if gum confirm "Show full diff?"; then
    echo "Showing full diff..."
    echo "================================================"
    git diff "${jj_git_shas_array[0]}:" "${jj_git_shas_array[1]}:" | cat
    echo "================================================"
  fi
else
  echo "  No differences found."
  echo "Undiverge the change by running:"
  echo "  jj new ${jj_git_shas_array[1]} && jj abandon ${jj_git_shas_array[0]}"
fi
