---
date: 2026-07-05
status: in-progress
subject: developer-suite-container
---

# Developer Suite Container

## Goal

Create a Docker-based integration test harness for `suiteDeveloperBase` so the default Linux developer suite can be activated in a clean container and inspected interactively with `docker exec`.

## Context

The reusable developer suite lives under `modules/home/suiteDeveloperBase`. It is intended to be reused across macOS and Linux, with per-user source-control identity supplied through `dotfiles.suites.developerBase.scmIdentity`.

Unit-style Nix evaluation and `nix flake check` catch many structural problems, but they do not provide a realistic shell home that can be inspected like a user profile. The requested harness should:

- Use Docker, not a fake host entry under `hosts/`.
- Build from the real flake modules in this checkout.
- Activate Home Manager for a normal test user with a clean home directory.
- Keep the container alive so the user can run `docker exec -it <name> ...`.
- Be explicit enough that a future reader can understand what is being tested and what is intentionally not covered.

## Decisions

- Put the harness under `integration/developer-suite/docker/` so it is clearly test infrastructure, not a package derivation, host config, or reusable Home Manager module.
- Use the official Nix image as the base so the container can evaluate and activate the flake in an environment close to a generic Linux Nix install.
- Generate a small test-only Home Manager config inside the container entrypoint that imports `homeModules.core` and `homeModules.suiteDeveloperBase`; do not add a fake host or synthetic flake output.
- Run activation as an unprivileged test user. Root may prepare Nix and the user account, but the resulting shell should be inspectable as the test user.
- Keep this as an inspection harness. It should be able to build and activate the profile, but it is not a full test assertion framework yet.

## Implementation Steps

1. [x] Create this self-contained integration-test plan.
2. [x] Add Dockerfile, entrypoint, inline Home Manager test config, and helper scripts.
3. [x] Document build/run/exec commands in the harness README and root README.
4. [ ] Build the Docker image and start the container enough to verify activation.
5. [x] Run final Nix validation and checkpoint the harness.

## Learning Log

- The harness should not add a fake host. The entrypoint builds a Home Manager activation package from the real flake modules with `builtins.getFlake` and a test-only inline module.
- The container intentionally sets `systemd.user.startServices = "suggest"` because Docker is not running systemd as pid 1. User units can be inspected, but the Atuin server is not started by activation.
- Docker is not currently available in this session: `integration/developer-suite/docker/bin/run` failed because `/var/run/docker.sock` does not exist. A live smoke test remains the next validation step once Docker Desktop or another Docker daemon is running.

## Work Log

- [x] 2026-07-05 22:57 - Created a separate Docker integration-test epic and plan for the developer suite container harness.
- [x] 2026-07-05 23:04 - Added the Docker harness under `integration/developer-suite/docker/`: image definition, activation entrypoint, build/run/exec scripts, and README documentation.
- [x] 2026-07-05 23:06 - Verified shell syntax, whitespace, and synthetic Linux Home Manager evaluation for the same module set the container builds.
- [x] 2026-07-05 23:08 - Ran `nix flake check`; the repo still evaluates and builds its existing checks.
- [ ] 2026-07-05 23:09 - Run the live Docker smoke test after a Docker daemon is available.

## Unfinished Work

- [ ] Run `integration/developer-suite/docker/bin/run` once Docker is running and confirm the container reaches the long-lived inspection state.
