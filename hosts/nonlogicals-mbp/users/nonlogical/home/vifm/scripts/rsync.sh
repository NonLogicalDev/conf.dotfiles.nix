#!/bin/bash

main() {
  local rsync_to=$1
  shift 1
  local rsync_from=()

  for _path in "$@"; do
    local _path_real=$(realpath "$_path")

    if [[ -d "$_path_real" ]]; then
      rsync_from+=("$_path/")
    else
      rsync_from+=("$_path")
    fi
  done

  echo rsync -avz --progress "${rsync_from[@]}" "$rsync_to"
}

main "$@"

