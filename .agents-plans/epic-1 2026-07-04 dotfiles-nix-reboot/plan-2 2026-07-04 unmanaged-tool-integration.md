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
- Keep top-level managed shell blocks as pointers only. A managed block in `.zshenv`, `.zprofile`, `.zshrc`, `.zlogin`, `.zlogout`, `.bashrc`, or `.bash_profile` should source one generated dispatcher file and contain no hook iteration logic.
- Source shell hook directories from generated dispatcher files in lexical order so user-owned hooks such as `~/.config/zsh/rc/zshenv.d/99-conda.zsh` or `~/.config/bash/rc/bashrc.d/99-conda.bash` can extend or override the Nix-managed hook without editing the top-level startup file.
- Keep shell hook layout and shell-specific hook sourcing syntax in each shell module. The shared unmanaged-program helper owns only the native Home Manager conflict policy for tools that do not need native Home Manager as a content generator.
- Preserve Home Manager zsh behavior by enabling native `programs.zsh` as a content generator, reading the fully merged native generated zsh file bodies from `home.file`, copying those bodies into unmanaged zsh's numbered Nix hooks, and forcing the native startup-file links off. This captures Home Manager internals such as `fpath`, `HELPDIR`, completion setup, history, aliases, `hm-session-vars.sh`, zsh plugin frameworks, and snippets from unrelated Home Manager modules without allowing Home Manager to replace the mutable top-level zsh files.
- For zsh, the conflict is native Home Manager file ownership, not native `programs.zsh.enable` itself. Unmanaged zsh intentionally sets `programs.zsh.enable = mkDefault true` when `includeHomeManagerZshContent` is enabled, then disables the native `.zshenv`, `.zprofile`, `.zshrc`, `.zlogin`, and `.zlogout` home-file links.
- Assert the zsh generator/file-ownership boundary. If `includeHomeManagerZshContent` is enabled, `programs.zsh.enable` must remain enabled so Home Manager can generate complete zsh content; if `includeHomeManagerZshContent` is disabled, native `programs.zsh.enable` must not be enabled because Home Manager would own the conventional startup files directly.
- Preserve Home Manager bash behavior by enabling native `programs.bash` as a content generator, mirroring the native generated file bodies into unmanaged bash's numbered Nix hooks, and forcing the native `.bash_profile`, `.profile`, `.bashrc`, and `.bash_logout` home-file links off. This keeps `hm-session-vars.sh`, completion, history settings, shell options, aliases, logout content, and integrations from other Home Manager modules without letting Home Manager replace the mutable top-level bash files.
- For bash, nested startup sourcing means the generated dispatcher must isolate its scratch variables. `.bash_profile` normally sources `.profile` and `.bashrc`; each dispatcher therefore wraps hook iteration in a short function with local variables so nested dispatchers do not clobber each other.
- Assert the bash generator/file-ownership boundary. If `includeHomeManagerBashContent` is enabled, `programs.bash.enable` must remain enabled so Home Manager can generate complete bash content; if `includeHomeManagerBashContent` is disabled, native `programs.bash.enable` must not be enabled because Home Manager would own conventional bash startup files directly.
- Preserve Home Manager Git behavior by enabling native `programs.git` as a content generator, copying the native generated `xdg.configFile."git/config".text` into `~/.config/dotfiles-nix/git/config`, and forcing only the native `~/.config/git/config` link off. Other native Git side effects such as the Git package, global ignore file, attributes file, hooks path, and maintenance integration can still be used.
- Assert the Git generator/file-ownership boundary. If `includeHomeManagerGitContent` is enabled, `programs.git.enable` must remain enabled so Home Manager can generate complete Git config; if `includeHomeManagerGitContent` is disabled, native `programs.git.enable` must not be enabled because Home Manager would own `~/.config/git/config` directly.
- Default native Home Manager program policy should be `forbid`, not silent `mkForce false`, for unmanaged tools where the native module would compete with the unmanaged module rather than serving as a content generator.
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
3. [x] Sketch `programs.unmanaged.zsh` with separate entries for `.zshenv`, `.zprofile`, `.zshrc`, `.zlogin`, and `.zlogout`.
4. [x] Sketch `programs.unmanaged.git` for a managed include block in either `~/.gitconfig` or `~/.config/git/config`.
5. [x] Define generator/file-ownership assertions for bash, zsh, and git so native Home Manager modules can generate content without owning the mutable top-level files.
6. [ ] Prototype one low-risk tool integration after the Dotter inventory is complete.

## Learning Log

- `programs.unmanaged.<tool>` means the conventional top-level files are unmanaged/mutable, not that Nix does nothing.
- The Nix-owned object is the managed block and the managed fragment, not necessarily the full top-level file.
- The conflict with native Home Manager modules should be loud by default when the native module competes for the same ownership boundary. Zsh is the exception in this slice: unmanaged zsh needs native Home Manager zsh to generate the complete content, then suppresses only native startup-file links.
- For zsh, model each startup and shutdown file separately:
	- `.zshenv`: tiny, always sourced, no interactive assumptions.
	- `.zprofile`: login-shell setup.
	- `.zshrc`: interactive shell setup.
	- `.zlogin`: login-shell commands that should run after `.zprofile`.
	- `.zlogout`: login-shell cleanup commands that should run when the shell exits.
