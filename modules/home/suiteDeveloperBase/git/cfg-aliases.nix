{
  # Tiny muscle-memory shorthands. These are intentionally boring and mirror
  # common Git subcommands rather than inventing new behavior.
  s = "show";
  b = "branch";
  co = "checkout";
  sw = "switch";

  # Local-stack log views. Most of these focus on first-parent history because
  # the daily review habit is "what changed on my branch since upstream?"
  l = "!git log -n 10 --first-parent --pretty=nice-cons $(git upstream)..HEAD";
  lg = "log -n 10 --first-parent --pretty=nice";
  lgr = "lg --reverse";
  lgf = "log -n 10 --first-parent --pretty=nice-sep --name-status";
  lgg = "log -n 10 --graph --pretty=nice-cons";
  lgt = ''!git lg --pretty=nice-cols --color | column -t -s "::"'';
  lgu = "!git lg -n 100 $(git upstream)..HEAD";
  lguu = "!git lg -n 100 HEAD..$(git upstream)";

  # Pull/merge aliases encode the preferred safe defaults: rebase local work or
  # fast-forward only; do not accidentally create merge commits while syncing.
  pullr = "pull --rebase";
  pullff = "pull --ff-only";
  mergeff = "merge --ff-only";

  # Status and file-listing shortcuts are optimized for scripts and compact
  # terminal prompts, not for porcelain explanations.
  st = "status -s";
  stu = "status -su";
  ls = "ls-files --exclude-standard";
  stat = "!git --no-pager show --numstat --shortstat --format=";

  # Diff aliases keep cached/staged diff muscle memory available under several
  # names accumulated over time.
  d = "diff";
  dc = "diff --cached";
  diffc = "diff --cached";
  cdiff = "diff --cached";

  # Commit and rebase shorthands. `ca` is intentionally no-edit because the
  # common use is "fold this small fix into the current commit".
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

  # Submodule aliases are only update helpers; clone/init policy should stay in
  # project-specific docs, not global Git config.
  su = "submodule update";
  suc = "submodule update --checkout";

  # Assume-unchanged helpers are for noisy local files that should not appear
  # in every status. `ls-untracked` lists files currently hidden this way.
  ls-untracked = ''!git ls-files -v | grep "^[[:lower:]]" | perl -pe "s/^\\\\w+\\\\s+//"'';
  untrack = "update-index --assume-unchanged";
  track = "update-index --no-assume-unchanged";

  # Directory helpers make shell aliases/scripts independent of the current
  # subdirectory inside a repository.
  sum = "show --format=medium --stat";
  dir-root = "rev-parse --path-format=absolute --show-toplevel";
  root = "dir-root";
  dir-git = "rev-parse --path-format=absolute --git-dir";
  dir-db = "rev-parse --path-format=absolute --git-common-dir";

  # `upstream` is used by the log and rebase aliases above. It defaults to HEAD
  # but accepts another ref when a script needs to query a different branch.
  upstream = "!f() { git rev-parse --abbrev-ref \${1:-HEAD}@{upstream}; }; f";

  # Run commands from the repository root. This keeps fzf-selected paths and
  # helper scripts stable when invoked from nested directories.
  run = ''!f() { cd "`git root`"; "$@"; }; f'';

  # Legacy checkpoint muscle memory. The project-level agent instructions use a
  # newer ISO `checkpoint[...]` commit format, so do not treat this alias as the
  # canonical agent checkpoint implementation.
  checkpoint = ''!f() { git add -A && git commit -m "$(date) :: checkpoint''${1:+ :: $1}"; }; f'';
  save = "checkpoint";

  # Interactive staging/reset/restore. These deliberately use porcelain output
  # plus fzf instead of a larger TUI so they remain small and scriptable.
  addi = "!git status -u --porcelain | fzf -m | cut -c 3- | xargs git run git add";
  reseti = "!git status -u --porcelain | fzf -m | cut -c 3- | xargs git run git reset --";
  restorei = "!git status -u --porcelain | fzf -m | cut -c 3- | xargs git run git restore --";

  # Commit/file inspection helpers for review and conflict triage.
  files = ''!git --no-pager show --format="" --name-status'';
  files-ls = ''!git --no-pager show --format="" --name-only'';
  conflicts = "!git --no-pager diff --name-status --diff-filter=U";
  conflicts-ls = "!git --no-pager diff --name-only --diff-filter=U";

  # Project-local helper commands that still need a future packaging/inventory
  # pass. They are preserved as aliases because the current workflow expects
  # them, but they are not yet modeled as reusable Blueprint packages.
  ctx = ''!git-utils git-ctx -q "ctx/"'';
  addu = "!git-utils git-checked-add-update";
  browse = "!git-utils git-browse";
  review = "!frk";

  # Arcanist/Facebook Arcanist helpers retained for repositories that still use
  # Phabricator-style review flows.
  arc-upload = ''!arc diff "HEAD~1"'';
  arc-draft = "arc-upload --only";
  arc-lint = "!arc lint --rev HEAD~1 --trace --apply-patches";
  arc-unit = "!arc unit --rev HEAD~1 --trace";

  # `farc` is another review-upload helper family. Keep it isolated from the
  # normal Git aliases so it can be removed easily if no current repo uses it.
  farc-push = "!farc upload HEAD~1..HEAD";
  farc-edit = "!git notes --ref refs/notes/farc edit";

  # `q*` aliases are a personal compatibility layer over StGit. They make StGit
  # feel like an older patch-queue workflow without forcing StGit commands into
  # the shell namespace.
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
