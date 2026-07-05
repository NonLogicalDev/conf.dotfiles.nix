---
date: 2026-07-05
status: in-progress
subject: ingest-dotter-common-packages
---

# Ingest Dotter Common Packages

## Goal

Ingest the next set of non-editor, non-GUI-terminal configuration and helper packages from `/Users/nonlogical/.config/dotter/common` into the Nix dotfiles repo.

This plan is for a careful package/app onboarding pass after the Git and zsh migrations. The goal is not to copy Dotter's directory structure into Nix. Dotter files are behavioral source material. The target shape should be idiomatic Home Manager modules, small host-user app profiles, and real Blueprint packages where scripts or binaries need to become managed commands.

## Context

The current Dotter common tree contains several topic directories that are already out of scope because they are editors, editor-adjacent, or GUI terminal profiles:

- Excluded editors: `vim`, `nvim`, and `vscode`.
- Excluded GUI terminals: `alacritty`, `wezterm`, and `ghostty`.
- Already handled by earlier plans: durable Git configuration under `common/git/.config/git/` and zsh startup behavior under `common/zsh/`.

The remaining common topics worth inventorying in this slice are:

- `bin/`: generic user commands such as `dstat`, `steam-wine`, `steam-wine-sh`, and `gman`.
- `git/bin/`: Git and StGit helper commands such as `git-summary`, `git-snap`, `git-squash`, `git-rstash`, `stg-fixup`, and related utilities.
- `tmux/`: tmux config and startup hook material.
- `vifm/`: Vifm config, colors, and helper scripts.
- `jj/`: Jujutsu config fragments under `.config/jj/`.
- `atuin/`: Atuin config plus local service/dev files such as `Justfile` and `compose.yml`.
- `fish/`: Fish shell conf.d material, to be reviewed as a possible secondary-shell compatibility slice rather than assumed active shell policy.

This repository already uses the host-user convention `hosts/nonlogicals-mbp/users/nonlogical/home/<program>/default.nix` for app-specific Home Manager configuration and `packages/<name>/default.nix` for Blueprint-exposed derivations such as `opn`.

## Product Integration

- Existing product model: host-user app behavior lives under `hosts/nonlogicals-mbp/users/nonlogical/home/`, reusable modules live under `modules/home/`, and buildable commands/packages live under `packages/`.
- New requirement's real intent: move more useful Dotter-managed command-line behavior into Nix without dragging editor and terminal migrations into this step.
- Cleanest integrated model: each app gets a focused host-user Home Manager profile when Home Manager can express it; each standalone script or command becomes a small package only when it is actually worth managing as an executable; copied config files are a fallback, not the default.
- Existing pieces that should move, change, or disappear: Dotter topic boundaries should not become permanent Nix boundaries when Home Manager has a better model. Legacy scripts should be reviewed for current usefulness before being packaged.
- Architecture impact: this plan may add new `home/<program>/` directories, new package derivations, and imports in `home-configuration.nix`, but it should not add common package bundles to `modules/home/core.nix`.
- Why this is better than a local patch: it prevents the migration from becoming a bulk symlink replacement and keeps every newly managed tool accountable to a Home Manager or package ownership boundary.

## Decisions

- Exclude `vim`, `nvim`, `vscode`, `alacritty`, `wezterm`, and `ghostty` from this plan even if inventory discovers small reusable snippets in those folders.
- Do not reopen the completed zsh and Git config migrations unless a helper command directly depends on them.
- Treat `common/git/bin` as helper-command source material, not Git configuration. Durable Git settings stay owned by the completed Git plan.
- Prefer Home Manager native options for `tmux`, `jj`, `atuin`, `fish`, and `vifm` if the available module support is good enough.
- Package scripts only after reading their dependencies and current value. A stale script should be deferred or removed from scope instead of being made official by Nix.
- Keep this migration host-user scoped first. Promote reusable suites or modules only after the same pattern appears more than once.

## Implementation Steps

1. [ ] Inventory live Dotter-managed files and current home targets for the in-scope topics: `bin`, `git/bin`, `tmux`, `vifm`, `jj`, `atuin`, and `fish`.
2. [ ] Classify each topic as Home Manager-native config, package derivation, small companion file, or deferred/no-longer-needed.
3. [ ] Migrate one low-risk app profile at a time under `hosts/nonlogicals-mbp/users/nonlogical/home/<program>/`.
4. [ ] Convert selected helper scripts into Blueprint packages only after their runtime dependencies and current usefulness are understood.
5. [ ] Wire accepted app profiles through `hosts/nonlogicals-mbp/users/nonlogical/home-configuration.nix` without adding broad common package lists.
6. [ ] Build the Home Manager activation package after each meaningful slice and run `nix flake check` before considering the plan complete.
7. [ ] Update this plan's learning log with each app-specific ownership decision.

## Learning Log

- Dotter's `common` tree uses recursive linking and topic directories; this migration should use those files as evidence rather than preserving their folder layout.
- The non-editor, non-terminal scope still contains multiple categories: app config, shell compatibility, helper scripts, Git helper commands, and local service files.
- `common/git/bin` is separate from durable Git settings. It should be evaluated as a command-package migration, not folded back into the completed Git config plan.

## Work Log

- [x] 2026-07-05 00:39 - Created plan 3 after inventorying `/Users/nonlogical/.config/dotter/common` and defining the non-editor, non-GUI-terminal scope.

## Unfinished Work

- [ ] Inventory in-scope Dotter topics and current live home targets before migrating any files.
- [ ] Decide the first low-risk app or script package to migrate.
- [ ] Run Home Manager build and `nix flake check` after the first implementation slice.
