{ pkgs }:

[
  {
    name = "zsh-completions";
    src = pkgs.zsh-completions;
    file = "no-plugin-file.zsh";
    functions = [ "share/zsh/site-functions" ];
  }
  {
    name = "zsh-autopair";
    src = pkgs.zsh-autopair;
    file = "share/zsh/zsh-autopair/autopair.zsh";
  }
  {
    name = "zsh-fzf-tab";
    src = pkgs.zsh-fzf-tab;
    file = "share/fzf-tab/fzf-tab.plugin.zsh";
  }
]
