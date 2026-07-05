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

This plan is about coexistence with tools that know nothing about Nix. A shell plugin installer, language runtime installer, editor integration, or CLI setup command will usually look for the standard user files and patch them directly: `~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.bashrc`, or `~/.gitconfig`. It is not realistic to expect every tool to write into a repo-specific drop-in directory or an alternate Git include file.

That creates a conflict with normal Home Manager ownership. If Home Manager owns `~/.zshrc` or `~/.gitconfig` wholesale, then Nix-oblivious tools can still edit those files, but their edits are either overwritten by the next activation or become unmanaged drift. If third-party tools own those files wholesale, Nix cannot reliably add the managed configuration needed for the migration.

The desired middle ground is: conventional top-level files remain mutable and tool-compatible, while Nix owns only a clearly marked block inside each file. That block sources or includes a Nix-managed fragment under `~/.config/dotfiles-nix/<tool>/`. Activation scripts maintain the marked block declaratively and preserve everything outside it.

## Product Integration

- Existing product model: Blueprint provides package/module/host layout, and Home Manager modules are the user-profile integration mechanism.
- New requirement's real intent: gain Home Manager's declarative power without breaking Nix-oblivious tools that mutate conventional dotfiles.
- Cleanest integrated model: introduce `programs.unmanaged.<tool>` modules that own coexistence boundaries, not full top-level file ownership.
- Existing pieces that should move, change, or disappear: native `programs.<tool>.enable` should be forbidden by default when the unmanaged tool module owns the top-level coexistence path.
- Architecture impact: reusable activation helpers likely belong in `lib/home/`; low-level modules belong in `modules/home/programs/unmanaged/` or a similar namespace.
- Why this is better than a local patch: it makes partial adoption explicit, reversible, and repeatable per tool instead of relying on hand-edited dotfile shims.

## Decisions

- Use the namespace `programs.unmanaged.<tool>` for the migration/adoption layer.
- Put the first low-level modules under `modules/home/programs/unmanaged/` and import that module set from `modules/home/core.nix` so the options are available but dormant until a host user enables them.
- Put the shared Home Manager marked-block activation helper under `lib/home/managed-block.nix`; the `home` directory provides the Home Manager context, so the filename does not need an `hm-` prefix.
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
- Nixpkgs standard lib does not provide a marked mutable-file block updater. Use standard pieces (`lib.escapeShellArg`, Home Manager activation DAG entries) but keep the repository-owned block replacement helper generic.
- Keep tool-specific block bodies out of `lib/home/managed-block.nix`; Git include syntax belongs in the Git module, and shell source syntax belongs in the unmanaged-program helper.
- Allow `lib/home/managed-block.nix` callers to override comment marker prefix/suffix so the same Home Manager block updater can target files with different comment syntaxes.
- Import the unmanaged bash, git, and zsh modules explicitly from `modules/home/core.nix`; avoid a `modules/home/programs/unmanaged/default.nix` that only hides a short module list.
- In this Blueprint flake's module graph, Home Manager submodules receive `inputs`, so leaf modules should use `inputs.self.lib.home.*` for repo-local helpers instead of deep relative imports or `_module.args` plumbing.

## Implementation Steps

1. [ ] Inventory existing top-level zsh, bash, and git files and identify third-party mutation patterns.
2. [x] Design a shared managed-block activation helper under `lib/home/`.
3. [x] Sketch `programs.unmanaged.zsh` with separate entries for `.zshenv`, `.zprofile`, and `.zshrc`.
4. [x] Sketch `programs.unmanaged.git` for a managed include block in `~/.gitconfig`.
5. [x] Define native program conflict assertions for zsh, bash, and git.
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
- [x] 2026-07-04 18:03 - Rewrote the context section to explain the coexistence problem for a future reader.
- [x] 2026-07-04 18:09 - Started the first implementation slice: dormant bash, zsh, and git Home Manager helpers plus a reusable managed-block activation helper.
- [x] 2026-07-04 18:17 - Implemented dormant unmanaged bash, zsh, and git modules, kept `managed-block` generic, and validated with `nix flake check` plus an enabled Home Manager eval.
- [x] 2026-07-04 18:17 - Verified native-program policy behavior: `force-disable` forces native Git off, and default `forbid` rejects simultaneous `programs.git.enable`.
- [x] 2026-07-04 18:19 - Added configurable comment markers and removed the unnecessary unmanaged module directory `default.nix`.
- [x] 2026-07-04 18:19 - Replaced deep relative helper imports with `inputs.self.lib.home.*` in the unmanaged submodules and revalidated with `nix flake check`.

## Unfinished Work

- [ ] Inventory current zsh, bash, git, and third-party mutation behavior before enabling these modules for a real user.
- [ ] Prototype one low-risk tool integration after the inventory is complete.
