{
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

  # Legacy environment hint used by existing personal scripts. Keep it explicit
  # here until those scripts are audited or replaced.
  PLATFORM = "MAC";
}
