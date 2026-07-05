if [[ -d "$HOME/.krew" ]]; then
  path=( "$HOME/.krew/bin" ${path:#"$HOME/.krew/bin"} )
fi

if (( $+commands[python3] )); then
  python_user_bin="$(python3 -m site --user-base 2>/dev/null)/bin"
  [[ -d "$python_user_bin" ]] && path=( "$python_user_bin" ${path:#"$python_user_bin"} )
  unset python_user_bin
fi

if [[ -d "$HOME/.poetry" ]]; then
  path=( "$HOME/.poetry/bin" ${path:#"$HOME/.poetry/bin"} )
  [[ -r "$HOME/.poetry/env" ]] && source "$HOME/.poetry/env"
fi

if [[ -s "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
  path=( "$HOME/.cargo/bin" ${path:#"$HOME/.cargo/bin"} )
fi

if (( $+commands[nvim] )); then
  alias vim="nvim"
  export PREFERRED_EDITOR="$(command -v nvim)"
elif (( $+commands[vim] )); then
  export PREFERRED_EDITOR="$(command -v vim)"
elif (( $+commands[vi] )); then
  export PREFERRED_EDITOR="$(command -v vi)"
fi

export EDITOR="${EDITOR:-$PREFERRED_EDITOR}"
export VISUAL="${VISUAL:-$PREFERRED_EDITOR}"
