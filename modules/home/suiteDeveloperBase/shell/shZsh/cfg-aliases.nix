{
  # This file should stay small. Aliases here are personal interactive
  # shortcuts, not compatibility shims for every command used in old dotfiles.

  # Use bat for quick file reads while preserving cat's no-pager behavior.
  cat = "bat -p --pager=never";

  # Show disk capacity in human units on macOS and Linux.
  df = "df -kh";

  # Show directory/file size totals in human units.
  du = "du -kh";

  # Short git entry point for frequent interactive use.
  g = "git";

  # Keep grep matches readable in terminals without affecting redirected output.
  grep = "grep --color=auto";

  # Short kubectl entry point; this is muscle memory more than abstraction.
  k = "kubectl";

  # Use eza as the default directory listing implementation.
  ls = "eza --group-directories-first";

  # Compact all-files listing for quick scans.
  l = "eza --oneline --all --group-directories-first";

  # Long listing with headers and Git status for project directories.
  ll = "eza --long --header --git --group-directories-first";

  # Long all-files listing for inspecting hidden config state.
  la = "eza --long --all --header --git --group-directories-first";

  # Long listing sorted by modification time for recent-file checks.
  lt = "eza --long --sort=modified --group-directories-first";

  # Retain established shortcuts for recursive and alternate sorted listings.
  lr = "eza --long --recurse --group-directories-first";
  lx = "eza --long --sort=extension --group-directories-first";
  lk = "eza --long --sort=size --group-directories-first";
  lc = "eza --long --sort=changed --changed --group-directories-first";
  lu = "eza --long --sort=accessed --accessed --group-directories-first";
  lm = "eza --long --all --header --git --group-directories-first | $PAGER";

  # Short entry point for the cross-platform opener wrapper.
  o = "opn";

  # Re-run the previous shell command through sudo after an expected denial.
  oops = "sudo $(fc -ln -1)";
}
