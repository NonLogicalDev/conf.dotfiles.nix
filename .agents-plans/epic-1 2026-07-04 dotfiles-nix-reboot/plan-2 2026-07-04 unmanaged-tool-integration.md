---
date: 2026-07-04
status: in-progress
subject: unmanaged-tool-integration
---

# Unmanaged Tool Integration

## Goal

Design a Home Manager migration layer for tools like zsh, bash, and git where Nix can manage a meaningful body of configuration without assuming third-party tools are Nix-aware.

The working name is `programs.unmanaged.<tool>`.

## Context

Many tools and installers assume they can mutate conventional top-level files such as `~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.bashrc`, and `~/.gitconfig`. The migration should not rely on those tools learning about custom `rc.d` directories or `third-party.gitconfig` files.

The desired shape is: top-level legacy files remain mutable, while Nix declaratively patches a small managed block into those files. Home Manager then writes managed fragments elsewhere.

## Product Integration

- Existing product model: Blueprint provides package/module/host layout, and Home Manager modules are the user-profile integration mechanism.
- New requirement's real intent: gain Home Manager's declarative power without breaking Nix-oblivious tools that mutate conventional dotfiles.
- Cleanest integrated model: introduce `programs.unmanaged.<tool>` modules that own coexistence boundaries, not full top-level file ownership.
- Existing pieces that should move, change, or disappear: native `programs.<tool>.enable` should be forbidden by default when the unmanaged tool module owns the top-level coexistence path.
- Architecture impact: reusable activation helpers likely belong in `lib/home/`; low-level modules belong in `modules/home/programs/unmanaged/` or a similar namespace.
- Why this is better than a local patch: it makes partial adoption explicit, reversible, and repeatable per tool instead of relying on hand-edited dotfile shims.

## Decisions

- Use the namespace `programs.unmanaged.<tool>` for the migration/adoption layer.
- Assume third-party tools are Nix-oblivious and will mutate conventional top-level files.
- Keep conventional top-level files mutable by default.
- Use activation scripts to insert or update marked managed blocks inside top-level files.
- Preserve all content outside managed blocks.
- Store Home Manager or Nix-generated content in managed fragments under `~/.config/dotfiles-nix/<tool>/`.
- Default native Home Manager program policy should be `forbid`, not silent `mkForce false`.
- Support an explicit `nativeProgramPolicy` enum:
	- `forbid`: fail if native `programs.<tool>.enable` is also enabled.
	- `force-disable`: unmanaged module wins and forces native module off.
	- `allow`: advanced mode for tools proven safe to combine.

## Implementation Steps

1. [ ] Inventory existing top-level zsh, bash, and git files and identify third-party mutation patterns.
2. [ ] Design a shared managed-block activation helper under `lib/home/`.
3. [ ] Sketch `programs.unmanaged.zsh` with separate entries for `.zshenv`, `.zprofile`, and `.zshrc`.
4. [ ] Sketch `programs.unmanaged.git` for a managed include block in `~/.gitconfig`.
5. [ ] Define native program conflict assertions for zsh, bash, and git.
6. [ ] Prototype one low-risk tool integration after the Dotter inventory is complete.

## Learning Log

- `programs.unmanaged.<tool>` means the conventional top-level files are unmanaged/mutable, not that Nix does nothing.
- The Nix-owned object is the managed block and the managed fragment, not necessarily the full top-level file.
- The conflict with native Home Manager modules should be loud by default. Silent disabling could hide surprising config.
- For zsh, model each startup file separately:
	- `.zshenv`: tiny, always sourced, no interactive assumptions.
	- `.zprofile`: login-shell setup.
	- `.zshrc`: interactive shell setup.
- For git, a managed block in `~/.gitconfig` can include the Nix-managed fragment while preserving arbitrary top-level changes.
- The migration ladder is:
	1. Top-level file mutable, Nix injects a marked include/source block.
	2. Nix manages most real config in fragments.
	3. Only after a file proves stable, consider full native Home Manager ownership.

## Work Log

- [x] 2026-07-04 18:02 - Created the unmanaged tool integration design plan from the brainstorming thread.

## Unfinished Work

- [ ] Decide final module file layout for `programs.unmanaged.<tool>`.
- [ ] Decide the exact managed block marker format.
- [ ] Inventory current zsh, bash, git, and third-party mutation behavior before implementation.
