# Developer Suite Integration

This harness activates the reusable `suiteDeveloperBase` Home Manager module in
a clean Linux container so the resulting profile can be inspected manually. It
uses a standard `Containerfile` plus Compose file so the same harness can run
with Docker or another compatible OCI runtime.

It does not define a fake host. The container builds a synthetic Home Manager
configuration at startup from the real flake modules:

- `homeModules.core`
- `homeModules.suiteDeveloperBase`

The shell entrypoint handles container setup. The Home Manager construction
itself lives in `home-manager-activation.nix` so the Nix expression can be read,
formatted, and reviewed as Nix rather than as a quoted shell string.

The synthetic profile uses this test identity:

- user: `devsuite`
- home: `/home/devsuite`
- name: `Developer Suite`
- email: `devsuite@example.test`
- slug: `devsuite`

## Run

From the repository root:

```bash
just -f integration/developer-suite/Justfile up
```

Follow activation logs:

```bash
just -f integration/developer-suite/Justfile logs
```

Open a shell after activation:

```bash
just -f integration/developer-suite/Justfile exec
```

By default the task file uses Docker:

```bash
COMPOSE="docker compose" CONTAINER_RUNTIME=docker just -f integration/developer-suite/Justfile up
```

For another Compose-compatible runtime, override both command surfaces:

```bash
COMPOSE="podman compose" CONTAINER_RUNTIME=podman just -f integration/developer-suite/Justfile up
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
not run systemd as pid 1, so the harness sets `systemd.user.startServices` to
`suggest` and does not try to start the Atuin server.

## Cleanup

```bash
just -f integration/developer-suite/Justfile clean
```

The repo is mounted read-only at `/workspace/dotfiles-nix`; profile writes are
contained inside the container.
