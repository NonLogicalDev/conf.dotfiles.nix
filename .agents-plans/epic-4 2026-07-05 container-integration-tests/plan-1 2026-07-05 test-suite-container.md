---
date: 2026-07-05
status: in-progress
subject: test-suite-container
---

# Test Suite Container

## Goal

Create a container-based integration test harness for `suiteDeveloperBase` so the default Linux developer suite can be activated in a clean container and inspected interactively through the selected local container runtime.

## Context

The reusable developer suite lives under `modules/home/suiteDeveloperBase`. It is intended to be reused across macOS and Linux, with per-user source-control identity supplied through `dotfiles.suites.developerBase.scmIdentity`.

Unit-style Nix evaluation and `nix flake check` catch many structural problems, but they do not provide a realistic shell home that can be inspected like a user profile. The requested harness should:

- Use a local container runtime with an explicit integration host profile.
- Build from the real flake modules in this checkout.
- Activate Home Manager for a normal test user with a clean home directory.
- Keep the container alive so the user can exec into it and inspect the profile.
- Be explicit enough that a future reader can understand what is being tested and what is intentionally not covered.

## Decisions

- Put the whole harness under `integration/test-suite/` so it is clearly test infrastructure, not a package derivation, host config, or reusable Home Manager module.
- Use OCI/Compose naming: `Containerfile`, `compose.yml`, and `Justfile`. Docker remains the default command in the Just recipes, but the layout should not imply that Docker is the only possible runtime.
- Use the official Nix image as the base so the container can evaluate and activate the flake in an environment close to a generic Linux Nix install.
- Define the integration profile as a normal Blueprint standalone Home Manager profile at `hosts/integration-test-suite/users/testuser/home-configuration.nix`.
- Keep the container's Linux substrate as static test infrastructure under `integration/test-suite/configuration.nix`. That NixOS file owns the disposable Unix user and Nix daemon plumbing; it is not a repo host profile and should not test reusable machine configuration.
- Keep shell orchestration in `entrypoint.sh`. The entrypoint runs the normal Home Manager CLI against `testuser@integration-test-suite`; do not generate a runtime flake or hand-built activation-package expression.
- Run activation as the unprivileged `testuser` through the Nix daemon started inside the container. Do not make `testuser` own `/nix` just to avoid daemon setup.
- Keep this as an inspection harness. It should be able to build and activate the profile, but it is not a full test assertion framework yet.

## Implementation Steps

1. [x] Create this self-contained integration-test plan.
2. [x] Add Containerfile, Compose file, Justfile, entrypoint, and integration host Home Manager profile.
3. [x] Document build/run/exec commands in the harness README and root README.
4. [x] Build the container image and start the container enough to verify activation.
5. [x] Run final Nix validation and checkpoint the harness.

## Learning Log

- Blueprint already supports host-only standalone Home Manager profiles. A directory at `hosts/<host>/users/<user>/home-configuration.nix` without a system config is exposed as `<user>@<host>` under `legacyPackages.<system>.homeConfigurations`.
- The integration harness uses that existing Blueprint path: `testuser@integration-test-suite`.
- The entrypoint uses the Home Manager CLI from the repo's locked `home-manager` input through `nix run <home-manager-input>#home-manager`, then runs `home-manager --flake "$repo#testuser@integration-test-suite" switch`.
- `integration/test-suite/configuration.nix` is intentionally local to the harness. It exists so the container can get normal NixOS-generated account files, shell paths, and Nix daemon behavior without adding a fake reusable host config to Blueprint.
- The container intentionally sets `systemd.user.startServices = "suggest"` because a normal inspection container is not running systemd as pid 1. User units can be inspected, but the Atuin server is not started by activation.
- The Containerfile uses `nixos-rebuild build` followed by the generated activation script. `nixos-rebuild switch` expects an already booted NixOS system, while this harness starts from the lean `nixos/nix` base image.
- Docker exec sessions inherit image-level environment variables, not environment changes made inside the entrypoint process. The image therefore sets `PATH` and `NIX_PROFILES` for the fixed `testuser` profile so shells can find `~/.nix-profile/bin` after Home Manager activation.
- The command surface now lives in `integration/test-suite/Justfile`, backed by `compose.yml`. The old nested `docker/bin` helper scripts were removed so there is one obvious task entrypoint.
- A live smoke test still depends on a local container runtime daemon. In this session the Docker-compatible socket `/var/run/docker.sock` does not exist, so `just -f integration/test-suite/Justfile up` cannot start the container yet.

