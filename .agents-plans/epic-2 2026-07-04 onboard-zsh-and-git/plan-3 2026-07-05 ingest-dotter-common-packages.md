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
- Assume the target Home Manager activation happens on a clean home for each migrated path. Existing Dotter symlinks and copied files are migration cleanup chores to record in this plan, not compatibility behavior to encode in Nix modules.
- Migrate Atuin first. Its Dotter config is mostly generated comments plus a small set of real preferences, so `programs.atuin.settings` can convey the actual behavior without copying the full TOML file.
- Let Atuin own shell history search on Ctrl-R. Keep `programs.fzf` enabled, but set `programs.fzf.historyWidget.command = ""` so fzf does not compete with Atuin's zsh integration.
- Enable Atuin fish integration in the shell slice. Fish is a secondary compatibility shell, but Home Manager can emit the native Atuin fish hook without preserving handwritten `conf.d` snippets.
- Replace the Docker-based Atuin server helper with a native Nix-managed Atuin server. Home Manager installs `atuin-server-up` and `atuin-server-down` as host-user helper commands that control the native per-user service manager: launchd on macOS and `systemd --user` on Linux. Both run `atuin server start` directly from the Nix Atuin package.
- Migrate tmux through Home Manager's native `programs.tmux` options plus one focused `extra.conf` file for status bar and keybinding behavior. Keep a top-level `.tmux.conf` bridge that sources the XDG config so ordinary tmux startup finds the Home Manager config.
- Migrate Jujutsu through Home Manager's native `programs.jujutsu.settings` as the source of truth for `~/.config/jj/config.toml`. Do not manage old `conf.d` tombstone files; on a clean target, no extra `conf.d` files should exist unless a future conditional-config slice intentionally creates them.
- Keep mutable Jujutsu repository metadata under `~/.config/jj/repos/` unmanaged. That directory is application state, not durable profile configuration.
- Keep `jq`, `gum`, and `git` as dependencies of the Jujutsu user profile because several migrated `jj` aliases shell out to them. Do not promote them into a broad common package list from this slice alone.

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
- The Atuin server helper does not belong under `packages/` because it is host-user operational glue, not a reusable program. It lives inline in `modules/home/suiteDeveloperBase/atuin/default.nix`, produces real `atuin-server-up` and `atuin-server-down` commands, and controls the platform-native user service running `atuin server start` directly from the Nix package.
- The Atuin service job should not hide meaningful behavior in a wrapper script. Launchd and systemd both run the Nix `atuin` executable directly, while Home Manager creates the mutable data directory with a marker file. macOS also gets a log directory because launchd writes stdout/stderr to files; Linux uses the user journal.
- The Nix-managed Atuin server uses `ATUIN_DB_URI=sqlite:///Users/nonlogical/.local/share/atuin/server.db`, `ATUIN_OPEN_REGISTRATION=true`, and `RUST_LOG=info,atuin_server=debug`; the client continues to sync against `http://127.0.0.1:45654`.
- The live tmux setup had both `~/.tmux.conf` and `~/.config/tmux/` as Dotter symlinks. Home Manager writes `~/.config/tmux/tmux.conf`; a small top-level bridge is enough to preserve tmux startup behavior without keeping duplicate config.
- The old tmux `init.sh` and `bin/hooks/tmux/on-start.sh` are not active tmux configuration. The `init.sh` only handled `reattach-to-user-namespace`, so it is not migrated in this slice.
- The tmux migration intentionally fixes the old `copy-modj-vi` typo by binding `y` in `copy-mode-vi`, matching the intended behavior rather than the exact old file.
- Jujutsu loads global config in this order: `~/.jjconfig.toml`, `~/.config/jj/config.toml`, then `~/.config/jj/conf.d/*.toml`. Because the migration assumes a clean target, old Dotter `conf.d` symlinks should be removed before activation instead of being shadowed with Home Manager tombstone files.
- Home Manager merges option values across imported Nix modules. Defining the same list-valued alias, such as `aliases.lg`, in two imported modules concatenates the command arrays instead of replacing the alias. Each `jj` alias should have a single owner module unless `lib.mkForce` is used intentionally.
- Existing-machine cleanup before activating the migrated profiles: remove Dotter-owned links/files for `~/.config/atuin/config.toml`, `~/.tmux.conf`, `~/.config/tmux`, `~/.config/jj/config.toml`, `~/.config/jj/conf.d`, and `~/.config/fish`; stop/remove any old Docker `atuin-server` container if it exists.

