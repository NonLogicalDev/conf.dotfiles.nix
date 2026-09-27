# Developer commands

This package owns the 18 previously deployed user commands. Source lives in `src/`; Nix supplies interpreters and command-line dependencies and installs wrappers into the profile's `bin`. The scripts retain their existing algorithms and command names, except for the confirmation fix described below. Git discovers `git-*` helpers through PATH.

## Commands

- Git: `git-commit-stat`, `git-ls-index`, `git-rstash`, `git-snap`, `git-split`, `git-squash`, `git-summary`, `git-utils`.
- StGit: `stg-fixup`, `stg-fixup.new`, `stg-repair-top`, `stg-rfpi`, `stg-utils`.
- Other tools: `arc-fix`, `dstat`, `gman`, `steam-wine`, `steam-wine-sh`.

## External dependencies

- `gman` uses macOS `/usr/bin/man`, `/usr/bin/open`, and Preview. It is retained in the package on Linux for command-name compatibility, but requires macOS to work.
- Steam helpers expect an existing Steam library and compatible Proton or Wine installation. Nix does not install games, Wine, or Proton. The defaults and Proton environment target Linux; availability on macOS does not establish that Windows games can run there. `ps` comes from macOS or from `procps` on Linux.
- `arc-fix` expects the repository's existing `arc` (Arcanist) installation on PATH. It accepts lint patches and therefore modifies files.
- Some Git/StGit utility functions call user Git aliases (`git root`, `git run`, `git lg`). Home Manager's Git configuration owns these aliases separately. `git-utils stg-overview` also expects a `stg-branches` command that was absent from the deployed helper set.

## Preserved limitations

These are existing personal scripts, not general-purpose safe interfaces. Syntax checks and selected help entrypoints establish packaging, not correctness of history edits or compatibility with every Git/StGit version.

- `git-rstash` force-pushes and invokes a push when called without arguments. Never use a blanket no-argument smoke test for this package.
- `git-squash`, `git-split`, `git-snap`, and the StGit repair helpers change refs, indexes, worktrees, or output files. StGit fixups directly edit stack metadata. `stg-rfpi` overwrites `~/Desktop/patchname.txt`; preserve that file before use.
- Several scripts split or interpolate arguments into shell commands, including `dstat` and `gman`; filenames and arguments containing spaces or shell syntax are not uniformly handled.
- `git-ls-index` implements a limited index parser. Steam listing and execution retain their existing error behavior when no games or usable Proton install are found. `steam-wine-sh` retains its existing Proton-output parsing and environment assumptions.

## Confirmation fix

`stg-utils push-interactive` now returns when its confirmation is declined or cancelled. Previously it printed cancellation and still invoked `stg push`. An isolated test supplies fake `gum` and `stg` commands and verifies that declined or cancelled confirmation leaves the push log empty, while acceptance invokes the selected push. No real repository or interactive program is used.

## Verification

The derivation checks Bash/Zsh/Ruby syntax and parses Python source, then invokes only the help entrypoints that have been inspected for side effects. Git and StGit mutation commands are not executed during a build. Wrappers preserve access to the real source path because several help commands extract comments from `$0`.
