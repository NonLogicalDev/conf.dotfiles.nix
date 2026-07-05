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

- `packages/` contains derivations and other buildable artifacts.
- `modules/home/programs/` contains lower-level Home Manager integrations for one program.
- `modules/home/suites/` contains higher-level Home Manager compositions that enable multiple programs or integrations together.
- `modules/darwin/`, `modules/nixos/`, and `modules/system-manager/` contain shared system modules.
- `hosts/<host>/` contains host-specific system facts and the per-user enablement choices for that host.
- `lib/` contains Nix-native helper functions and data that do not produce artifacts by themselves.
