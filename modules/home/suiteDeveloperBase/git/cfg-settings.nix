{
  config,
  lib,
  pkgs,
}:

let
  # Concrete values come from dotfiles.suites.developerBase.scmIdentity in the
  # host-user profile. Keep this file reusable across machines by avoiding
  # literal names, email addresses, or personal namespace strings.
  cfg = config.dotfiles.suites.developerBase;
in

{
  # Shared source-control identity. This intentionally matches Jujutsu so the
  # suite has one normal authorship surface.
  user = {
    name = cfg.scmIdentity.name;
    email = cfg.scmIdentity.email;
  };

  credential."https://gist.github.com".helper = [
    ""
    "!${lib.getExe pkgs.gh} auth git-credential"
  ];

  core = {
    # Keep hooks in ~/bin/git-hooks because older scripts and repos may already
    # assume that location. A future package-managed hook suite can replace this
    # once those scripts are inventoried.
    hooksPath = "${config.home.homeDirectory}/bin/git-hooks";
    pager = "cat";
  };

  pager = {
    show = "less";
    diff = "less";
    files = "cat";
  };

  pretty = {
    # These formats back the log aliases in cfg-aliases.nix. They favor dense
    # one-screen review of local stacks over Git's default verbose log output.
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
    # JetBrains tools want absolute paths. The command normalizes Git's
    # temporary relative paths before handing them to IDEA.
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
