autoload -Uz compinit

zsh_cache_dir="${ZSH_CACHE_DIR:-$HOME/.cache/zsh}"
mkdir -p "$zsh_cache_dir"

zsh_comp_files=("$zsh_cache_dir"/compdump(Nm-20))
if (( $#zsh_comp_files )); then
  compinit -i -C -d "$zsh_cache_dir/compdump"
else
  compinit -i -d "$zsh_cache_dir/compdump"
fi
unset zsh_cache_dir zsh_comp_files
