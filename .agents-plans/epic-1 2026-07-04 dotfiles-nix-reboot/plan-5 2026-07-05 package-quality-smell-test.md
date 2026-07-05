---
date: 2026-07-05
status: complete
subject: package-quality-smell-test
---

# Package Quality Smell Test

## Goal

Meticulously review package derivations, package-like Home Manager integrations, and package-consuming suite modules so the repository passes a strict Nix maintainer smell test before more migration layers are built on top.

## Context

The repository uses `numtide/blueprint` directly and keeps buildable artifacts under `packages/`, low-level Home Manager integrations under `modules/home/pkg<Name>`, and reusable suites under `modules/home/suite<Name>`. The current package surface is small, but the boundary matters because later work will reuse these patterns across macOS and Linux.

Target surfaces for this pass:

- `packages/opn/default.nix`, including how Blueprint exposes and checks the package.
- `modules/home/pkgUnmanagedBash.nix`, `modules/home/pkgUnmanagedGit.nix`, and `modules/home/pkgUnmanagedZsh.nix`.
- `modules/home/suiteDeveloperBase/**`, including Atuin, Git, Jujutsu, shell, tmux, Neovim, and extracted Jujutsu Bash snippets.
- Any repo-local helper functions used by those files.

The review should be adversarial. A future Nix or Home Manager maintainer should not see avoidable surprises such as brittle string escaping, unclear ownership, platform-hostile assumptions, unnecessary abstraction, weak package metadata, untracked runtime dependencies, or comments that hide a simpler design.

## Decisions

- Use fresh read-only review agents for disjoint surfaces so the critique is not only the implementing agent defending prior choices.
- Treat subagent reports as evidence, not proof. The main thread still owns integration decisions, code edits, final validation, and checkpointing.
- Prefer small fixes with direct quality impact over broad rearrangement. This pass is a smell-test hardening pass, not a redesign of the suite.
- Keep behavior stable unless a review finding exposes a bug or a clearly inferior Nix pattern.
- A clean-system reusable suite should not expose aliases that call unpackaged custom helpers such as `git-utils`, `stg-utils`, `arc`, `farc`, or `frk`. Those workflows can return later as packaged tools or host-local config, but comments are not enough to make broken aliases acceptable.
- StGit itself is part of the intended Git workflow and is now an explicit dependency of the Git suite. Incidental helper commands used by aliases, such as GNU `tac`, should be referenced by store path instead of assuming Darwin provides them.
- `opn` is a local flake package rather than a nixpkgs submission. It should still have usable metadata and nixpkgs-style executable lookup, but this pass does not force a repository license decision.

## Implementation Steps

1. [x] Create the self-contained package quality plan.
2. [x] Run fresh subagent reviews for package derivations, low-level Home Manager package integrations, and suite modules.
3. [x] Integrate review findings into a concrete fix list.
4. [x] Apply focused fixes for accepted findings.
5. [x] Run formatting, script syntax checks, package builds, Home Manager activation build, synthetic Linux evaluation when relevant, and `nix flake check`.
6. [x] Checkpoint the verified quality pass.

## Learning Log

- Unmanaged zsh must maintain the files zsh actually reads. When `programs.zsh.dotDir` is set, only `~/.zshenv` stays top-level; later startup files live under `$ZDOTDIR`.
- `.profile` is not necessarily sourced by Bash, so its unmanaged dispatcher must be POSIX-safe rather than using `local` or `shopt`.
- Managed mutable blocks must not write through arbitrary symlinks. A prior Home Manager `/nix/store` symlink can be replaced with a regular mutable copy, but other symlinks should fail loudly.
- Jujutsu's `immutable_heads()` customization belongs under `revset-aliases`, not `snapshot`.
- Reusable Linux/macOS suites must not set false platform hints. `PLATFORM=MAC` is Darwin-only until the legacy scripts that depend on it are audited.
- Neovim commands that pass user text to external tools should use argv-style calls, not concatenated shell strings.

## Work Log

- [x] 2026-07-05 15:33 - Created this plan and dispatched fresh read-only review agents for derivations, low-level Home Manager integrations, and developer-suite modules.
- [x] 2026-07-05 15:42 - Integrated first-round findings: unmanaged shell bridge fixes, managed-block symlink safety, `opn` package polish, Jujutsu revset and send fixes, platform gating, Neovim argv commands, explicit StGit/DNS dependencies, Darwin-only Dash/cdf handling, and removal of unpackaged custom Git helper aliases.
- [x] 2026-07-05 15:46 - Ran a second adversarial diff review and fixed the remaining clean-system dependency issue by pinning StGit's `lgr` alias to GNU `tac` from `coreutils`.
- [x] 2026-07-05 15:49 - Verified formatting, script syntax, Lua parsing, `opn` build and metadata, Home Manager activation build, synthetic Linux invariants, cross-system no-build evaluation, and full `nix flake check`.

## Unfinished Work

N/A
