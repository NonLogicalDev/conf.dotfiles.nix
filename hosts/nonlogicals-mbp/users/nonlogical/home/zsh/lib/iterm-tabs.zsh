if [[ -n "$ITERM_SESSION_ID" ]]; then
  function tab-color() {
    echo -ne "\033]6;1;bg;red;brightness;$1\a"
    echo -ne "\033]6;1;bg;green;brightness;$2\a"
    echo -ne "\033]6;1;bg;blue;brightness;$3\a"
  }

  function tab-reset() {
    echo -ne "\033]6;1;bg;*;default\a"
  }

  function iterm2_tab_precmd() {
    tab-reset
  }

  function iterm2_tab_preexec() {
    if [[ "$1" =~ "^ssh " ]]; then
      tab-color 56 132 255
    elif [[ "$1" =~ "^sudo" ]]; then
      tab-color 181 76 87
    fi
  }

  autoload -U add-zsh-hook
  add-zsh-hook precmd iterm2_tab_precmd
  add-zsh-hook preexec iterm2_tab_preexec
fi
