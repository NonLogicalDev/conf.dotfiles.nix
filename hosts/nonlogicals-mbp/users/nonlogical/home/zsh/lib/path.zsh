function path_list {
  for p in "${path[@]}"; do
    printf "%s\n" "$p"
  done
}

function path_drop {
  local args=()
  if [[ $1 == '-' ]]; then
    while IFS= read -r a; do
      args+=( "$a" )
    done
  else
    args=( "$@" )
  fi

  local new_path=()
  for p in "${path[@]}"; do
    local match=0
    for pn in "${args[@]}"; do
      if [[ $p == $pn ]]; then
        match=1
        break
      fi
    done
    if [[ match -eq 1 ]]; then
      continue
    fi
    new_path+=( "$p" )
  done
  path=( "${new_path[@]}" )
}

function path_append {
  local args=()
  if [[ $1 == '-' ]]; then
    while IFS= read -r a; do
      args+=( "$a" )
    done
  else
    args=( "$@" )
  fi

  path_drop "${args[@]}"
  path=( "${path[@]}" "${args[@]}" )
}

function path_prepend {
  local args=()
  if [[ $1 == '-' ]]; then
    while IFS= read -r a; do
      args+=( "$a" )
    done
  else
    args=( "$@" )
  fi

  path_drop "${args[@]}"
  path=( "${args[@]}" "${path[@]}" )
}
