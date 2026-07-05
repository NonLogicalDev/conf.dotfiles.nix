[
  # Text and parsing behavior carried from the old interactive shell. These are
  # kept as named zsh options so Home Manager emits normal `setopt` calls.
  "COMBINING_CHARS"
  "INTERACTIVE_COMMENTS"
  "RC_QUOTES"
  "NO_MAIL_WARNING"

  # Keep zsh's spelling correction enabled, but avoid noisy mail checks.
  "CORRECT"

  # Job-control defaults for long-running terminal work.
  "LONG_LIST_JOBS"
  "AUTO_RESUME"
  "NOTIFY"
  "NO_BG_NICE"
  "NO_HUP"
  "NO_CHECK_JOBS"

  # Completion behavior. The detailed zstyle policy lives in
  # `lib/init-completion-styles.zsh`; these are the coarse zsh options.
  "COMPLETE_IN_WORD"
  "ALWAYS_TO_END"
  "PATH_DIRS"
  "AUTO_MENU"
  "AUTO_LIST"
  "AUTO_PARAM_SLASH"
  "EXTENDED_GLOB"
  "NO_MENU_COMPLETE"
  "NO_FLOW_CONTROL"

  # Directory navigation conveniences.
  "AUTO_CD"
  "AUTO_PUSHD"
  "PUSHD_IGNORE_DUPS"

  # History and globbing preferences. `INC_APPEND_HISTORY` complements the
  # Home Manager history settings in `shell-zsh/default.nix`.
  "INC_APPEND_HISTORY"
  "NO_NOMATCH"
  "IGNORE_EOF"

  # Allow the prompt theme to use prompt substitutions.
  "PROMPT_SUBST"
]
