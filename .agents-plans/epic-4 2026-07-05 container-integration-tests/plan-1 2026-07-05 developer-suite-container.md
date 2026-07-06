---
date: 2026-07-05
status: in-progress
subject: developer-suite-container
---

# Developer Suite Container

## Goal

Create a container-based integration test harness for `suiteDeveloperBase` so the default Linux developer suite can be activated in a clean container and inspected interactively through the selected local container runtime.

## Context

The reusable developer suite lives under `modules/home/suiteDeveloperBase`. It is intended to be reused across macOS and Linux, with per-user source-control identity supplied through `dotfiles.suites.developerBase.scmIdentity`.

Unit-style Nix evaluation and `nix flake check` catch many structural problems, but they do not provide a realistic shell home that can be inspected like a user profile. The requested harness should:

- Use a local container runtime, not a fake host entry under `hosts/`.
- Build from the real flake modules in this checkout.
- Activate Home Manager for a normal test user with a clean home directory.
- Keep the container alive so the user can exec into it and inspect the profile.
- Be explicit enough that a future reader can understand what is being tested and what is intentionally not covered.

## Decisions

- Put the whole harness under `integration/developer-suite/` so it is clearly test infrastructure, not a package derivation, host config, or reusable Home Manager module.
- Use OCI/Compose naming: `Containerfile`, `compose.yml`, and `Justfile`. Docker remains the default command in the Just recipes, but the layout should not imply that Docker is the only possible runtime.
- Use the official Nix image as the base so the container can evaluate and activate the flake in an environment close to a generic Linux Nix install.
- Keep shell orchestration in `entrypoint.sh` and the Home Manager construction in `home-manager-activation.nix`. The activation expression imports `homeModules.core` and `homeModules.suiteDeveloperBase`; do not add a fake host or synthetic flake output.
- Run activation as an unprivileged test user. Root may prepare Nix and the user account, but the resulting shell should be inspectable as the test user.
- Keep this as an inspection harness. It should be able to build and activate the profile, but it is not a full test assertion framework yet.

## Implementation Steps

1. [x] Create this self-contained integration-test plan.
2. [x] Add Containerfile, Compose file, Justfile, entrypoint, and inline Home Manager test config.
3. [x] Document build/run/exec commands in the harness README and root README.
4. [ ] Build the container image and start the container enough to verify activation.
5. [x] Run final Nix validation and checkpoint the harness.

## Learning Log

- The harness should not add a fake host. `home-manager-activation.nix` builds a Home Manager activation package from the real flake modules with `builtins.getFlake` and a test-only inline module.
- The container intentionally sets `systemd.user.startServices = "suggest"` because a normal inspection container is not running systemd as pid 1. User units can be inspected, but the Atuin server is not started by activation.
- The command surface now lives in `integration/developer-suite/Justfile`, backed by `compose.yml`. The old nested `docker/bin` helper scripts were removed so there is one obvious task entrypoint.
- A live smoke test still depends on a local container runtime daemon. In this session the Docker-compatible socket `/var/run/docker.sock` does not exist, so `just -f integration/developer-suite/Justfile up` cannot start the container yet.

## Work Log

- [x] 2026-07-05 22:57 - Created a separate Docker integration-test epic and plan for the developer suite container harness.
- [x] 2026-07-05 23:04 - Added the Docker harness under `integration/developer-suite/docker/`: image definition, activation entrypoint, build/run/exec scripts, and README documentation.
- [x] 2026-07-05 23:06 - Verified shell syntax, whitespace, and synthetic Linux Home Manager evaluation for the same module set the container builds.
- [x] 2026-07-05 23:08 - Ran `nix flake check`; the repo still evaluates and builds its existing checks.
- [ ] 2026-07-05 23:09 - Run the live Docker smoke test after a Docker daemon is available.
- [x] 2026-07-06 00:09 - Flattened the harness into `integration/developer-suite/` and replaced bespoke helper scripts with Justfile recipes plus Compose.
- [x] 2026-07-06 00:17 - Renamed the runtime files to `Containerfile` and `compose.yml`, keeping Docker as the default command but no longer baking it into the file layout.
- [x] 2026-07-06 06:13Z - Verified the flattened harness with `just --list`, `just --dry-run up`, `docker compose config`, `bash -n`, the synthetic Linux Home Manager evaluation, `git diff --check`, and `nix flake check`.
- [ ] 2026-07-06 06:13Z - Live `just -f integration/developer-suite/Justfile up` is still blocked because `/var/run/docker.sock` does not exist in this session.
- [x] 2026-07-06 06:18Z - Moved the quoted Home Manager expression out of `entrypoint.sh` into `home-manager-activation.nix` and added comments explaining the test-only module boundary.

## Unfinished Work

- [ ] Run `just -f integration/developer-suite/Justfile up` once a container runtime is running and confirm the container reaches the long-lived inspection state.
