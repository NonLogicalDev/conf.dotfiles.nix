{ pkgs }:

{
  # Keep optional command-line tools quiet and focused when they are present.
  ANSIBLE_NOCOWS = "1";
  FZFZ_EXCLUDE_PATTERN = ".git/|env/";

  # Color matched grep text with a loud but familiar magenta background. Both
  # variables are kept because different grep implementations consult different
  # names.
  GREP_COLOR = "37;45";
  GREP_COLORS = "mt=37;45";

  # Keep shells and CLI tools on UTF-8. This is host-user profile state, not zsh
  # behavior, so it lives in the parent shell suite.
  LANG = "en_US.UTF-8";
  LC_ALL = "en_US.UTF-8";

  # Prefer Neovim everywhere a shell-launched program asks for an editor. This
  # is intentionally declarative instead of probing for nvim/vim/vi at startup.
  EDITOR = "nvim";
  PREFERRED_EDITOR = "nvim";
  VISUAL = "nvim";

  # Default pager for programs that honor PAGER. Pager behavior/options are
  # configured in `programs.less` in the parent shell module.
  PAGER = "less";

  # Preserve terminal capabilities expected by existing editor preferences.
  NVIM_TUI_ENABLE_TRUE_COLOR = "1";
  TERM_ITALICS = "true";

}
// pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
  # Legacy environment hint used by existing macOS-only personal scripts. Do
  # not set it on Linux; a false platform signal is worse than an absent one.
  PLATFORM = "MAC";

  # Homebrew casks belong in the conventional macOS applications directory.
  HOMEBREW_CASK_OPTS = "--appdir=/Applications";
}
