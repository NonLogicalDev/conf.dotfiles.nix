zmodload zsh/terminfo || :
autoload -Uz edit-command-line && zle -N edit-command-line

function zsh-widget-noop() {}
zle -N zsh-widget-noop

if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  function zle-line-init() {
    printf '%s' "${terminfo[smkx]}"
  }

  function zle-line-finish() {
    printf '%s' "${terminfo[rmkx]}"
  }

  zle -N zle-line-init
  zle -N zle-line-finish
fi

typeset -g -A key
key=(
  Tab          '	'
  ShiftTab     '^[[Z'
  Backspace    '^?'
  Delete       '^[[3~'
  Home         "$terminfo[khome]"
  End          "$terminfo[kend]"
  PageUp       "$terminfo[kpp]"
  PageDown     "$terminfo[knp]"
  Up           "$terminfo[kcuu1]"
  Down         "$terminfo[kcud1]"
  Left         "$terminfo[kcub1]"
  Right        "$terminfo[kcuf1]"
  Insert       "$terminfo[kich1]"
)

[[ -n "${key[Home]}" ]] && bindkey -- "${key[Home]}" beginning-of-line
[[ -n "${key[End]}" ]] && bindkey -- "${key[End]}" end-of-line
[[ -n "${key[PageUp]}" ]] && bindkey -- "${key[PageUp]}" beginning-of-buffer-or-history
[[ -n "${key[PageDown]}" ]] && bindkey -- "${key[PageDown]}" end-of-buffer-or-history
[[ -n "${key[Left]}" ]] && bindkey -- "${key[Left]}" backward-char
[[ -n "${key[Right]}" ]] && bindkey -- "${key[Right]}" forward-char
[[ -n "${key[Backspace]}" ]] && bindkey -- "${key[Backspace]}" backward-delete-char
[[ -n "${key[Delete]}" ]] && bindkey -- "${key[Delete]}" delete-char
[[ -n "${key[Insert]}" ]] && bindkey -- "${key[Insert]}" overwrite-mode

zmodload zsh/complist || :
bindkey -M menuselect -- "${key[Tab]}" menu-complete
bindkey -M menuselect -- "${key[ShiftTab]}" reverse-menu-complete

bindkey -M viins ' ' magic-space
bindkey -M vicmd '\e' zsh-widget-noop
bindkey -M vicmd 'v' edit-command-line
bindkey '^Q' push-line-or-edit
bindkey -M viins '^Y' yank
bindkey -M viins '^U' kill-whole-line
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^?' backward-delete-char

if (( $+widgets[history-substring-search-up] )); then
  [[ -n "${key[Up]}" ]] && bindkey -- "${key[Up]}" history-substring-search-up
  [[ -n "${key[Down]}" ]] && bindkey -- "${key[Down]}" history-substring-search-down
fi
