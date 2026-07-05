function __microprompt_pwd() {
  local pwd_parts=(${(s:/:)PWD})
  local part_count=${#pwd_parts[@]}
  local compressed_pwd=""
  local home_prefix=""

  if [[ "$PWD" == "$HOME" ]]; then
    echo "~"
    return
  elif [[ "$PWD" == "$HOME/"* ]]; then
    home_prefix="~"
    pwd_parts=(${(s:/:)${PWD#$HOME/}})
    part_count=${#pwd_parts[@]}
  fi

  if [[ "$PWD" == "/" ]]; then
    echo "/"
    return
  fi

  if [[ $part_count -le 2 ]]; then
    if [[ -n "$home_prefix" ]]; then
      echo "$home_prefix/${(j:/:)pwd_parts}"
    else
      echo "/${(j:/:)pwd_parts}"
    fi
    return
  fi

  for (( i=0; i<part_count-2; i++ )); do
    if [[ "${pwd_parts[i+1]}" == .* ]]; then
      compressed_pwd+="${pwd_parts[i+1]:0:2}/"
    else
      compressed_pwd+="${pwd_parts[i+1]:0:1}/"
    fi
  done

  compressed_pwd+="${pwd_parts[part_count-1]}/${pwd_parts[part_count]}"

  if [[ -n "$home_prefix" ]]; then
    echo "$home_prefix/$compressed_pwd"
  else
    echo "/$compressed_pwd"
  fi
}

function __microprompt_prompt_cmd_duration() {
  [[ -z "$__MICROPROMPT_LAST_CMD_START_TIME" ]] && return

  local duration=$(( EPOCHSECONDS - __MICROPROMPT_LAST_CMD_START_TIME ))
  [[ $duration -lt 1 ]] && return

  local minutes=$(( duration / 60 ))
  local seconds=$(( duration % 60 ))
  if [[ $minutes -gt 0 ]]; then
    echo "${minutes}m${seconds}s"
  else
    echo "${seconds}s"
  fi
}

function __microprompt_prompt_cmd_exit_code() {
  [[ $__MICROPROMPT_LAST_CMD_EXIT_CODE -eq 0 ]] && return
  echo "$__MICROPROMPT_LAST_CMD_EXIT_CODE"
}

function __microprompt_prompt_date() {
  echo "%F{blue}$(date +%Y-%m-%dT%H:%M:%S)%f"
}

function __microprompt_prompt_host() {
  if [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    local hostname="${HOST:-$(hostname -s 2>/dev/null || hostname)}"
    echo "%F{cyan}($hostname)%f"
  fi
}

function __microprompt_prompt_preexec() {
  __MICROPROMPT_LAST_CMD_START_TIME=$EPOCHSECONDS
}

function __microprompt_prompt_precmd() {
  __MICROPROMPT_LAST_CMD_EXIT_CODE=$?
}

function __microprompt_prompt_newline() {
  echo $'\n%{\r%}'
}

function __microprompt_prompt_func() {
  (( __MICROPROMPT_ENABLE_ENRICHMENTS != 1 )) && return

  local prompt_parts=()
  prompt_parts+=("$(__microprompt_prompt_date)")

  local host_part="$(__microprompt_prompt_host)"
  [[ -n "$host_part" ]] && prompt_parts+=("$host_part")

  local exit_code_part="$(__microprompt_prompt_cmd_exit_code)"
  [[ -n "$exit_code_part" ]] && prompt_parts+=("%F{red}[$exit_code_part]%f")

  prompt_parts+=("$(__microprompt_pwd)")

  local duration_part="$(__microprompt_prompt_cmd_duration)"
  [[ -n "$duration_part" ]] && prompt_parts+=("%F{yellow}($duration_part)%f")

  if (( __MICROPROMPT_ENABLE_NEWLINE == 1 )); then
    echo "> ${(j: :)prompt_parts}$(__microprompt_prompt_newline)"
  else
    echo "> ${(j: :)prompt_parts} "
  fi
}

function microprompt_init() {
  zmodload zsh/datetime || :
  autoload -Uz +X add-zsh-hook 2>/dev/null

  setopt PROMPT_SUBST

  add-zsh-hook preexec __microprompt_prompt_preexec
  add-zsh-hook precmd __microprompt_prompt_precmd

  PROMPT='$(__microprompt_prompt_func)$ '

  function microprompt_split() {
    __MICROPROMPT_ENABLE_NEWLINE=$(( 1 - __MICROPROMPT_ENABLE_NEWLINE ))
  }

  __MICROPROMPT_ENABLE_ENRICHMENTS=1
  function microprompt_hide() {
    __MICROPROMPT_ENABLE_ENRICHMENTS=$(( 1 - __MICROPROMPT_ENABLE_ENRICHMENTS ))
  }

  microprompt_split
}

case "$TERM_PROGRAM" in
  WarpTerminal|vscode|cursor)
    __MICROPROMPT_DISABLE=1
    ;;
esac

if (( ${__MICROPROMPT_DISABLE:-0} != 1 )); then
  microprompt_init
fi
