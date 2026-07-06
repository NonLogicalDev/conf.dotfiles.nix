# Test Suite Integration

This harness activates the reusable `suiteDeveloperBase` Home Manager module in
a clean Linux container so the resulting profile can be inspected manually. It
uses a standard `Containerfile` plus Compose file so the same harness can run
with Docker or another compatible OCI runtime.

The container runs the normal Home Manager CLI against the Blueprint standalone
profile `testuser@integration-test-suite`. That profile lives at
`hosts/integration-test-suite/users/testuser/home-configuration.nix` and
imports the real flake modules:

- `homeModules.core`
- `homeModules.suiteDeveloperBase`

The synthetic profile uses this test identity:

- user: `testuser`
- home: `/home/testuser`
- name: `Test User`
- email: `testuser@example.test`
- slug: `testuser`

## Run

From the repository root:

```bash
just -f integration/test-suite/Justfile up
```

Follow activation logs:

```bash
just -f integration/test-suite/Justfile logs
```

Open a shell after activation:

```bash
just -f integration/test-suite/Justfile exec
```

By default the task file uses Docker:

```bash
COMPOSE="docker compose" CONTAINER_RUNTIME=docker just -f integration/test-suite/Justfile up
```

For another Compose-compatible runtime, override both command surfaces:

```bash
COMPOSE="podman compose" CONTAINER_RUNTIME=podman just -f integration/test-suite/Justfile up
```

To activate a different standalone Home Manager profile from this flake, set
`DOTFILES_NIX_HOME_PROFILE` to the profile name and keep `DOTFILES_NIX_USER` /
`DOTFILES_NIX_HOME` aligned with that profile:

```bash
DOTFILES_NIX_HOME_PROFILE=some-user@some-host DOTFILES_NIX_USER=some-user DOTFILES_NIX_HOME=/home/some-user \
  just -f integration/test-suite/Justfile up
```

## Inspect

Inside the container:

```bash
zsh -l
git config --global --list --show-origin
jj config list --include-defaults
ls -la ~/.config
find ~/.config/zsh/rc -maxdepth 3 -type f -print
find ~/.config/bash/rc -maxdepth 3 -type f -print
```

Home Manager user services are generated for inspection, but the container does
not run systemd as pid 1, so the integration profile sets
`systemd.user.startServices` to `suggest` on Linux and does not try to start the
Atuin server.

## Cleanup

```bash
just -f integration/test-suite/Justfile clean
```

The repo is mounted read-only at `/workspace/dotfiles-nix`; profile writes are
contained inside the container.