## Work Log

- [x] 2026-07-05 00:39 - Created plan 3 after inventorying `/Users/nonlogical/.config/dotter/common` and defining the non-editor, non-GUI-terminal scope.
- [x] 2026-07-05 00:53 - Inventoried live targets for the in-scope Dotter topics, chose Atuin as the first low-risk app migration, added `home/atuin`, disabled fzf's Ctrl-R widget in favor of Atuin, and verified the Home Manager activation build.
- [x] 2026-07-05 00:54 - Verified the Atuin slice with `nix flake check`.
- [x] 2026-07-05 00:58 - Trimmed Atuin migration to client behavior only by dropping the local `Justfile` and `compose.yml` helper files from Home Manager ownership.
- [x] 2026-07-05 01:00 - Added `atuin-server-up` and `atuin-server-down` as host-user Home Manager helper commands instead of reusable Blueprint packages.
- [x] 2026-07-05 01:08 - Verified generated `atuin-server-up` and `atuin-server-down` with `bash -n`, confirmed only Atuin client TOML is installed under `.config/atuin`, and reran `nix flake check`.
- [x] 2026-07-05 01:16 - Added the tmux Home Manager profile with native options, focused `extra.conf`, and a top-level `.tmux.conf` bridge.
- [x] 2026-07-05 01:22 - Verified the generated tmux files, parsed the generated config with an isolated tmux socket, and reran `nix flake check`.
- [x] 2026-07-05 01:29 - Added the Jujutsu Home Manager profile, replaced legacy `conf.d` symlinks with managed tombstones, validated generated config through `jj config list`, and reran `nix flake check`.
- [x] 2026-07-05 01:35 - Removed Dotter compatibility behavior from the Atuin, Jujutsu, tmux, and fish modules, added the clean-system cleanup notes, and replaced the Docker Atuin server helper with a launchd-backed native Atuin server.
- [x] 2026-07-05 01:50 - Removed the hidden `atuin-server-launchd` wrapper so the LaunchAgent runs the Nix `atuin` executable directly; Home Manager now creates the server data and log directories declaratively.
- [x] 2026-07-05 11:05 - Added a Linux `systemd.user.services.atuin-server` unit comparable to the macOS LaunchAgent, with matching `atuin-server-up` and `atuin-server-down` helpers that use Home Manager's configured `systemctl` path.
- [x] 2026-07-05 11:09 - Renamed Atuin module local bindings in hierarchical broad-to-specific order, such as `atuinServerToolsLaunchd`, `atuinServerToolLaunchdUp`, `svcLaunchdLabel`, `svcSystemdUnitName`, `svcDirectoryLaunchdLog`, and `svcDatabaseUri`, so related service variables sort together.
- [x] 2026-07-05 11:18 - Reviewed the Atuin server service definitions against pinned Home Manager conventions: launchd now uses `RunAtLoad` and a default user domain, while Linux emits the unit only when `systemd.user.enable` is true and the helpers start/stop Home Manager-owned units instead of enabling/disabling them.

## Unfinished Work

- [ ] Before activating on the existing machine, clean the Dotter-owned paths listed in the learning log so Home Manager can own the clean target paths without `force` or tombstone compatibility.
- [ ] Decide whether the next app slice should be `vifm` or script packaging.
- [ ] Review `common/bin` and `common/git/bin` helper scripts command by command before converting any into Blueprint packages.
