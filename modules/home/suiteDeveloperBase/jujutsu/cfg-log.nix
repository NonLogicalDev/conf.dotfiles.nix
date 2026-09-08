{ lib, pkgs, ... }:

let
  inherit (import ./lib { inherit lib pkgs; }) jjAliasBashFile;
in

{
  # Log aliases and templates are split out because they are the most personal
  # part of the jj UI. They define how everyday graph output reads at a glance.
  programs.jujutsu.settings = {
    ui.ts-rel = false;

    aliases = {
      # Compact personal log: small stack-oriented graph around the current
      # change, using the custom template below.
      l = [
        "log"
        "-T"
        "my_log_compact"
        "--config"
        "revsets.log=rlog"
      ];

      # Fuller current-branch log for when the compact template hides too much.
      ll = [
        "log"
        "--config"
        "revsets.log=::@"
      ];

      # Broader local-stack log: ancestors from trunk plus nearby descendants.
      # This is the default mental model for "where am I in this stack?"
      lg = [
        "log"
        "-n"
        "10"
        "--config"
        "revsets.log=ancestors(trunk()..@, 2) | descendants(@, 3) | @"
      ];

      # Show only the current stack and its immediate ancestors from trunk.
      tlog = [
        "log"
        "-r"
        "ancestors(trunk()..@, 2)"
      ];

      # Show the first bookmark reachable from the current change. Useful for
      # scripts or prompts that want one branch-ish name without full log noise.
      bm = jjAliasBashFile { file = ./lib/aliases/bm.bash; };

      # Show all bookmarks reachable from the current change. This is the
      # explicit version of `bm` when multiple labels may matter.
      bma = jjAliasBashFile { file = ./lib/aliases/bma.bash; };

      # Bookmark overview for bookmarks owned by this identity. Includes root so
      # the graph has a stable anchor even when bookmarks are disconnected.
      bl = [
        "log"
        "-T"
        "if(!root, my_log_compact)"
        "-r"
        "root() | ((bookmarks() | remote_bookmarks()) & mine())"
      ];
    };

    template-aliases = {
      # `my_*` names are intentionally namespaced so they do not collide with jj
      # built-ins or future upstream templates.
      "my_muted(tpl)" = ''label("muted", tpl)'';

      # Label calculation is separated from rendering so the compact log can
      # style working-copy, immutable, mutable, and conflicted commits together.
      "my_log_commit_label(commit)" = ''
        separate(" ",
          if(commit.current_working_copy(), "working_copy"),
          if(commit.immutable(), "immutable", "mutable"),
          if(commit.conflict(), "conflicted"),
        )
      '';

      # Sigils keep the graph scannable: @ for working copy, a chess-rook-ish
      # marker for commits on the first-parent path to @, dash otherwise.
      "my_log_commit_sigils(commit)" = ''
        concat(
          coalesce(
            if(commit.current_working_copy(), label("working_copy", "@")),
            if(commit.contained_in('first_parent(@)'), label("git_head", "♜")),
            my_muted("-"),
          ),
        )
      '';

      # Author display intentionally collapses the current configured identity
      # to <self>; other authors keep a short email-local label.
      "my_format_author_short(commit)" = ''
        if(commit.mine(),
          label("author self", "<self>"),
          label("author other", concat("<", coalesce(commit.author().email().local(), email_placeholder), ">")),
        )
      '';

      "my_format_change_id(change_id)" = "format_short_change_id_with_change_offset(change_id)";
      "my_format_commit_id(commit_id)" = ''concat("[", commit_id.shortest(8), "]")'';
      "my_format_description(description)" = ''
        if(description,
          description.first_line(),
          description_placeholder,
        )
      '';

      "my_format_relative_short(timestamp)" = ''
        timestamp.ago()
          .replace(" ago", "")
          .replace(" days", "d")
          .replace(" day", "d")
          .replace(" hours", "h")
          .replace(" hour", "h")
          .replace(" minutes", "m")
          .replace(" minute", "m")
          .replace(" seconds", "s")
          .replace(" second", "s")
          .replace(" just now", "now")
      '';

      # Keep bookmark/tag rendering out of the main header so long labels do not
      # crowd out change id, commit id, author, age, and description.
      "my_format_bookmarks(bookmarks)" =
        ''if(bookmarks.len() > 0, concat("(B: ", bookmarks.join(", "), ")"))'';
      "my_format_tags(tags)" = ''if(tags.len() > 0, concat("(T: ", tags.join(", "), ")"))'';

      "my_log_commit_header(commit)" = ''
        truncate_end(120, separate(" ",
          my_format_change_id(commit),
          my_format_commit_id(commit.commit_id()),
          "-",
          my_format_author_short(commit),
          my_format_relative_short(commit_timestamp(commit)),
          commit.working_copies(),
          if(config("ui.show-cryptographic-signatures").as_boolean(),
            format_short_cryptographic_signature(commit.signature())
          ),
          my_muted("#"),
          label(
            separate(" ",
              if(commit.current_working_copy(), "working_copy"),
              if(commit.immutable(), "immutable", "mutable"),
              if(commit.conflict(), "conflicted"),
            ),
            separate(" ",
              if(commit.conflict(), label("conflict", "{conflict}")),
              if(commit.empty(), label("empty", "∅")),
              my_format_description(commit.description()),
            ),
          ),
        ), "...")
      '';

      # This is the actual compact log line used by `jj l`. It trades full
      # metadata for a stable one-screen review surface.
      my_log_compact = "my_log_compact(self)";
      "my_log_compact(commit)" = ''
        if(commit.root(),
          my_muted("{root}"),
          label(my_log_commit_label(commit),
            separate("\n   ",
              separate(" ",
                my_log_commit_sigils(commit),
                my_log_commit_header(commit),
              ),
              separate(" ", my_format_bookmarks(commit.bookmarks()), my_format_tags(commit.tags())),
            )
          )
        ) ++ "\n"
      '';
    };
  };
}
