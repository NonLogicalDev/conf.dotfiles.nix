{ ... }:

{
  # Template aliases are jj's display/config language. Most of these are small
  # helpers used by the custom log template and push bookmark naming.
  programs.jujutsu.settings = {
    template-aliases = {
      "hlp_is_self(sig)" = ''stringify(sig.email()).lower() == config("user.email").as_string().lower()'';

      # Preserve the original personal template names for existing jj commands.
      # Their implementations remain in the reusable my_ and hlp_ helpers.
      "nl_is_self(sig)" = "hlp_is_self(sig)";
      "nl_muted(tpl)" = "my_muted(tpl)";
      "nl_format_author_short(commit)" = "my_format_author_short(commit)";
      "nl_format_bookmarks(bookmarks)" = "my_format_bookmarks(bookmarks)";
      "nl_format_change_id(change_id)" = "my_format_change_id(change_id)";
      "nl_format_commit_id(commit_id)" = "my_format_commit_id(commit_id)";
      "nl_format_description(description)" = "my_format_description(description)";
      "nl_format_relative_short(timestamp)" = "my_format_relative_short(timestamp)";
      "nl_format_tags(tags)" = "my_format_tags(tags)";
      "nl_log_commit_header(commit)" = "my_log_commit_header(commit)";
      "nl_log_commit_label(commit)" = "my_log_commit_label(commit)";
      "nl_log_commit_sigils(commit)" = "my_log_commit_sigils(commit)";
      nl_log_compact = "my_log_compact";
      "nl_log_compact(commit)" = "my_log_compact(commit)";

      "format_short_id(id)" = "id.shortest(6)";
      "format_short_signature(signature)" = ''
        label(
          separate(" ",
            "author",
            if(hlp_is_self(signature), "self", "other"),
          ),
          concat("<", coalesce(signature.email().local(), email_placeholder), ">"),
        )
      '';
    };

    templates = {
      git_push_bookmark = ''
        separate("/",
          self.author().email().local(),
          "jj-change-id",
          self.change_id().shortest(6)
        )
      '';

      # Keep jj's built-in description prompt, but include the Git diff below
      # the ignore-rest marker for convenient commit-message drafting.
      draft_commit_description = ''
        concat(
          builtin_draft_commit_description,
          "\nJJ: ignore-rest\n",
          diff.git(),
        )
      '';
    };
  };
}
