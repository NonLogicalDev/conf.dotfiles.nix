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
- Migrate Atuin first. Its Dotter config is mostly generated comments plus a small set of real preferences, so `programs.atuin.settings` can convey the actual behavior without copying the full TOML file.
- Let Atuin own shell history search on Ctrl-R. Keep `programs.fzf` enabled, but set `programs.fzf.historyWidget.command = ""` so fzf does not compete with Atuin's zsh integration.
- Defer Atuin fish integration until the fish slice. The old fish Dotter file only ran `atuin init fish`, but this repo has not yet decided whether Home Manager should own fish as a secondary shell.
- Keep the Atuin slice focused on client behavior. Local service/dev helpers such as `Justfile` and `compose.yml` are not migrated into Home Manager unless a later system/service slice intentionally owns the Atuin server.
- Expose Atuin local server control through the Atuin Home Manager profile, not `packages/`. `atuin-server-up` and `atuin-server-down` carry the useful behavior of the old Compose/Justfile setup while keeping operational defaults overridable through environment variables. The top-level `packages/` tree is reserved for reusable tools.

## Implementation Steps

1. [x] Inventory live Dotter-managed files and current home targets for the in-scope topics: `bin`, `git/bin`, `tmux`, `vifm`, `jj`, `atuin`, and `fish`.
2. [x] Classify each topic as Home Manager-native config, package derivation, small companion file, or deferred/no-longer-needed.
3. [x] Migrate one low-risk app profile at a time under `hosts/nonlogicals-mbp/users/nonlogical/home/<program>/`.
4. [ ] Convert selected reusable helper scripts into Blueprint packages only after their runtime dependencies and current usefulness are understood.
5. [ ] Wire accepted app profiles through `hosts/nonlogicals-mbp/users/nonlogical/home-configuration.nix` without adding broad common package lists.
6. [x] Build the Home Manager activation package after each meaningful slice and run `nix flake check` before considering the plan complete.
7. [ ] Update this plan's learning log with each app-specific ownership decision.

## Learning Log

- Dotter's `common` tree uses recursive linking and topic directories; this migration should use those files as evidence rather than preserving their folder layout.
- The non-editor, non-terminal scope still contains multiple categories: app config, shell compatibility, helper scripts, Git helper commands, and local service files.
- `common/git/bin` is separate from durable Git settings. It should be evaluated as a command-package migration, not folded back into the completed Git config plan.
- Home Manager has native modules for `tmux`, `programs.jujutsu`, `programs.atuin`, `programs.vifm`, and `programs.fish`. Script directories under `common/bin` and `common/git/bin` still need command-by-command dependency review before becoming Blueprint packages.
- `tmux` is not the safest first slice because Home Manager writes XDG `~/.config/tmux/tmux.conf`, while the live Dotter setup also owns top-level `~/.tmux.conf`. That migration needs an explicit precedence/cleanup decision.
- `jj` has a native Home Manager module, but the current Dotter `conf.d` contains long custom command aliases and templates. It should be migrated deliberately as a Jujutsu config slice, not as the first low-risk app.
- Atuin's durable client settings are compact: local sync server URL, session-scoped up-key filter mode, return-query escape behavior, `enter_accept = false`, stats grouping, `sudo` prefix stripping, and sync-v2 records. Home Manager renders these cleanly into generated TOML.
- The Atuin local server `Justfile` and `compose.yml` are not client settings. They are excluded from this Home Manager slice; the essential client behavior is the local `sync_address`.
- Enabling Atuin zsh integration while fzf zsh integration is enabled requires disabling fzf's Ctrl-R history widget. Home Manager documents `programs.fzf.historyWidget.command = ""` as the supported way to yield Ctrl-R to Atuin.
- The Atuin server helper does not belong under `packages/` because it is host-user operational glue, not a reusable program. It lives inline in `home/atuin/default.nix`, produces real `atuin-server-up` and `atuin-server-down` commands, and keeps mutable operational values configurable with `ATUIN_SERVER_*` environment variables.

## Work Log

- [x] 2026-07-05 00:39 - Created plan 3 after inventorying `/Users/nonlogical/.config/dotter/common` and defining the non-editor, non-GUI-terminal scope.
- [x] 2026-07-05 00:53 - Inventoried live targets for the in-scope Dotter topics, chose Atuin as the first low-risk app migration, added `home/atuin`, disabled fzf's Ctrl-R widget in favor of Atuin, and verified the Home Manager activation build.
- [x] 2026-07-05 00:54 - Verified the Atuin slice with `nix flake check`.
- [x] 2026-07-05 00:58 - Trimmed Atuin migration to client behavior only by dropping the local `Justfile` and `compose.yml` helper files from Home Manager ownership.
- [x] 2026-07-05 01:00 - Added `atuin-server-up` and `atuin-server-down` as host-user Home Manager helper commands instead of reusable Blueprint packages.
- [x] 2026-07-05 01:08 - Verified generated `atuin-server-up` and `atuin-server-down` with `bash -n`, confirmed only Atuin client TOML is installed under `.config/atuin`, and reran `nix flake check`.

## Unfinished Work

- [ ] Decide whether the next app slice should be `tmux`, `jj`, `vifm`, or script packaging.
- [ ] Review `common/bin` and `common/git/bin` helper scripts command by command before converting any into Blueprint packages.
