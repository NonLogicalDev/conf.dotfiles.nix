---
date: 2026-07-04
status: in-progress
subject: onboard-existing-zsh-and-git
---

# Onboard Existing Zsh And Git

## Goal

Onboard the current personal zsh and Git behavior into this Nix dotfiles repo without breaking the existing shell or Git workflow.

The migration target is not an exact copy of the old Dotter file tree. Existing files are source material for understanding behavior. Each slice should translate that behavior into idiomatic Home Manager and small Nix-owned helper files where possible, avoiding large literal shell/config blobs unless there is a clear reason to keep a script as a file.

Target real-user surfaces:

- `~/.zshenv`
- `~/.zprofile`
- `~/.zshrc`
- `~/.zlogin`
- `~/.zlogout`
- `~/.config/zsh/`
- `~/.config/git/`
- `~/.gitconfig`

## Context

The repository now has the bootstrap layout, Home Manager core module, and unmanaged zsh/Git helpers needed for a partial migration. The current real home still has Dotter-era config. That legacy config should be read as inventory, not treated as a shape that Nix must reproduce exactly.

Current zsh shape:

- Top-level zsh files exist and are small loader stubs.
- `~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.zlogin`, and `~/.zlogout` source `~/.config/zsh/hooks/_loader.zsh` with startup-file-specific hook directories.
- `~/.zprofile` also evaluates `/opt/homebrew/bin/brew shellenv zsh`.
- `~/.zshrc` also contains an LM Studio PATH block for `/Users/nonlogical/.lmstudio/bin`.
- `~/.config/zsh/hooks/` contains hook files for `zshenv`, `zprofile`, `zshrc`, `zlogin`, and `zlogout`.
- `~/.config/zsh/plugins` and `~/.config/zsh/themes` are symlinks into the Dotter tree.

Current Git shape:

- `~/.gitconfig` does not currently exist.
- `~/.config/git/config` exists and includes `gitconfig.d/00_index`.
- `~/.config/git/gitconfig.d` and `~/.config/git/gitignore.default` are symlinks into the Dotter tree.
- `~/.config/git/ignore` exists as a small real file.
- The current Git config contains personal identity and a GitHub credential helper that points at a concrete Nix store `gh` wrapper path; that helper should not be blindly frozen as a durable literal without deciding how `gh` will be provided by Nix.

No obvious secret patterns were found in the inspected zsh/Git paths during the first inventory pass, but all copied config should still be reviewed before enabling it.

## Product Integration

- Existing product model: reusable Home Manager behavior lives in `modules/home/`, while real host-user choices live under `hosts/<host>/users/<username>/`.
- New requirement's real intent: make the user's current zsh and Git setup repo-owned by Nix while preserving current behavior and allowing Nix-oblivious tools to keep mutating conventional files during the transition.
- Cleanest integrated model: add per-app host-user config modules under `hosts/nonlogicals-mbp/users/nonlogical/home/`, using `home/zsh/default.nix` and `home/git/default.nix` because both apps have companion files.
- Existing pieces that should move, change, or disappear: Dotter-owned symlinks under `~/.config/zsh` and `~/.config/git` should disappear piece by piece as their behavior is represented by Home Manager options or small Nix-owned companion files. Top-level zsh and Git config files should stay mutable and be wired through unmanaged helpers.
- Architecture impact: this epic exercises the newly documented host-user per-app layout and the unmanaged zsh/Git bridge modules.
- Why this is better than a local patch: semantic migration keeps the repo readable after the transition. It avoids preserving accidental Dotter-era file boundaries while still keeping activation reversible and compatible with Nix-oblivious tools.

## Decisions

- Create epic-2 for onboarding real zsh and Git config, separate from epic-1 bootstrap and unmanaged-helper design.
- Use `hosts/nonlogicals-mbp/users/nonlogical/home/zsh/default.nix` for zsh because zsh has hooks, plugins, and themes as companion files.
- Use `hosts/nonlogicals-mbp/users/nonlogical/home/git/default.nix` for Git because Git has config fragments and ignore files as companion files.
- Do not preserve backward compatibility for old experimental unmanaged Git paths or markers; this repo is still in bootstrap.
- Keep top-level zsh files mutable through `programs.unmanaged.zsh`.
- Keep top-level Git files mutable through `programs.unmanaged.git`.
- Use copied config content only as inventory/source evidence. Do not commit long-lived exact copies of loose files when Home Manager options can express the same behavior.
- Treat the current GitHub credential helper's concrete Nix store path as a migration smell. Prefer a future Nix-managed `gh` package path or a Git credential helper integration rather than copying the old store path as a durable config value.
- Migrate Git first because most of the existing Git behavior maps cleanly to `programs.git.settings`, `programs.git.ignores`, and the existing unmanaged Git include bridge.
- Use only `.config/git/config` as the unmanaged Git include target for now. `~/.gitconfig` does not exist today, and including both locations would duplicate multi-valued settings such as credential helpers if Git reads both files.
- For zsh, migrate semantic groups incrementally. Candidate groups are Home Manager package/session integration, history, shell options, completion, aliases, environment variables, key bindings, plugin setup, prompt/theme behavior, and finalizers. Keep script-like pieces as companion files only until they can be translated or intentionally retained.

