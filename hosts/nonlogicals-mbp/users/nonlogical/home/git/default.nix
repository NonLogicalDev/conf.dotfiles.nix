{
  lib,
  pkgs,
  ...
}:

{
  home.packages = [
    pkgs.gh
  ];

  programs.unmanaged.git = {
    enable = true;

    # Only the XDG global config exists today. Keeping one include site avoids
    # reading multi-valued settings, such as credential helpers, twice.
    includeTargets = [ ".config/git/config" ];
  };

  programs.git = {
    ignores = [
      ".vscode/"
      ".idea/"
      "*.local.md"
      ".nvim.lua"
      "[._]*.s[a-w][a-z]"
      "[._]s[a-w][a-z]"
      "*.un~"
      "Session.vim"
      ".netrwhist"
      "*~"
      "*.iml"
      "*.ipr"
      "*.iws"
      "/out/"
      ".idea_modules/"
      "atlassian-ide-plugin.xml"
      "com_crashlytics_export_strings.xml"
      "crashlytics.properties"
      "crashlytics-build.properties"
      "*.DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "Icon"
      "._*"
      ".DocumentRevisions-V100"
      ".fseventsd"
      ".Spotlight-V100"
      ".TemporaryItems"
      ".Trashes"
      ".VolumeIcon.icns"
      ".com.apple.timemachine.donotpresent"
      ".AppleDB"
      ".AppleDesktop"
      "Network Trash Folder"
      "Temporary Items"
      ".apdisk"
    ];

    settings = [
      {
        user = {
          name = "Oleg Utkin";
          email = "hello@nonlogical.net";
        };

        credential."https://gist.github.com".helper = [
          ""
          "!${lib.getExe pkgs.gh} auth git-credential"
        ];

        core = {
          hooksPath = "~/bin/git-hooks";
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

      {
        alias = {
          s = "show";
          b = "branch";
          co = "checkout";
          sw = "switch";

          l = "!git log -n 10 --first-parent --pretty=nice-cons $(git upstream)..HEAD";
          lg = "log -n 10 --first-parent --pretty=nice";
          lgr = "lg --reverse";
          lgf = "log -n 10 --first-parent --pretty=nice-sep --name-status";
          lgg = "log -n 10 --graph --pretty=nice-cons";
          lgt = ''!git lg --pretty=nice-cols --color | column -t -s "::"'';
          lgu = "!git lg -n 100 $(git upstream)..HEAD";
          lguu = "!git lg -n 100 HEAD..$(git upstream)";

          pullr = "pull --rebase";
          pullff = "pull --ff-only";
          mergeff = "merge --ff-only";

          st = "status -s";
          stu = "status -su";
          ls = "ls-files --exclude-standard";
          stat = "!git --no-pager show --numstat --shortstat --format=";

          d = "diff";
          dc = "diff --cached";
          diffc = "diff --cached";
          cdiff = "diff --cached";

          c = "commit";
          cm = "commit -m";
          ca = "commit --amend --no-edit";
          cae = "commit --amend";

          rb = "rebase";
          rbe = "rebase --edit";
          rbc = "rebase --continue";
          rbi = "rebase -i";
          rbu = "!git rebase $(git upstream)";

          cp = "cherry-pick";

          su = "submodule update";
          suc = "submodule update --checkout";

          ls-untracked = ''!git ls-files -v | grep "^[[:lower:]]" | perl -pe "s/^\\\\w+\\\\s+//"'';
          untrack = "update-index --assume-unchanged";
          track = "update-index --no-assume-unchanged";

          sum = "show --format=medium --stat";
          dir-root = "rev-parse --path-format=absolute --show-toplevel";
          root = "dir-root";
          dir-git = "rev-parse --path-format=absolute --git-dir";
          dir-db = "rev-parse --path-format=absolute --git-common-dir";
          upstream = "!f() { git rev-parse --abbrev-ref \${1:-HEAD}@{upstream}; }; f";
          run = ''!f() { cd "`git root`"; "$@"; }; f'';
          checkpoint = ''!f() { git add -A && git commit -m "$(date) :: checkpoint''${1:+ :: $1}"; }; f'';
          save = "checkpoint";

          addi = "!git status -u --porcelain | fzf -m | cut -c 3- | xargs git run git add";
          reseti = "!git status -u --porcelain | fzf -m | cut -c 3- | xargs git run git reset --";
          restorei = "!git status -u --porcelain | fzf -m | cut -c 3- | xargs git run git restore --";

          files = ''!git --no-pager show --format="" --name-status'';
          files-ls = ''!git --no-pager show --format="" --name-only'';
          conflicts = "!git --no-pager diff --name-status --diff-filter=U";
          conflicts-ls = "!git --no-pager diff --name-only --diff-filter=U";

          ctx = ''!git-utils git-ctx -q "ctx/"'';
          addu = "!git-utils git-checked-add-update";
          browse = "!git-utils git-browse";
          review = "!frk";

          arc-upload = ''!arc diff "HEAD~1"'';
          arc-draft = "arc-upload --only";
          arc-lint = "!arc lint --rev HEAD~1 --trace --apply-patches";
          arc-unit = "!arc unit --rev HEAD~1 --trace";

          farc-push = "!farc upload HEAD~1..HEAD";
          farc-edit = "!git notes --ref refs/notes/farc edit";

          q = "!stg";
          qinit = "!stg init";
          qsd = "!stg sd";
          qls = "!stg series";
          qseries = "!stg series";
          qapplied = "!stg series -A";
          qnew = "!stg new";
          qrefresh = "!stg refresh";
          qedit = "!stg edit";
          qrename = "!stg rename";
          qpush = "!stg push";
          qpop = "!stg pop";
          qgoto = "!stg goto";
        };

        "stgit.alias" = {
          rf = "!stg refresh";
          rfs = "!stg refresh --spill";
          spill = "stg refresh --spill";

          l = "!stg series -d --short=5";
          s = "!env GIT_PAGER=cat stg show";
          e = "!stg edit";
          ed = "!stg edit --diff";
          ls = "!stg series --noprefix";
          lg = "!stg series -d";
          lgf = "!stg series -d";
          lga = "!stg series -d -A";
          lgr = "!stg series -d --color=always | tac";
          lgs = "!(stg series -AP && (stg series -UP | head -n 4)) | xargs stg lg";

          patch = "!stg edit --diff --save-template -";
          patch-path = "!stg-utils files";
          pp = "!stg-utils files";

          t = "!stg-utils patch-info";
          pn = "!stg-utils patch-new";
          pi = "!stg-utils push-interactive";
          rc = "refresh --checked";
          rci = "refresh --checked --index";
          rcu = "refresh --checked --update";
          check = "!stg-utils check-index";
          spilli = "!stg-utils spill-interactive";

          replace = "!stg pop -a && stg push";
          pushm = "!stg-utils push-set";
          mpush = "!stg-utils push-set";
          tig = "!git-utils stg-tig";
          rstash = "!git-utils stg-rstash";
        };
      }
    ];
  };
}
