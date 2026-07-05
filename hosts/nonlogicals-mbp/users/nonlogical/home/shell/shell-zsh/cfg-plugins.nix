{ pkgs }:

[
  # Extra completion definitions. Home Manager's zsh plugin support adds this
  # package to fpath before compinit runs.
  {
    name = "zsh-completions";
    src = pkgs.zsh-completions;
    functions = [ "share/zsh/site-functions" ];
  }

  # Lightweight automatic quote/bracket pairing. This remains a zsh plugin
  # because Home Manager does not expose a higher-level option for it.
  {
    name = "zsh-autopair";
    src = pkgs.zsh-autopair;
    file = "share/zsh/zsh-autopair/autopair.zsh";
  }

  # Completion UI on top of fzf. This is distinct from `programs.fzf`; fzf gives
  # us the fuzzy finder and bindings, while fzf-tab replaces zsh's completion
  # selection UI.
  {
    name = "zsh-fzf-tab";
    src = pkgs.zsh-fzf-tab;
    file = "share/fzf-tab/fzf-tab.plugin.zsh";
  }
]
