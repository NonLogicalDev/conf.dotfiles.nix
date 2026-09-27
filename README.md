# dotfiles-nix

This repository manages the development environment through Home Manager. The local Mac uses the standalone `nonlogical@nonlogicals-mbp` profile with Determinate Nix. Terminal applications and mutable application data remain installed and stored separately from their Nix-managed preferences.

## Local workflow

From this checkout:

```sh
home-manager switch --flake .#nonlogical@nonlogicals-mbp
nix flake check
```

To build and inspect a profile before activating it:

```sh
nix build '.#homeConfigurations."nonlogical@nonlogicals-mbp".activationPackage'
```

The host profile composes the shared developer suite with local terminal/editor preferences, personal helper commands, existing tool paths, and an independently pinned Jujutsu version. Shell and Git entrypoints remain editable through the repository's managed include blocks. Changes to durable settings belong in the Nix modules.

The Darwin scaffold is retained for future system management; it is not the activation entrypoint on this Determinate-managed Mac. Other existing Nix profile packages remain installed independently unless Home Manager owns the same package.

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

- `integration/test-suite/` contains a container integration harness that
  activates `suiteDeveloperBase` for a clean Linux test user named `testuser`.
  It uses `Containerfile`, `compose.yml`, and `Justfile` so Docker is only the
  default runtime, not part of the file layout. It runs the normal Home Manager
  CLI against the Blueprint standalone profile
  `testuser@integration-test-suite`, defined at
  `hosts/integration-test-suite/users/testuser/home-configuration.nix`. Run
  `just -f integration/test-suite/Justfile up`, then inspect it with `just -f
  integration/test-suite/Justfile exec`.
