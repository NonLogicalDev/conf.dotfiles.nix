# AGENTS.md - dotfiles-nix

Read this file before editing the repo. This project is a slow migration from Dotter-managed dotfiles to Nix-managed user and system profiles.

## Migration Memory

- Take small, reviewable steps.
- Prefer explicit ownership over clever abstraction.
- Keep migration reversible until each slice is proven.
- Do not move secrets into the repo.
- Do not rewrite working config just because it looks messy.
- The repo was bootstrapped with an empty `INIT` commit, followed by README and `$Tasker_Plan` scaffolding.
- Next migration step: perform a read-only inventory of the current Dotter layout and existing dotfiles before migrating real config.

## Project Rules

- Use `numtide/blueprint` directly as the flake output mapper.
- Do not add `flake-parts`.
- Do not migrate real dotfiles before inventorying Dotter ownership and current behavior.
- Keep shared modules free of personal host/user constants unless the value is genuinely shared.
- Keep `modules/home/core.nix` explicitly light during bootstrap. Do not add common packages there until inventory shows what should be owned.
- Do not create fake hosts. Add `hosts/<host>/configuration.nix`, `darwin-configuration.nix`, or `system-configuration.nix` only for real machines.

## Blueprint Layout

Use Blueprint's folders by what they produce:

- `packages/` contains derivations and other buildable artifacts.
- `modules/home/programs/` contains lower-level Home Manager integrations for one program.
- `modules/home/suites/` contains higher-level Home Manager compositions that enable multiple programs or integrations together.
- `modules/darwin/`, `modules/nixos/`, and `modules/system-manager/` contain shared system modules.
- `hosts/<host>/` contains host-specific system facts.
- `hosts/<host>/users/<username>/home-configuration.nix` contains the per-user Home Manager enablement choices for that host.
- `hosts/<host>/users/<username>/home/<program>.nix` contains per-app user config when one file is enough.
- `hosts/<host>/users/<username>/home/<program>/default.nix` contains per-app user config when the app needs sibling files.
- `lib/` contains Nix-native helper functions and data that do not produce artifacts by themselves.

Prefer `lib/` for reusable Nix helpers such as option builders, naming helpers, small module constructors, shared predicates, or data normalization. If it grows, split it by namespace, for example `lib/home/`, `lib/packages/`, or `lib/hosts/`, then re-export those helpers from `lib/default.nix`.

## Package And Module Boundaries

- Low-level program derivations belong under `packages/programs/<name>/`.
- Low-level Home Manager integrations belong under `modules/home/programs/<name>/`.
- Higher-level Home Manager bundles belong under `modules/home/suites/<name>/`.
- `hosts/<host>/users/<username>/home-configuration.nix` should choose what to enable for that user on that host; reusable behavior belongs in modules.
- Host-user app configuration belongs under `hosts/<host>/users/<username>/home/<program>.nix`, or under `hosts/<host>/users/<username>/home/<program>/default.nix` when the program needs companion files.
- `users.users.<name>.home` is a nix-darwin system option and belongs in the Darwin host layer, not inside Home Manager modules.
- In this Blueprint flake's module graph, `inputs` is available in submodules. Use `inputs.self.lib.*` for repo-local helpers instead of deep relative imports such as `../../../../lib/...`.
- Do not use `_module.args` merely to thread repo-local helper libraries into submodules when `inputs.self.lib.*` is available.

## Validation

- Run `nix flake check` after changing Nix files.
- For documentation-only changes, a quick `nix flake check` is still preferred when cheap.
- Keep the active `.agents-plans/` plan updated when changing project conventions or migration scope.