## Work Log

- [x] 2026-07-05 22:57 - Created a separate Docker integration-test epic and plan for the developer suite container harness.
- [x] 2026-07-05 23:04 - Added the Docker harness under `integration/developer-suite/docker/`: image definition, activation entrypoint, build/run/exec scripts, and README documentation.
- [x] 2026-07-05 23:06 - Verified shell syntax, whitespace, and synthetic Linux Home Manager evaluation for the same module set the container builds.
- [x] 2026-07-05 23:08 - Ran `nix flake check`; the repo still evaluates and builds its existing checks.
- [ ] 2026-07-05 23:09 - Run the live Docker smoke test after a Docker daemon is available.
- [x] 2026-07-06 00:09 - Flattened the harness into `integration/developer-suite/` and replaced bespoke helper scripts with Justfile recipes plus Compose.
- [x] 2026-07-06 00:17 - Renamed the runtime files to `Containerfile` and `compose.yml`, keeping Docker as the default command but no longer baking it into the file layout.
- [x] 2026-07-06 06:13Z - Verified the flattened harness with `just --list`, `just --dry-run up`, `docker compose config`, `bash -n`, the synthetic Linux Home Manager evaluation, `git diff --check`, and `nix flake check`.
- [ ] 2026-07-06 06:13Z - Live container startup is still blocked because `/var/run/docker.sock` does not exist in this session.
- [x] 2026-07-06 06:18Z - Moved the quoted Home Manager expression out of `entrypoint.sh` into `home-manager-activation.nix` and added comments explaining the test-only module boundary.
- [x] 2026-07-06 06:31Z - Replaced the activation-package expression with a plain `home-configuration.nix` default and changed the entrypoint to run the normal Home Manager CLI against the selected file.
- [x] 2026-07-06 06:38Z - Added `home-manager-wrapper.nix` so passed config files can stay host-shaped while the harness supplies container-only user and service-manager facts.
- [x] 2026-07-06 06:45Z - Backed out the wrapper/runtime-flake direction and replaced it with a normal Blueprint integration host profile.
- [x] 2026-07-06 06:52Z - Renamed the harness/profile to `integration/test-suite`, `hosts/integration-test-suite`, and `testuser@integration-test-suite`.
- [x] 2026-07-06 06:58Z - Verified `testuser@integration-test-suite` through Blueprint's `legacyPackages.x86_64-linux.homeConfigurations`, verified the Home Manager CLI `--flake path:$repo#testuser@integration-test-suite build --no-out-link` path, ran `docker compose config`, `just --dry-run up`, `git diff --check`, and `nix flake check`.
- [ ] 2026-07-06 06:58Z - Live `just -f integration/test-suite/Justfile up` is still blocked because `/var/run/docker.sock` does not exist in this session.
- [x] 2026-07-06 07:43Z - Replaced manual container account setup with a static `integration/test-suite/configuration.nix` and a Containerfile `nixos-rebuild build` plus activation step; the runtime entrypoint now starts `nix-daemon` and activates only the standalone Home Manager profile.
- [x] 2026-07-06 00:41 - Built and started the test-suite container, verified Home Manager activation for `testuser@integration-test-suite`, and added image-level Nix profile environment so interactive exec shells can find Home Manager packages.

## Unfinished Work

N/A
