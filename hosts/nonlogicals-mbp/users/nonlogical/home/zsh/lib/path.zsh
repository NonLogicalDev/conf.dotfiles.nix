function path_list {
  for p in "${path[@]}"; do
    printf "%s\n" "$p"
  done
}
