{
  # StGit aliases are namespaced under Git's `stgit.alias` config. They are for
  # patch-stack workflows where a branch is treated as an editable queue rather
  # than a sequence of immutable commits.
  #
  # Refresh aliases are the core loop: update the current patch from the index
  # or working tree, optionally spilling unrelated edits back out.
  rf = "!stg refresh";
  rfs = "!stg refresh --spill";
  spill = "stg refresh --spill";

  # Compact stack views and patch editing helpers. `lgs` shows applied patches
  # plus a short preview of unapplied patches so the queue shape is visible.
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

  # Custom stg-utils helpers still live outside this Nix repo. Keep these
  # aliases documented so a future packaging pass knows which commands matter.
  t = "!stg-utils patch-info";
  pn = "!stg-utils patch-new";
  pi = "!stg-utils push-interactive";
  rc = "refresh --checked";
  rci = "refresh --checked --index";
  rcu = "refresh --checked --update";
  check = "!stg-utils check-index";
  spilli = "!stg-utils spill-interactive";

  # Stack movement and bridge helpers. `replace` rebuilds the applied stack by
  # popping everything and pushing again; use it when queue order got stale.
  replace = "!stg pop -a && stg push";
  pushm = "!stg-utils push-set";
  mpush = "!stg-utils push-set";
  tig = "!git-utils stg-tig";
  rstash = "!git-utils stg-rstash";
}
