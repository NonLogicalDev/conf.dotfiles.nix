{
  config,
  lib,
  pkgs,
}:

let
  cfg = config.dotfiles.suites.developerBase;
in

{
  user = {
    name = cfg.git.userName;
    email = cfg.git.userEmail;
  };

  credential."https://gist.github.com".helper = [
    ""
    "!${lib.getExe pkgs.gh} auth git-credential"
  ];

  core = {
    hooksPath = "${config.home.homeDirectory}/bin/git-hooks";
    pager = "cat";
  };

  pager = {
    show = "less";
    diff = "less";
    files = "cat";
  };

  pretty = {
    nice = "tformat:* %C(red)%h%Creset - %C(bold blue)<%an>%Creset %s%n    %C(green)(%ar / %cr)%C(yellow)%d%Creset";
    nice-extra = "tformat:%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an : %ae>%Creset";
    nice-cons = "tformat:%C(red)%h%Creset - %s | %C(bold blue)<%an>%Creset | %C(green)(%cr)%C(yellow)%d%Creset";
    nice-sep = "tformat:%n* %C(red)%h%Creset - %s%n\t%C(bold blue)<%an>%Creset%C(yellow)%d%Creset %C(green)(%cr)%Creset";
    nice-old = "tformat:%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an : %ae>%Creset";
    nice-cols = "tformat:%C(red)%h%Creset::%C(bold blue)<%an>%Creset::%s::%C(green)(%ar)%Creset::%C(yellow)%d%Creset";
  };

  commit.verbose = true;
  push.default = "simple";
  rerere.enabled = true;

  diff = {
    tool = "vimdiff";
    algorithm = "histogram";
  };

  merge = {
    tool = "vimdiff";
    conflictstyle = "diff3";
  };

  mergetool.intellij = {
    cmd = ''idea merge $(cd $(dirname "$LOCAL") && pwd)/$(basename "$LOCAL") $(cd $(dirname "$REMOTE") && pwd)/$(basename "$REMOTE") $(cd $(dirname "$BASE") && pwd)/$(basename "$BASE") $(cd $(dirname "$MERGED") && pwd)/$(basename "$MERGED")'';
    trustExitCode = true;
  };

  difftool = {
    intellij.cmd = ''idea diff $(cd $(dirname "$LOCAL") && pwd)/$(basename "$LOCAL") $(cd $(dirname "$REMOTE") && pwd)/$(basename "$REMOTE")'';
    vscode.cmd = "code --wait --diff $LOCAL $REMOTE";
  };

  tig.color = {
    cursor = "green black";
    title-focus = "green black";
    title-blur = "white black";
  };
}
