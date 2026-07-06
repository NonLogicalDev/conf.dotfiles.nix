# Developer Suite Docker Integration

This harness activates the reusable `suiteDeveloperBase` Home Manager module in
a clean Linux container so the resulting profile can be inspected manually.

It does not define a fake host. The container builds a synthetic Home Manager
configuration at startup from the real flake modules:

- `homeModules.core`
- `homeModules.suiteDeveloperBase`

The synthetic profile uses this test identity:

- user: `devsuite`
- home: `/home/devsuite`
- name: `Developer Suite`
- email: `devsuite@example.test`
- slug: `devsuite`

## Run

From the repository root:

```bash
integration/developer-suite/docker/bin/run
```

Follow activation logs:

```bash
docker logs -f dotfiles-nix-devsuite
```

Open a shell after activation:

```bash
integration/developer-suite/docker/bin/exec
```

Or directly:

```bash
docker exec -it dotfiles-nix-devsuite su - devsuite
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
docker rm --force dotfiles-nix-devsuite
docker image rm dotfiles-nix-devsuite:latest
```

The repo is mounted read-only at `/workspace/dotfiles-nix`; profile writes are
contained inside the container.
