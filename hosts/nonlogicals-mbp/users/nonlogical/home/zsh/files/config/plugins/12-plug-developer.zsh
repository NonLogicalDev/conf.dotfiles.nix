################################################################################
# Utilities:
################################################################################

## iTerm Integration
function init.term.iterm {
  if [[ -s "${HOME}/.iterm2_shell_integration.zsh" ]]; then
    echo "INIT | iTerm..."

    source "${HOME}/.iterm2_shell_integration.zsh"
    INIT_LIST[iterm] = "iterm"
  fi
}
