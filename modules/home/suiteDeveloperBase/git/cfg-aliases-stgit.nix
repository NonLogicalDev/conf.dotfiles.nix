{
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
}
