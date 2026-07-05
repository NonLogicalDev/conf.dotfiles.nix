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

The desired middle ground is: conventional top-level files remain mutable and tool-compatible, while Nix owns only a clearly marked block inside each file. For Git, that block includes a Nix-managed fragment under `~/.config/dotfiles-nix/git/`. For shell startup files, that block sources generated dispatcher files under `~/.config/<shell>/rc/<startup-file>.<shell>`; each dispatcher sources ordered hooks from the sibling `~/.config/<shell>/rc/<startup-file>.d/` directory, where Home Manager owns one numbered Nix hook and users or non-Nix tools can add their own numbered hooks. Activation scripts maintain the marked block declaratively and preserve everything outside it.

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
- Store Git's Home Manager or Nix-generated content in managed fragments under `~/.config/dotfiles-nix/git/`.
- Store shell Home Manager or Nix-generated content as numbered hooks under `~/.config/<shell>/rc/<startup-file>.d/50-nix-managed.<shell>`.
- Keep top-level managed shell blocks as pointers only. A managed block in `.zshrc`, `.zshenv`, `.zprofile`, `.bashrc`, or `.bash_profile` should source one generated dispatcher file and contain no hook iteration logic.
- Source shell hook directories from generated dispatcher files in lexical order so user-owned hooks such as `~/.config/zsh/rc/zshenv.d/99-conda.zsh` or `~/.config/bash/rc/bashrc.d/99-conda.bash` can extend or override the Nix-managed hook without editing the top-level startup file.
- Keep shell hook layout and shell-specific hook sourcing syntax in each shell module. The shared unmanaged-program helper owns only the native Home Manager conflict policy, not ordered hook directories or shell startup-file activation.
- Default native Home Manager program policy should be `forbid`, not silent `mkForce false`.
- Support an explicit `nativeProgramPolicy` enum:
	- `forbid`: fail if native `programs.<tool>.enable` is also enabled.
	- `force-disable`: unmanaged module wins and forces native module off.
	- `allow`: advanced mode for tools proven safe to combine.
- Nixpkgs standard lib does not provide a marked mutable-file block updater. Use standard pieces (`lib.escapeShellArg`, Home Manager activation DAG entries) but keep the repository-owned block replacement helper generic.
- Keep tool-specific block bodies out of `lib/home/managed-block.nix`; Git include syntax belongs in the Git module, and shell source syntax belongs in the unmanaged-program helper.
- Allow `lib/home/managed-block.nix` callers to override comment marker prefix/suffix so the same Home Manager block updater can target files with different comment syntaxes.
- Allow `lib/home/managed-block.nix` callers to choose where a new block is inserted. Default to appending, but support an `after-preamble` mode with caller-provided line regexes so shebangs, file headers, and doc comments can remain before the managed block.
- Allow callers to opt into relocating an existing managed block. Shell startup files use this because the managed source block must run before most hand-written or installer-written rc content. Git also uses relocation so the include remains near the top of the mutable config file.
- Place the Git managed include near the top of the chosen mutable config file. Git applies config in file order, so this lets Nix provide defaults while later hand-written or tool-written top-level settings can override them.
- Import the unmanaged bash, git, and zsh modules explicitly from `modules/home/core.nix`; avoid a `modules/home/programs/unmanaged/default.nix` that only hides a short module list.
- In this Blueprint flake's module graph, Home Manager submodules receive `inputs`, so leaf modules should use `inputs.self.lib.home.*` for repo-local helpers instead of deep relative imports or `_module.args` plumbing.
- Git pressure tests on Apple Git 2.50.1 show that normal Git config loading reads `~/.config/git/config` and `~/.gitconfig`, but `git config --global` has narrower behavior: it does not expand includes unless `--includes` is passed, and its write target depends on which global config file exists. Keep the Git include target configurable.

## Implementation Steps