## Implementation Steps

1. [x] Inventory current zsh and Git files, symlinks, top-level stubs, and line counts.
2. [x] Create this epic-2 plan before migration edits.
3. [x] Copy current zsh and Git config content into host-user per-app directories for review.
4. [x] Add `home/zsh/default.nix` that stages repo-owned companion files without surprising activation conflicts.
5. [x] Add `home/git/default.nix` that stages repo-owned Git fragments without freezing the old concrete `gh` store path as active Nix config.
6. [x] Import the new per-app modules from `hosts/nonlogicals-mbp/users/nonlogical/home-configuration.nix`.
7. [x] Build/evaluate the Home Manager profile.
8. [x] Replace staged Git file copies with idiomatic Home Manager Git settings and the unmanaged Git include bridge.
9. [ ] Decide the activation cutover plan for existing Dotter-linked zsh files under `~/.config/zsh`.
10. [ ] Migrate zsh semantic groups into Home Manager/Nix instead of preserving the old file tree as the final structure.

## Learning Log

- `~/.gitconfig` is absent at the start of this epic, so unmanaged Git will create it during activation if `includeTargets` includes `.gitconfig`.
- Existing `~/.config/git/config` is a real mutable file, not a symlink.
- Existing `~/.config/git/gitconfig.d` and `~/.config/git/gitignore.default` are Dotter symlinks.
- Existing `~/.config/zsh/plugins` and `~/.config/zsh/themes` are Dotter symlinks.
- Existing top-level zsh files already use a hook-loader pattern. The unmanaged zsh module uses a different `~/.config/zsh/rc/<startup-file>.d/` hook layout, so onboarding needs to decide whether to preserve the legacy hook tree as managed content or translate it into the new rc layout.
- Home Manager activation checks existing link targets. Repo-owned copies should be reviewed before replacing existing files or symlinks in the real home.
- The first implementation slice staged copied files under `~/.config/dotfiles-nix/staged/zsh` and `~/.config/dotfiles-nix/staged/git` through Home Manager. That was useful as inventory, but the durable migration direction is semantic Nix/Home Manager config rather than long-lived staged copies.
- Representative checksum checks matched between source files and repo-staged copies for `.zshenv`, `.zprofile`, `.zshrc`, `.config/git/config`, `.config/git/gitconfig.d/01_defaults`, and `.config/zsh/plugins/10-plug-bundle.zsh`.
- `nix flake check` passes after staging the newly imported host-user app module paths in Git. The flake-backed evaluation requires imported paths to be tracked or staged.
- Home Manager renders `"stgit.alias"` as Git's `[stgit "alias"]` subsection, and `git config --file` reads the generated values as `stgit.alias.*`.
- The migrated Git module writes the managed fragment at `~/.config/git/config.d/50-nix-managed.conf`. `programs.unmanaged.git` inserts a small include block into mutable `~/.config/git/config` so Nix-oblivious tools can still edit the top-level file.
- The direct Home Manager inspection build needs `home.username` and `home.homeDirectory` supplied by the caller or system integration. This repo intentionally does not hardcode those values in reusable modules.

## Work Log

- [x] 2026-07-04 20:54 - Created epic-2 plan after inventorying current zsh and Git surfaces.
- [x] 2026-07-04 21:02 - Copied current zsh and Git config into `hosts/nonlogicals-mbp/users/nonlogical/home/{zsh,git}/files/`, following Dotter symlinks so the repo contains real reviewable files.
- [x] 2026-07-04 21:04 - Added imported per-app modules that stage copied config under `~/.config/dotfiles-nix/staged/` instead of taking live config ownership.
- [x] 2026-07-04 21:08 - Validated with `nix flake check` after staging new imported paths so Nix could see them in the git-backed flake.
- [x] 2026-07-04 21:59 - Corrected the epic direction after deciding that durable migration should translate behavior into Nix/Home Manager rather than preserve exact Dotter file copies.
- [x] 2026-07-04 21:59 - Replaced staged Git file copies with `programs.git.settings`, `programs.git.ignores`, `pkgs.gh`, and `programs.unmanaged.git`.
- [x] 2026-07-04 21:59 - Built an inspection-only Home Manager activation package with inline `home.username` and `home.homeDirectory`, then verified the generated Git config and unmanaged include activation block.

## Unfinished Work

- [ ] Document activation cutover steps before touching existing Dotter-linked zsh files.
- [ ] Migrate zsh semantic groups into Home Manager/Nix without carrying forward the old file tree as the final shape.
- [ ] Decide which script-like zsh pieces should remain as small companion files and which should become Home Manager options.
