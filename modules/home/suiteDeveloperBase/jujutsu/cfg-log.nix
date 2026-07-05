{ ... }:

{
  # Log aliases and templates are split out because they are the most personal
  # part of the jj UI. They define how everyday graph output reads at a glance.
  programs.jujutsu.settings = {
    ui.ts-rel = false;

    aliases = {
      l = [
        "log"
        "-T"
        "my_log_compact"
        "-n"
        "10"
        "--config"
        "revsets.log=rlog"
      ];

      ll = [
        "log"
        "-n"
        "10"
        "--config"
        "revsets.log=::@"
      ];

      lg = [
        "log"
        "-n"
        "10"
        "--config"
        "revsets.log=ancestors(trunk()..@, 2) | descendants(@, 3) | @"
      ];

      bm = [
        "util"
        "exec"
        "--"
        "bash"
        "-euo"
        "pipefail"
        "-c"
        ''
          jj --ignore-working-copy log \
            -n 1 -G \
            -r 'bookmarks() & ::@' \
            -T 'stringify(self.bookmarks().join("\n")).first_line() ++ "\n"'
        ''
        ""
      ];

      bma = [
        "util"
        "exec"
        "--"
        "bash"
        "-euo"
        "pipefail"
        "-c"
        ''
          jj --ignore-working-copy log \
            -n 1 -G \
            -r 'bookmarks() & ::@' \
            -T 'stringify(self.bookmarks().join("\n")) ++ "\n"'
        ''
        ""
      ];

      bl = [
        "log"
        "-n"
        "10"
        "-T"
        "if(!root, my_log_compact)"
        "-r"
        "root() | ((bookmarks() | remote_bookmarks()) & mine())"
      ];
    };

    template-aliases = {
      "my_muted(tpl)" = ''label("muted", tpl)'';

      "my_log_commit_label(commit)" = ''
        separate(" ",
          if(commit.current_working_copy(), "working_copy"),
          if(commit.immutable(), "immutable", "mutable"),
          if(commit.conflict(), "conflicted"),
        )
      '';

      "my_log_commit_sigils(commit)" = ''
        concat(
          coalesce(
            if(commit.current_working_copy(), label("working_copy", "@")),
            if(commit.contained_in('first_parent(@)'), label("git_head", "♜")),
            my_muted("-"),
          ),
        )
      '';

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
