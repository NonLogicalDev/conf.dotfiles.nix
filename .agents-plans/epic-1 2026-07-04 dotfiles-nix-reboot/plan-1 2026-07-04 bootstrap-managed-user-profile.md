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

## Work Log

- [x] 2026-07-04 16:58 - Created the initial plan after the empty `INIT` repo bootstrap.
- [x] 2026-07-04 16:58 - Prepared README and `$Tasker_Plan` scaffolding for the first non-empty project commit.
- [x] 2026-07-04 17:03 - Switched the flake direction to direct Blueprint, with no `flake-parts`.
- [x] 2026-07-04 17:03 - Fixed the first validation failure by removing duplicate home-manager home path configuration.
- [x] 2026-07-04 17:03 - Removed hardcoded `system.primaryUser` from the shared Darwin module.
- [x] 2026-07-04 17:03 - Validated the direct Blueprint scaffold with `nix flake check`.

## Unfinished Work

- [ ] Inventory Dotter ownership and current dotfiles in a read-only pass.
