---
date: 2026-07-05
status: complete
subject: flatten-blueprint-module-layout
---

# Flatten Blueprint Module Layout

## Goal

Restructure repository-local Blueprint package and Home Manager module paths so generated flake output names are obvious from filenames and do not require thin top-level wrapper modules.

The target convention is:

- `packages/<name>.nix` or `packages/<name>/default.nix` for buildable package artifacts.
- `modules/home/pkg<Name>.nix` or `modules/home/pkg<Name>/default.nix` for lower-level Home Manager integrations.
- `modules/home/suite<Name>.nix` or `modules/home/suite<Name>/default.nix` for higher-level Home Manager suites.

## Context

This repository uses `numtide/blueprint` directly. Blueprint exports files and directories under `modules/home/` as `homeModules.*`, so path names are part of the public import surface used by host-user profiles.

Before this restructuring, the layout had an extra semantic layer:

- a nested unmanaged-program directory contained lower-level bash, git, and zsh integrations;
- a nested developer-base suite directory contained the reusable developer suite;
- a thin top-level developer-base wrapper existed only to export the suite through Blueprint.

That layout made sense while the repo was being bootstrapped, but it now hides the actual Blueprint output names behind wrapper files and nested folders. The desired shape moves the semantic category into the exported module basename:

- unmanaged bash becomes `modules/home/pkgUnmanagedBash.nix`;
- unmanaged git becomes `modules/home/pkgUnmanagedGit.nix`;
- unmanaged zsh becomes `modules/home/pkgUnmanagedZsh.nix`;
- developer base becomes `modules/home/suiteDeveloperBase/default.nix`.

`packages/opn/default.nix` already matches the package convention and should not move in this slice.

## Product Integration

- Existing product model: Blueprint folder names create flake outputs; host-user profiles import `inputs.self.homeModules.*`; repo-local docs describe ownership boundaries.
- New requirement's real intent: make Blueprint output names and repository ownership boundaries visible directly in path names, without manually maintained top-level wrapper modules.
- Cleanest integrated model: encode module category in the `modules/home/` basename with `pkg` and `suite` prefixes plus camelCase names, and keep package derivations directly under `packages/<name>{.nix,/default.nix}`.
- Existing pieces that should move, change, or disappear: legacy nested unmanaged modules should become top-level `pkgUnmanaged*` modules; the legacy developer-base suite directory should become `modules/home/suiteDeveloperBase/`; the thin developer-base wrapper should disappear.
- Architecture impact: host-user imports change to `homeModules.suiteDeveloperBase`; `modules/home/core.nix` imports change to the `pkgUnmanaged*` modules.
- Why this is better than a local patch: the convention removes wrapper churn and keeps Blueprint output names stable, predictable, and reviewable from the filesystem.

## Decisions

- Use `pkg` plus a camelCase name for reusable lower-level Home Manager integrations, even when the integration does not build a package. The prefix means "package/program integration module" in the Home Manager output namespace.
- Use `suite` plus a camelCase name for higher-level Home Manager compositions that enable multiple tools or behavior families together.
- Keep nested suite implementation folders in the same camelCase style when the folder name is part of a durable module boundary. The developer shell suite uses `shBash`, `shFish`, and `shZsh` rather than `shell-bash`, `shell-fish`, or `shell-zsh`.
- Keep `packages/opn/default.nix` where it is because `packages/<name>/default.nix` already matches the desired package convention.
- Remove the thin developer-base wrapper instead of preserving backward compatibility. This repository is still in active migration and the host-user profile can update to the new output name in the same checkpoint.
- Update `README.md`, `AGENTS.md`, and relevant plan breadcrumbs so future agents do not recreate the legacy nested program/suite directories.

## Implementation Steps

1. [x] Move unmanaged Home Manager modules to `modules/home/pkgUnmanaged{Bash,Git,Zsh}.nix`.
2. [x] Move the developer suite directory to `modules/home/suiteDeveloperBase/` and delete the thin wrapper module.
3. [x] Update imports in `modules/home/core.nix` and `hosts/nonlogicals-mbp/users/nonlogical/home-configuration.nix`.
4. [x] Update repo docs and plan breadcrumbs that describe the Blueprint layout.
5. [x] Format, build the Home Manager activation package, inspect the exported module names, and run `nix flake check`.
6. [x] Checkpoint the verified restructuring.

## Learning Log

- Blueprint exports `modules/home/<basename>.nix` and `modules/home/<basename>/default.nix` as `homeModules.<basename>`, so the basename should carry enough meaning to be the public import name.
- The package convention is already satisfied for `opn` because it lives at `packages/opn/default.nix`.
- After the restructure, `nix eval '.#homeModules' --apply 'builtins.attrNames'` reports `core`, `pkgUnmanagedBash`, `pkgUnmanagedGit`, `pkgUnmanagedZsh`, and `suiteDeveloperBase`.

## Work Log

- [x] 2026-07-05 10:41 - Created this plan to fork the Blueprint layout convention work under epic 1 before moving files.
- [x] 2026-07-05 10:47 - Moved Home Manager modules to camelCase `pkg*` and `suite*` Blueprint outputs, updated imports/docs/plans, and validated with exported module inspection, activation build, synthetic Linux eval, formatting, and `nix flake check`.
- [x] 2026-07-05 11:02 - Extended the camelCase convention inside the developer shell suite by renaming shell implementation folders to `shBash`, `shFish`, and `shZsh`.

## Unfinished Work

N/A