1. [ ] Inventory existing top-level zsh, bash, and git files and identify third-party mutation patterns.
2. [x] Design a shared managed-block activation helper under `lib/home/`.
3. [x] Sketch `programs.unmanaged.zsh` with separate entries for `.zshenv`, `.zprofile`, and `.zshrc`.
4. [x] Sketch `programs.unmanaged.git` for a managed include block in either `~/.gitconfig` or `~/.config/git/config`.
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
- For git, a managed block in `~/.gitconfig` or `~/.config/git/config` can include the Nix-managed fragment while preserving arbitrary top-level changes.
- For bash and zsh startup files, append placement is too late for the migration use case. The managed source block should be inserted after only the leading preamble, so ordered hook directories can affect the rest of `.bashrc`, `.bash_profile`, `.zshenv`, `.zprofile`, and `.zshrc`.
- For bash and zsh, the Nix-owned hook defaults to `50-nix-managed.<shell>` inside `~/.config/<shell>/rc/<startup-file>.d/`. Lower numbers can prepare state before Nix; higher numbers can extend or override Nix-managed setup.
- For bash and zsh, generated dispatcher files live at `~/.config/<shell>/rc/<startup-file>.<shell>`, next to but not inside the startup-file-specific hook directory. Dispatchers source only sibling hooks matching `[0-9][0-9]-*.<shell>` from `~/.config/<shell>/rc/<startup-file>.d/`.
- `lib/home/unmanaged-program.nix` should not know shell hook layout or individual shell semantics. Bash hook paths, `shopt -s nullglob`, and `50-nix-managed.bash` live in `modules/home/programs/unmanaged/bash.nix`; zsh hook paths, `(N)` glob qualifiers, and `50-nix-managed.zsh` live in `modules/home/programs/unmanaged/zsh.nix`.
- For Git config, a near-top include is safer than an appended include because it makes the managed fragment behave like defaults. Existing top-level settings that appear later in `~/.gitconfig` or `~/.config/git/config` continue to win.
- Home Manager activation scripts should not rely on the user's ambient shell `PATH` for text-processing tools. The managed-block helper accepts an explicit `awk` executable path, and Home Manager modules pass `${pkgs.gawk}/bin/awk`.
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
- [x] 2026-07-04 18:36 - Added explanatory comments to the repo-local `lib/` files so readers do not need deep Nix or Home Manager module knowledge to follow the helper boundaries.
- [x] 2026-07-04 18:42 - Added managed-block placement control with default append behavior and an `after-preamble` mode for configurable shebang/header/comment preservation.
- [x] 2026-07-04 18:47 - Pressure-tested Git global config loading and added `programs.unmanaged.git.includeTarget` so the managed include block can live in either `~/.gitconfig` or `~/.config/git/config`.
- [x] 2026-07-04 19:01 - Changed unmanaged bash and zsh startup files to place the managed source block before ordinary rc content and to relocate older appended blocks during activation.
- [x] 2026-07-04 19:06 - Fixed activation to use an explicit Nix-provided `awk`, then verified the disposable test profile activates idempotently with one managed block per top-level file.
- [x] 2026-07-04 19:07 - Changed unmanaged Git to insert and relocate the managed include near the top of the mutable Git config so later top-level settings remain local overrides.
- [x] 2026-07-04 19:15 - Changed unmanaged bash and zsh to write Nix-managed hooks under `~/.config/<shell>/rc/<startup-file>.d/50-nix-managed.<shell>` and source all numbered hooks from each startup file, with shell-specific source syntax kept in the shell modules.
- [x] 2026-07-04 19:24 - Moved shell hook layout ownership out of `lib/home/unmanaged-program.nix` and into the bash and zsh modules.
- [x] 2026-07-04 19:30 - Changed unmanaged bash and zsh top-level managed blocks to source generated dispatcher files instead of embedding hook iteration logic directly; dispatchers live beside sibling `rc/<startup-file>.d/` hook directories.
- [x] 2026-07-04 19:33 - Moved bash and zsh hook directories to `~/.config/<shell>/rc/<startup-file>.d/` while keeping managed blocks as dispatcher source pointers.
- [x] 2026-07-04 19:36 - Moved shell dispatcher files out of hook directories to `~/.config/<shell>/rc/<startup-file>.<shell>` so `*.d/` directories contain only numbered hooks.

## Unfinished Work

- [ ] Inventory current zsh, bash, git, and third-party mutation behavior before enabling these modules for a real user.
- [ ] Prototype one low-risk tool integration after the inventory is complete.
