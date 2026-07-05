{
  config,
  pkgs,
  ...
}:

let
  # The suite derives personal bookmark namespaces from a neutral SCM slug.
  # This keeps immutable bookmark policy reusable across machines/users while
  # still protecting the current user's remote namespace by default.
  cfg = config.dotfiles.suites.developerBase;
  personalBookmarkGlob = "${cfg.scmIdentity.slug}/*";
  immutableBookmarkRevset = "builtin_immutable_heads() | (bookmarks(glob:'${personalBookmarkGlob}'))";
in

{
  # Keep JJ subdomains split by purpose. The main module owns identity, UI,
  # colors, and revsets; sibling files own aliases, log formatting, and
  # templates because those maps are dense enough to deserve focused comments.
  imports = [
    ./cfg-aliases.nix
    ./cfg-log.nix
    ./cfg-templates.nix
  ];

  # Jujutsu has a native Home Manager module that generates
  # `$XDG_CONFIG_HOME/jj/config.toml`. Keep the durable config there instead of
  # preserving the old Dotter `conf.d` split as the target shape.
  programs.jujutsu = {
    enable = true;

    settings = {
      user = {
        name = cfg.scmIdentity.name;
        email = cfg.scmIdentity.email;
      };

      ui = {
        # Make `jj` open the small personal log by default.
        default-command = [ "lg" ];

        # Keep diffs familiar to Git users and leave interactive editors to jj's
        # built-in tools until a dedicated merge-tool slice says otherwise.
        diff-formatter = ":git";
        conflict-marker-style = "git";
        pager = ":builtin";
        diff-editor = ":builtin";
        merge-editor = ":builtin";
      };

      colors = {
        muted = {
          fg = "black";
        };

        empty = {
          fg = "red";
        };
        "description placeholder" = {
          fg = "red";
        };
        "empty description placeholder" = {
          fg = "red";
        };
        "working_copy empty" = {
          fg = "red";
        };
        "working_copy empty description placeholder" = {
          fg = "red";
        };

        "author self" = {
          fg = "green";
          underline = true;
        };
        "author other" = {
          fg = "bright blue";
        };

        "diff removed token" = {
          underline = false;
        };
        "diff added token" = {
          underline = false;
        };

        bookmark = {
          fg = "bright yellow";
        };
        bookmarks = {
          fg = "bright yellow";
        };
        tag = {
          fg = "bright yellow";
        };
        tags = {
          fg = "bright yellow";
        };
      };

      git = {
        # Do not push local scratch changes that are intentionally marked private.
        private-commits = "description(glob:'private:*')";
      };

      snapshot = {
        # This profile favors jj seeing the whole working tree by default.
        auto-track = "all()";
      };

      revset-aliases = {
        # Keep personal remote bookmark namespaces immutable by default.
        "immutable_heads()" = immutableBookmarkRevset;
        "closest_bookmark(to)" = "heads(::to & bookmarks())";
        "closest_pushable(to)" = "heads(::to & ~description(exact:\"\") & (~empty() | merges()))";
        log = "present(@) | ancestors(immutable_heads().., 2) | present(trunk())";
        rlog = "ancestors(trunk()..@, 2) | descendants(@, 3) | @";
        hlog = "::@";
      };
    };
  };

  # Several jj aliases shell out to `jq`, `gum`, and Git. Keep those runtime
  # dependencies near the jujutsu profile instead of promoting them into a broad
  # common package list.
  home.packages = [
    pkgs.git
    pkgs.gum
    pkgs.jq
    pkgs.stgit
  ];
}
