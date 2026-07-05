{
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
}
