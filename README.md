# dotfiles-nix

This repo is the slow reboot of my user profile management: move from a Dotter-controlled garden of chaos to a Nix-managed profile that is understandable, reversible, and boring to operate.

The goal is not to port everything at once. The first phase is inventory and boundaries:

- Identify what Dotter currently owns.
- Separate machine-specific state from portable user profile configuration.
- Decide which parts belong in Nix, which parts should stay as app state, and which parts should be deleted.
- Introduce Nix modules only after the current behavior is understood.

The flake is Blueprint-native and is intended to grow into three system-profile targets over time:

- `nix-darwin` for macOS machines.
- NixOS for full Nix-managed hosts.
- `system-manager` for non-NixOS systems where Nix should manage selected system state.

## Layout

- `packages/<name>.nix` or `packages/<name>/default.nix` contains package derivations and other buildable artifacts.
- `modules/home/pkg<Name>.nix` or `modules/home/pkg<Name>/default.nix` contains lower-level Home Manager integrations for one program or package family, using camelCase after the `pkg` prefix.
- `modules/home/suite<Name>.nix` or `modules/home/suite<Name>/default.nix` contains higher-level Home Manager compositions that enable multiple programs or integrations together, using camelCase after the `suite` prefix.
- `modules/darwin/`, `modules/nixos/`, and `modules/system-manager/` contain shared system modules.
- `hosts/<host>/` contains host-specific system facts.
- `hosts/<host>/users/<username>/home-configuration.nix` contains the per-user Home Manager enablement choices for that host.
- `hosts/<host>/users/<username>/home/<program>.nix` contains per-app user config when one file is enough.
- `hosts/<host>/users/<username>/home/<program>/default.nix` contains per-app user config when the app needs sibling files.
- `lib/` contains Nix-native helper functions and data that do not produce artifacts by themselves.

## Integration Harnesses

- `integration/developer-suite/` contains a container integration harness that
  activates `suiteDeveloperBase` for a clean Linux test user named `devsuite`.
  It uses `Containerfile`, `compose.yml`, and `Justfile` so Docker is only the
  default runtime, not part of the file layout. Run
  `just -f integration/developer-suite/Justfile up`, then inspect it with
  `just -f integration/developer-suite/Justfile exec`.
