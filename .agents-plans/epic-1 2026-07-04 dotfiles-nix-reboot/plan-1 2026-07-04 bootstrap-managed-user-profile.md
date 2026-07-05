---
date: 2026-07-04
status: in-progress
subject: bootstrap-managed-user-profile
---

# Bootstrap Managed User Profile

## Goal

Bootstrap a new local repo for a slow migration from a Dotter-controlled dotfiles setup to a Nix-managed user profile.

The repo starts deliberately small: an empty `INIT` commit first, then README and `$Tasker_Plan` scaffolding as the next commit.

## Context

The current dotfiles situation is treated as a working but chaotic garden. This project should first discover ownership and behavior before replacing anything. The early work should be read-only inventory, not eager migration.

## Decisions

- Use `~/Projects/local/dotfiles-nix` as the local repo path.
- Keep planning repo-local in `.agents-plans/` because this work is owned by this checkout.
- Start with an empty `INIT` commit so all future scaffolding and migration work is visible as intentional changes.
- Make the next migration step an inventory of Dotter and current dotfiles before writing Nix modules.
- Keep secrets and machine-local volatile state out of the repo.
- Use `numtide/blueprint` directly as the flake output mapper; do not add `flake-parts`.
- Start with one current-machine Darwin scaffold named `nonlogicals-mbp`, plus shared module locations for future user and system profiles.
- Keep shared modules free of personal host/user constants; user identity should live at the host/profile boundary until we introduce a cleaner abstraction.
- Keep home modules explicitly light during bootstrap; do not add common packages until inventory shows what should be owned.
- Add `system-manager` as an available system-profile target, but wait to create a `system-configuration.nix` host until there is a real non-NixOS system to model.
- Use `lib/` for Nix-native helpers that do not produce artifacts; keep buildable artifacts in `packages/` and configurable behavior in `modules/`.
- Move agent-facing repo conventions out of `README.md` and into repo-local `AGENTS.md`.
- Keep migration principles and current next-step memory in `AGENTS.md`, not in the human-facing README.
- Keep repository layout details in `README.md` because they are useful project documentation.
- Call out `hosts/<host>/users/<username>/home-configuration.nix` explicitly as the per-user Home Manager enablement path.
- Use `hosts/<host>/users/<username>/home/<program>.nix` for per-app user config when one file is enough.
- Use `hosts/<host>/users/<username>/home/<program>/default.nix` when a per-app user config needs sibling files such as templates, generated fragments, or other support files.

## Implementation Steps

1. [x] Create the local repo.
2. [x] Create an empty `INIT` commit.
3. [x] Add the initial README describing the migration goal and pacing.
4. [x] Add the first `$Tasker_Plan` plan under `.agents-plans/`.
5. [x] Commit the README and plan as the first non-empty project commit.
6. [x] Add a direct Blueprint flake skeleton for user and system profile management.
7. [x] Validate the flake evaluates.
8. [x] Commit the Blueprint scaffold.
9. [ ] Next session: inventory Dotter ownership and current dotfile surfaces before migrating real config.

## Learning Log

- The project should preserve current working behavior until each slice is understood and has a rollback path.
- Nix should become the owner of deliberate user-profile configuration, not a dumping ground for every existing file.
- Blueprint maps conventional folders like `hosts/` and `modules/` into flake outputs, so the repo should lean on that structure before inventing local glue.
- `flake-parts` is intentionally omitted after the scope correction; Blueprint owns the flake output shape.
- Blueprint's Darwin/home-manager wiring derives the home-manager user's home directory from the Darwin user; do not duplicate `home.homeDirectory` inside the host user home profile.
- Do not hardcode `system.primaryUser` in the shared Darwin core module.
- `modules/home/core.nix` should not install common packages yet. Package ownership should come after the Dotter/dotfiles inventory.
- Blueprint maps `hosts/<hostname>/system-configuration.nix` to `systemConfigs.<hostname>` when the `system-manager` input is present.
- Blueprint exposes `lib/default.nix` as `flake.lib`, making it the right place for reusable Nix helper functions and non-artifact data.
- Repo operating conventions should live in `AGENTS.md`; keep `README.md` focused on project intent and human-facing status.
- Starting principles and bootstrapping status are agent memory for future work, not README content.
- Layout details are human-facing enough to keep in `README.md`; detailed enforcement still lives in `AGENTS.md`.
- Blueprint's host-user path deserves explicit documentation because it is the boundary between reusable modules and per-user enablement.
- Per-app user config should stay under the host-user home tree. Reusable behavior belongs in modules; machine/user-specific app choices belong under `hosts/<host>/users/<username>/home/`.

## Work Log

- [x] 2026-07-04 16:58 - Created the initial plan after the empty `INIT` repo bootstrap.
- [x] 2026-07-04 16:58 - Prepared README and `$Tasker_Plan` scaffolding for the first non-empty project commit.
- [x] 2026-07-04 17:03 - Switched the flake direction to direct Blueprint, with no `flake-parts`.
- [x] 2026-07-04 17:03 - Fixed the first validation failure by removing duplicate home-manager home path configuration.
- [x] 2026-07-04 17:03 - Removed hardcoded `system.primaryUser` from the shared Darwin module.
- [x] 2026-07-04 17:03 - Validated the direct Blueprint scaffold with `nix flake check`.
- [x] 2026-07-04 17:12 - Removed the provisional common package list from the shared home module.
- [x] 2026-07-04 17:18 - Added the `system-manager` input and a light shared module placeholder.
- [x] 2026-07-04 17:34 - Documented the planned `lib/` slot for Nix-native helpers.
- [x] 2026-07-04 17:37 - Moved agent-facing organization guidance from `README.md` into `AGENTS.md`.
- [x] 2026-07-04 17:39 - Moved migration principles and current next-step memory from `README.md` into `AGENTS.md`.
- [x] 2026-07-04 17:39 - Restored concise layout documentation to `README.md`.
- [x] 2026-07-04 17:41 - Called out the explicit host-user Home Manager configuration path in README and AGENTS.
- [x] 2026-07-05 00:22 - Documented the host-user per-app config convention: `home/<program>.nix` for single-file app config, or `home/<program>/default.nix` with sibling files when the app needs a small local tree.

## Unfinished Work

- [ ] Inventory Dotter ownership and current dotfiles in a read-only pass.