- For git, a managed block in `~/.gitconfig` or `~/.config/git/config` can include the Nix-managed fragment while preserving arbitrary top-level changes.
- For bash and zsh startup files, append placement is too late for the migration use case. The managed source block should be inserted after only the leading preamble, so ordered hook directories can affect the rest of `.bashrc`, `.bash_profile`, `.zshenv`, `.zprofile`, `.zshrc`, `.zlogin`, and `.zlogout`.
- For bash and zsh, the Nix-owned hook defaults to `50-nix-managed.<shell>` inside `~/.config/<shell>/rc/<startup-file>.d/`. Lower numbers can prepare state before Nix; higher numbers can extend or override Nix-managed setup.
- For bash and zsh, generated dispatcher files live at `~/.config/<shell>/rc/<startup-file>.<shell>`, next to but not inside the startup-file-specific hook directory. Dispatchers source only sibling hooks matching `[0-9][0-9]-*.<shell>` from `~/.config/<shell>/rc/<startup-file>.d/`.
- `lib/home/unmanaged-program.nix` should not know shell hook layout or individual shell semantics. Bash hook paths, `shopt -s nullglob`, and `50-nix-managed.bash` live in `modules/home/programs/unmanaged/bash.nix`; zsh hook paths, `(N)` glob qualifiers, and `50-nix-managed.zsh` live in `modules/home/programs/unmanaged/zsh.nix`.
- Home Manager's `programs.zsh` option namespace is not enough by itself. Home Manager's native zsh module contributes important generated content only when `programs.zsh.enable` is true, including `typeset -U path cdpath fpath manpath`, `fpath` additions from `NIX_PROFILES`, `HELPDIR`, completion initialization, history setup, shell options, aliases, and plugin-framework content.
- Home Manager session variables are generated into `config.home.sessionVariablesPackage` as `etc/profile.d/hm-session-vars.sh`. Native Home Manager zsh places this in `.zshenv` for non-login shells and `.zprofile` for login shells; unmanaged zsh preserves that by copying the native generated file bodies into its own hooks.
- Home Manager's native bash module writes fixed top-level file bodies for `.bash_profile`, `.profile`, `.bashrc`, and `.bash_logout`. Unmanaged bash mirrors those formulas after `programs.bash` options have merged, then writes the result into `50-nix-managed.bash` hooks.
- The user's ambient `/bin/bash` may be older than the Home Manager-provided bash package. Runtime validation should use the generated profile's `home-path/bin/bash`; native Home Manager bash content may use shell options or conditions that are not valid in Apple's old system bash.
- For Git config, a near-top include is safer than an appended include because it makes the managed fragment behave like defaults. Existing top-level settings that appear later in `~/.gitconfig` or `~/.config/git/config` continue to win.
- Home Manager's native Git module already produces the exact merged text we need at `xdg.configFile."git/config".text`. Unmanaged Git can reuse that text directly, then disable only the native file link so activation can manage a near-top include in the mutable global config.
- Git validation should use `git config --global --includes`, because plain `git config --global` does not expand includes for reads. In the disposable test home, the near-top managed include provided Home Manager defaults, while later mutable top-level values still won for keys such as `user.name` and `core.editor`.
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
- [x] 2026-07-04 19:40 - Added unmanaged zsh coverage for `.zlogin` and `.zlogout` using the same dispatcher and numbered-hook layout as the existing zsh startup files.
- [x] 2026-07-04 19:43 - Added a Home Manager zsh content bridge so unmanaged zsh hooks include merged `programs.zsh` snippets from other Home Manager modules without enabling native zsh file ownership by default.
- [x] 2026-07-04 19:50 - Added unmanaged zsh session-variable sourcing so `.zshenv` and `.zprofile` hooks source Home Manager's generated `hm-session-vars.sh` in the same non-login/login split as native Home Manager zsh.
- [x] 2026-07-04 19:56 - Replaced the partial zsh option-text bridge with native Home Manager zsh content generation: unmanaged zsh now enables native zsh by default, reads the merged generated zsh startup-file bodies, writes them into `50-nix-managed.zsh` hooks, and disables only the native startup-file links.
- [x] 2026-07-04 19:57 - Added assertions for unmanaged zsh's generator mode so invalid combinations fail during evaluation instead of conflicting during activation.
- [x] 2026-07-04 20:09 - Reworked unmanaged bash to use native Home Manager bash as a content generator, covering `.bash_profile`, `.profile`, `.bashrc`, and `.bash_logout` while keeping the top-level files mutable and dispatcher-only.
- [x] 2026-07-04 20:16 - Reworked unmanaged Git to use native Home Manager Git as a content generator, copy the generated config into `~/.config/dotfiles-nix/git/config`, and force off only the native `~/.config/git/config` link.
- [x] 2026-07-04 20:19 - Validated the disposable profile with lived-in bash and Git fixtures: Home Manager bash content, shell hooks, logout order, Git includes, repeated credential helpers, native ignore/attributes files, and later mutable Git overrides all behaved as expected.

## Unfinished Work

- [ ] Inventory current zsh, bash, git, and third-party mutation behavior before enabling these modules for a real user.
- [ ] Prototype one low-risk tool integration after the inventory is complete.
