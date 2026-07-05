function is-callable {
  (( $+commands[$1] || $+functions[$1] || $+aliases[$1] || $+builtins[$1] ))
}

function coalesce {
  for arg in $argv; do
    print "$arg"
    return 0
  done
  return 1
}

function sman() {
  local max_man_width=120
  if [[ $COLUMNS -gt $max_man_width ]]; then
    MANWIDTH=$max_man_width man "$@"
  else
    man "$@"
  fi
}

function rm() {
  local is_recursive=0
  local is_force=0
  local has_home=0
  local has_root=0

  for arg in "$@"; do
    [[ $arg == "-f" ]] && is_force=1
    [[ $arg == "-r" ]] && is_recursive=1
    [[ $arg == "-rf" || $arg == "-fr" ]] && is_force=1 && is_recursive=1
    [[ $arg == "$HOME" ]] && has_home=1
    [[ $arg == "/" ]] && has_root=1
  done

  if [[ $is_force -eq 1 && $is_recursive -eq 1 ]]; then
    if [[ $has_home -eq 1 || $has_root -eq 1 ]]; then
      echo "ERROR: refusing dangerous rm $*" >&2
      return 128
    fi

    echo "Just checking in..." >&2
    echo "You are running 'rm $*'" >&2
    echo "Are you totally sure? (y/n)" >&2
    read "REPLY?"
    if [[ $REPLY != "y" && $REPLY != "yes" ]]; then
      echo "ERROR: aborting..." >&2
      return 128
    fi
  fi

  command rm -v "$@"
}

function cdf() {
  cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')"
}

function mkdcd {
  [[ -n "$1" ]] && mkdir -p "$1" && builtin cd "$1"
}

function cdls {
  builtin cd "$argv[-1]" && ls "${(@)argv[1,-2]}"
}

function pushdls {
  builtin pushd "$argv[-1]" && ls "${(@)argv[1,-2]}"
}

function popdls {
  builtin popd "$argv[-1]" && ls "${(@)argv[1,-2]}"
}

function slit {
  awk "{ print ${(j:,:):-\$${^@}} }"
}

function find-exec {
  find . -type f -iname "*${1:-}*" -exec "${2:-file}" '{}' \;
}

function psu {
  ps -U "${1:-$LOGNAME}" -o 'pid,%cpu,%mem,command' "${(@)argv[2,-1]}"
}

function gi() {
  curl -L -s "https://www.gitignore.io/api/$*"
}

function lk {
  if [[ -d "$1" ]]; then
    ls -al "$1"
  fi
}

function wanip {
  dig @resolver1.opendns.com ANY myip.opendns.com +short
}

function refresh {
  tput clear || return 2
  zsh -ic "$@"
}

function cwatch {
  while true; do
    local output
    output=$(refresh "$@")
    local exitcode=$?
    [[ $exitcode -ne 0 ]] && return "$exitcode"
    printf '%s' "$output"
  done
}

function expand-aliases {
  unset 'functions[_expand-aliases]'
  functions[_expand-aliases]=$BUFFER
  if (($+functions[_expand-aliases])); then
    BUFFER=${functions[_expand-aliases]#$'\t'}
    CURSOR=$#BUFFER
  fi
}

zle -N expand-aliases
bindkey '^E' expand-aliases
