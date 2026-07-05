{ ... }:

let
  inherit (import ./lib) jjAliasBashFile;
in

{
  # These aliases are user workflow, not reusable command packages. Keeping them
  # in jujutsu config preserves `jj <alias>` muscle memory while Home Manager
  # still owns the rendered TOML.
  programs.jujutsu.settings.aliases = {
    # Tiny namespace shorthands for commands that are frequent but verbose.
    wt = [ "workspace" ];
    ws = [ "workspace" ];
    f = [ "file" ];

    # Print the JJ change id for a rev. This is the stable review/discussion
    # handle in JJ, distinct from the Git commit sha.
    id = jjAliasBashFile { file = ./lib/aliases/id.bash; };

    # Print the backing Git commit id for a rev. Useful when crossing the JJ/Git
    # boundary for pushes, GitHub links, or external tooling.
    sha = jjAliasBashFile { file = ./lib/aliases/sha.bash; };

    # Move the nearest bookmark forward to the closest non-empty pushable change.
    # This is the common "advance my branch pointer after editing a stack" move.
    tug = [
      "bookmark"
      "move"
      "--from"
      "closest_bookmark(@)"
      "--to"
      "closest_pushable(@)"
    ];

    # Diff formatter toggles. The default profile uses Git-style diffs; these
    # aliases make it cheap to switch between Git compatibility and JJ words.
    diff-git = [
      "diff"
      "--config"
      "ui.diff-formatter=:git"
    ];
    diff-jj = [
      "diff"
      "--config"
      "ui.diff-formatter=:color-words"
    ];

    # Compare the current change to the fork point with a named bookmark. This
    # answers "what is my branch doing relative to that bookmark?"
    diff-to = jjAliasBashFile {
      file = ./lib/aliases/diff-to.bash;
      shellArg0 = "--";
    };

    # Compare the fork-point-to-bookmark range between two bookmarks. This is
    # for branch/review archaeology when two named stacks diverged.
    diff-bw = jjAliasBashFile {
      file = ./lib/aliases/diff-bw.bash;
      shellArg0 = "---";
    };

    # Push a JJ change to Git using either an existing bookmark or a generated
    # change-id branch. This keeps review publishing explicit and avoids
    # accidentally pushing every local bookmark.
    send = jjAliasBashFile { file = ./lib/aliases/send.bash; };

    # Interactive wrapper around `send` for the common case where the target
    # bookmark should be selected from current local bookmarks.
    sendi = jjAliasBashFile { file = ./lib/aliases/sendi.bash; };

    # Divergent-change triage helper. JJ can have multiple commits for one
    # change id; this checks whether the divergent commits actually differ and
    # prints the repair command when they do not.
    "fix-div" = jjAliasBashFile { file = ./lib/aliases/fix-div.bash; };

    # Delete or forget a local/remote bookmark. The name is intentionally loud
    # because it removes references, not changes.
    begone = jjAliasBashFile { file = ./lib/aliases/begone.bash; };

    # Squash the current branch stack back into the nearest bookmark while
    # preserving the destination message. Useful after a series of small fixups.
    sqb = jjAliasBashFile { file = ./lib/aliases/sqb.bash; };

    # Squash the current change into its parent. This is the one-change version
    # of `sqb` for immediate local cleanup.
    sqp = jjAliasBashFile { file = ./lib/aliases/sqp.bash; };

    # Create a short random bookmark on a chosen change. This is a lightweight
    # way to mark a useful point in a stack without inventing a polished branch
    # name before the work deserves one.
    mark = jjAliasBashFile { file = ./lib/aliases/mark.bash; };
  };
}
