{ ... }:

{
  # Template aliases are jj's display/config language. Most of these are small
  # helpers used by the custom log template and push bookmark naming.
  programs.jujutsu.settings = {
    template-aliases = {
      "hlp_is_self(sig)" = ''stringify(sig.email()).lower() == config("user.email").as_string().lower()'';
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
