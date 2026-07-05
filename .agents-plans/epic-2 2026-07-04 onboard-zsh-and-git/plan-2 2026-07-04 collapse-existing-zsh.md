---
date: 2026-07-04
status: complete
subject: collapse-existing-zsh
---

# Collapse Existing Zsh

## Goal

Aggressively collapse the current Dotter-era zsh configuration into idiomatic Home Manager and small Nix-owned companion files.

The target is not an exact copy of `~/.config/zsh`. The old files are behavioral evidence. Prefer Home Manager options for history, completion, plugins, aliases, paths, environment variables, and integrations. Keep shell snippets only when they encode genuinely custom behavior that Home Manager does not model.

## Context

The existing zsh setup was staged under `hosts/nonlogicals-mbp/users/nonlogical/home/zsh/files/` during inventory. It currently mirrors the old layout:

- top-level zsh files: `zshenv`, `zprofile`, `zshrc`, `zlogin`, and `zlogout`
- hook loader files under `files/config/hooks/`
- numbered plugin files under `files/config/plugins/`
- extras and prompt files under `files/config/plugins/extras/` and `files/config/themes/`

The old `zshrc` flow sources every plugin file from `~/.config/zsh/plugins/*.zsh`. That preserves Dotter-era ordering but hides which behavior is core shell policy, which behavior is package/plugin integration, and which behavior is custom local code. This plan owns replacing that with readable Nix sections.

## Product Integration

- Existing product model: host-user app config began under `hosts/nonlogicals-mbp/users/nonlogical/home/<program>/`; reusable unmanaged shell bridge modules now live under `modules/home/pkgUnmanagedBash.nix` and `modules/home/pkgUnmanagedZsh.nix`.
- New requirement's real intent: let Home Manager own zsh behavior without losing the ability for Nix-oblivious tools to append to conventional top-level startup files.
- Cleanest integrated model: enable `programs.zsh` and native Home Manager integrations; use `programs.unmanaged.zsh` only as a bridge into Home Manager-generated files; keep custom code in small `cfg-*.nix` or `lib/*.zsh` files with clear ownership.
- Existing pieces that should move, change, or disappear: the staged `files/config/plugins/*.zsh` mirror should disappear as each semantic group is represented by Home Manager or a focused companion file.
- Architecture impact: zsh follows the Git pattern of a small `default.nix` plus `cfg-*` section files, but shell snippets should be smaller and more intentional than the old plugin tree.
- Why this is better than a local patch: it makes zsh startup understandable as Nix configuration instead of a numbered shell-file pipeline.

## Decisions

- Use Home Manager `programs.zsh` native options for history, shell options, completion, syntax highlighting, autosuggestions, history substring search, aliases, session variables, and startup-file extras where possible.
- Use Home Manager `programs.fzf`, `programs.direnv`, and `programs.zoxide` for those integrations instead of hand-written `eval "$(tool init zsh)"` snippets.
- Keep the custom `microprompt` prompt as a Home Manager `programs.zsh.siteFunctions` entry. Home Manager writes `prompt_microprompt_setup` into `share/zsh/site-functions`, which is already on `fpath`; prompt selection is a small Nix-owned `initContent` block that runs zsh's native `promptinit`/`prompt microprompt` flow.
- Keep custom functions and unusual key bindings as companion snippets initially, then continue shrinking them in later zsh slices.
- Remove staged files that become fully represented by Nix or focused companion snippets.
- Keep `path_list` as a small interactive utility, but do not keep custom path mutation helpers. Direct zsh `path=(...)` array edits are clear enough at the remaining call sites.
- Keep companion zsh files grouped by runtime responsibility. Files concatenated into `programs.zsh.initContent` are named `init-<name>.zsh`; zsh prompt functions and other autoloaded assets live under `lib/functions/` instead of using the init-fragment naming scheme.
- Keep `shZsh/lib` strict: startup fragments stay only when they must execute during shell startup, reusable commands and prompt themes use Home Manager `programs.zsh.siteFunctions`, and general session state moves to Home Manager session variables or session paths. Autoloaded function sources are split by role under `lib/functions/utils/` and `lib/functions/prompts/`; `shZsh/default.nix` uses `lib.filesystem.listFilesRecursive` over `lib/functions/` instead of listing every function file manually.
- Use Home Manager `programs.vivid` for GNU-style `LS_COLORS` instead of keeping a handcrafted color database in a shell snippet.
- Use Home Manager `programs.less` for pager options; do not keep `LESS`, `LESS_TERMCAP_*`, `LS_COLORS`, or `LSCOLORS` as hand-written zsh color defaults.
- Keep companion zsh files as source files for readability, but concatenate their contents with Nix before passing them to `programs.zsh.initContent`; do not generate a zshrc that sources private companion files from the Nix store.
- Keep `home.sessionPath` limited to general user bin directories; do not add app-specific or plugin-manager paths such as `.lmstudio/bin` or `.krew/bin` implicitly.
- Store host-user shell configuration under `hosts/nonlogicals-mbp/users/nonlogical/home/shell/`; keep zsh-specific implementation under `shell/shZsh/` so normal `cfg-*.nix` section names remain unambiguous inside the zsh boundary.
- Keep a clean split between shell-adjacent tools and zsh implementation. `home/shell/default.nix` enables tools such as fzf, direnv, zoxide, mise, bat, less, eza, vivid, general user bin paths, and zsh integration toggles for those shell-suite tools. `home/shell/shZsh/default.nix` owns zsh startup content, zsh plugins, and zsh-only packages.
- Keep zsh startup-file extras as zsh files under `shZsh/lib/rc-<name>-extra.zsh`; `default.nix` should wire them with `builtins.readFile` instead of embedding multi-line rc bodies inline.
- Keep editor selection declarative in zsh session variables; do not probe for `nvim`, `vim`, or `vi` during shell startup.
- Keep zsh integration toggles for shell-suite programs in the parent shell suite, but write them as conventional explicit `programs.<tool>` option blocks. Avoid generated attrs and `mkMerge` when the configuration is just a small host-user profile.
- Keep session variables in the parent shell suite, not in `shZsh`; values such as locale, grep colors, and editor defaults are shell profile state rather than zsh-specific configuration.

## Implementation Steps

1. [x] Fork plan 2 from the combined zsh/Git onboarding plan and make plan 1 Git-only.
2. [x] Inventory existing zsh plugin files and classify behavior by Home Manager coverage.
3. [x] Replace the review-only `home.file.".config/dotfiles-nix/staged/zsh"` module with an active Home Manager zsh profile.
4. [x] Move simple shell policy into `programs.zsh` options and `cfg-*.nix` sections.
5. [x] Replace package integrations with Home Manager modules where available.
6. [x] Keep only focused companion zsh files for custom prompt activation, functions, key bindings, and terminal-specific behavior.
7. [x] Remove staged Dotter mirror files whose behavior has been converted.
8. [x] Build/evaluate the Home Manager profile and run `nix flake check`.
9. [x] Combine remaining companion zsh snippets into a smaller set of logically named `<namespace>-<name>.zsh` files.
10. [x] Replace hardcoded `LS_COLORS` with a Home Manager-owned vivid palette.
11. [x] Rebuild/evaluate the Home Manager profile and run `nix flake check`.
12. [x] Replace the runtime `sourceZshLib` helper with explicit Nix fragment lists and `builtins.readFile`.
13. [x] Move zsh implementation under `home/shell/shZsh` and keep `home/shell/default.nix` as the light shell suite module.
14. [x] Audit old zsh startup extras and keep only snippets with clear zsh-runtime ownership.
15. [x] Move editor defaults out of shell startup logic and into zsh session variables.
16. [x] Keep shell-suite zsh integration assignments in explicit conventional program blocks under `home/shell/default.nix`.
17. [x] Move session variables from `shZsh` to the parent `shell` suite and wire them through `home.sessionVariables`.
18. [x] Move `microprompt` from an inline init fragment to a zsh site function exposed through Home Manager `programs.zsh.siteFunctions`.
19. [x] Rename all zsh files concatenated into `initContent` to `init-<name>.zsh`.
20. [x] Audit `shZsh/lib` and move or remove files that do not have a strong zsh-runtime ownership argument.
21. [x] Clean up `shZsh/default.nix` so the Home Manager module reads like conventional Nix instead of an accumulated migration sketch.

## Learning Log

- The old zsh history behavior maps mostly to `programs.zsh.history`: large `size`/`save`, `path = "$HOME/.cache/zsh/history"`, `share = true`, `extended = true`, `ignoreSpace = true`, and `ignoreDups = true`.
- The old plugin list overlaps Home Manager-native integrations: `zsh-syntax-highlighting`, `zsh-history-substring-search`, `fzf`, `direnv`, and `zoxide`.
- The old Nix-specific fpath/helpdir/session variable behavior is already handled by Home Manager's zsh module when `programs.zsh.enable = true`.
- The old `~/.config/zsh/plugins/10-plug-bundle.zsh` mixes plugin manager bootstrapping, prompt selection, terminal detection, and tool integrations; it should be split by responsibility instead of copied.
- `programs.zsh.dotDir` should remain compatible with the unmanaged top-level bridge. The bridge should source Home Manager-owned files without hardcoding the user home path in reusable modules.
- The collapsed zsh profile uses an absolute `programs.zsh.dotDir` derived from `config.home.homeDirectory` to avoid Home Manager's relative-dotDir deprecation warning while still avoiding a hardcoded user path.
- `programs.unmanaged.zsh` successfully copies Home Manager's generated zsh file bodies into `~/.config/zsh/rc/<startup-file>.d/50-nix-managed.zsh` hooks and keeps conventional top-level zsh files mutable.
- The old `path_prepend`, `path_append`, and `path_drop` helpers were unnecessary after the collapse. The remaining path mutations are local and clearer as direct `path=( "$dir" ${path:#"$dir"} )` expressions.
- The remaining init companion zsh snippets should group by concern rather than by original Dotter file boundaries: shell helpers, completion policy, terminal UI, ZLE/keymap behavior, prompt activation, and external integrations.
- Home Manager's `programs.vivid` can generate `LS_COLORS` for zsh, but completion color styles should read `LS_COLORS` lazily with `zstyle -e` so they do not depend on the exact init ordering of the vivid integration.
- `LSCOLORS` is not needed in the zsh profile while `ls` is aliased to `eza`; if BSD `ls` color behavior becomes necessary later, add it as an explicit macOS compatibility decision rather than a leftover default.
- The zsh init companion files are now Nix inputs rather than runtime dependencies: `default.nix` groups `init-<name>.zsh` paths by init phase and uses `builtins.readFile` to produce the final Home Manager `initContent`.
- `microprompt` is no longer an init fragment or a fake zsh plugin. Home Manager's `programs.zsh.siteFunctions` writes `prompt_microprompt_setup` into `share/zsh/site-functions`, and prompt selection is a small Nix-owned `initContent` block in `shZsh/default.nix`.
- `microprompt` follows zsh prompt theme conventions: the autoloaded file is named `prompt_microprompt_setup`, it defines and calls `prompt_microprompt_setup "$@"`, it sets `prompt_opts` for prompt options, and its hook functions are named `prompt_microprompt_preexec` and `prompt_microprompt_precmd` so `promptinit` can remove them when switching themes.
- Generic helper commands such as `path-ls`, `cdf`, `ip-wan`, `refresh`, and the guarded `rm` wrapper should not be concatenated into zsh startup. They now live under `lib/functions/utils/` and are exposed through `programs.zsh.siteFunctions`, so zsh autoloads them on first use. Prompt theme functions live under `lib/functions/prompts/`.
- `shZsh/default.nix` should keep Home Manager ordering explicit with named anchors. The relevant generated zshrc anchors are plugin paths at order `560`, `compinit` at `570`, plugin sources at `900`, aliases at `1100`, syntax highlighting at `1200`, and history finalization at `1250`.
- `zsh-completions` should be owned as a `programs.zsh.plugins` entry, not also installed directly through `home.packages`; the plugin entry already adds the completion source tree to zsh's plugin/fpath handling.
- The old `/opt/homebrew/bin/brew shellenv` profile hook does not belong in `shZsh/lib/rc-profile-extra.zsh`. It is a machine-local Homebrew bridge, not zsh-specific behavior; if Homebrew environment management is needed later, model it explicitly in the Darwin or broader shell layer.
- General session defaults such as `PAGER`, `PLATFORM`, user bin paths, and `/usr/local` paths belong in the parent shell Home Manager config, not zsh rc snippets. Zsh-specific cache state belongs in `programs.zsh.sessionVariables`.
- The login fortune and logout quote snippets were removed. They were nostalgic shell behavior, but they did not have a strong ownership argument in the Nix-managed zsh profile.
- Zsh aliases should be a small intentional layer, not a dumped compatibility list. Drop old `nocorrect`/`noglob` wrappers and aliases without clear current ownership, and comment each remaining alias in `cfg-aliases.nix`.
- Cross-platform shell commands belong in the parent shell suite, not in zsh startup. The `opn` wrapper provides a visible `open`/`xdg-open`/`gio open` compatibility command, lives as a real Blueprint package under `packages/opn/default.nix`, and zsh only keeps `o = "opn"` as a convenience alias.
- `opn` should choose the platform opener at Nix evaluation time with `pkgs.stdenv.hostPlatform`, not by probing `uname` at runtime. Darwin builds a wrapper around `/usr/bin/open`; Linux builds a wrapper around `${pkgs.xdg-utils}/bin/xdg-open`.
- Shell Nix files should carry enough intent comments for a future reader to recover why each section exists. Prefer comments about ownership boundaries, migration decisions, and why behavior is modeled in Home Manager instead of repeating what each assignment syntactically does.
- Python user-bin, Cargo, Homebrew, and similar Nix-oblivious toolchain bridges are deferred. They should be designed as explicit shell or system integration slices later instead of being hidden in zsh startup by default.
- The host-user shell folder is intentionally broader than zsh. Zsh-specific files live under `shZsh`, so `cfg-aliases.nix`, `cfg-options.nix`, `cfg-plugins.nix`, and `cfg-session-variables.nix` are clear without a redundant `cfg-zsh-` prefix.
- Non-zsh shell tools are enabled in the shell suite module. Their zsh integration flags also live in the parent shell suite because they are options on the tool modules themselves; `shZsh` only owns zsh startup content, zsh plugins, and zsh-only packages.
- Zsh rc extra bodies live in zsh source files so shell syntax remains syntax-highlighted and parse-checkable. The Nix module now references those files rather than carrying large inline strings.
- Editor defaults are declarative session variables now: `PREFERRED_EDITOR`, `EDITOR`, and `VISUAL` are set to `nvim`. This removes dynamic command probing from zsh startup.
- Zsh integrations for fzf, direnv, zoxide, mise, and vivid live in explicit `programs.<tool>` blocks in the parent shell suite. This is more conventional than generating attrs from a one-off list, and `eza` remains an explicit exception because the profile owns `ls`/`ll`/`la` aliases directly.
- Session variables now live at `home/shell/cfg-session-variables.nix` and are assigned to `home.sessionVariables`; unmanaged zsh still receives them through Home Manager's generated `hm-session-vars.sh`.

## Work Log

- [x] 2026-07-04 22:31 - Renamed plan 1 to the Git-only plan and created this zsh-specific plan.
- [x] 2026-07-04 22:31 - Read the staged zsh plugin, hook, top-level, prompt, and extra files and mapped several behaviors to Home Manager options.
- [x] 2026-07-04 22:54 - Replaced the staged zsh mirror with a Home Manager profile using native zsh, fzf, direnv, zoxide, mise, bat, eza, syntax highlighting, history substring search, and packaged zsh plugins.
- [x] 2026-07-04 22:54 - Removed the copied Dotter zsh file tree and kept focused companion snippets under `home/zsh/lib/`.
- [x] 2026-07-04 22:54 - Verified generated zsh hook files with `zsh -n` and ran `nix flake check`.
- [x] 2026-07-04 22:48 - Removed custom path mutation helpers while keeping `path_list` available as an interactive utility.
- [x] 2026-07-04 22:55 - Reopened the zsh plan to capture the companion-file grouping cleanup.
- [x] 2026-07-04 23:00 - Replaced manual `LS_COLORS` shell export with Home Manager `programs.vivid` and lazy completion color lookup.
- [x] 2026-07-04 23:02 - Removed the remaining terminal color defaults from zsh snippets and moved pager options to `programs.less`.
- [x] 2026-07-04 23:04 - Verified source zsh snippets, generated Home Manager zsh hooks, activation package build, and `nix flake check`.
- [x] 2026-07-04 23:06 - Replaced the runtime zsh source helper with explicit Nix fragment lists and `builtins.readFile`.
- [x] 2026-07-04 23:07 - Verified the Nix-inlined zsh fragments with source parse checks, generated hook parse checks, activation package build, and `nix flake check`.
- [x] 2026-07-04 23:08 - Removed app-specific `.lmstudio/bin` and `.krew/bin` path additions from the zsh profile.
- [x] 2026-07-04 23:09 - Verified no generated `.lmstudio` or `.krew` references remain; generated zsh hooks parse and `nix flake check` passes.
- [x] 2026-07-04 23:11 - Renamed the host-user zsh config folder to `home/shell/shZsh` and kept zsh section files as normal `cfg-*.nix` files inside that zsh-specific directory.
- [x] 2026-07-04 23:11 - Moved zsh implementation into `home/shell/shZsh` and created a light `home/shell/default.nix` for non-zsh shell-adjacent tools.
- [x] 2026-07-04 23:12 - Moved zsh rc extra bodies into `shZsh/lib/rc-<name>-extra.zsh` files.
- [x] 2026-07-04 23:17 - Verified the shell/shZsh split and rc extra extraction with source zsh parse checks, Home Manager activation build, generated hook parse checks, generated hook inspection, and `nix flake check`.
- [x] 2026-07-04 23:21 - Moved editor defaults to zsh session variables and removed dynamic editor probing from shell integrations.
- [x] 2026-07-04 23:22 - Verified generated zsh hooks export editor variables from Home Manager session variables; source hooks parse and `nix flake check` passes.
- [x] 2026-07-04 23:24 - Replaced repeated zsh integration assignments with `zshIntegratedPrograms` and an explicit `eza` exception.
- [x] 2026-07-04 23:25 - Moved session variables from `shZsh` to parent `shell` and wired them through `home.sessionVariables`.
- [x] 2026-07-04 23:26 - Moved shell-suite `enableZshIntegration` policy from `shZsh` up to `shell/default.nix`.
- [x] 2026-07-04 23:27 - Verified generated zsh integrations still include fzf, direnv, zoxide, mise, and vivid while eza remains alias-only; source hooks parse and `nix flake check` passes.
- [x] 2026-07-04 23:28 - Replaced the generated `zshIntegratedPrograms`/`mkMerge` shape in `home/shell/default.nix` with explicit conventional program option blocks.
- [x] 2026-07-04 23:35 - Moved `microprompt` out of inline init content and renamed init fragments to `init-<name>.zsh`.
- [x] 2026-07-04 23:38 - Verified renamed init fragments, generated zsh hooks, microprompt autoload behavior, activation package build, formatting, and `nix flake check`.
- [x] 2026-07-04 23:42 - Removed fake function-only zsh plugin files and `file = "no-plugin-file.zsh"` sentinel values; Home Manager now adds only the needed `functions` paths and skips absent default plugin files.
- [x] 2026-07-04 23:45 - Aligned `microprompt` with zsh prompt theme conventions and verified prompt loading, hook cleanup, generated zsh hooks, activation package build, formatting, and `nix flake check`.
- [x] 2026-07-04 23:50 - Replaced the temporary local zsh plugin wrapper with `programs.zsh.siteFunctions` and moved prompt theme selection into `cfg-prompt.nix`.
- [x] 2026-07-04 23:58 - Audited `shZsh/lib`, moved generic helper commands to `siteFunctions`, moved general session defaults to Home Manager variables/paths, removed login/logout frills, renamed unmanaged toolchain startup, and verified with source checks, generated hook checks, activation build, and `nix flake check`.
- [x] 2026-07-05 00:03 - Split autoloaded functions into `lib/functions/utils/` and `lib/functions/prompts/`, moved the directory scan and prompt selection into `shZsh/default.nix`, and removed the narrow `cfg-functions.nix` and `cfg-prompt.nix` files.
- [x] 2026-07-05 00:03 - Replaced the hand-rolled `builtins.readDir` helper with nixpkgs `lib.filesystem.listFilesRecursive` for collecting zsh site-function source files.
- [x] 2026-07-05 00:12 - Cleaned up `shZsh/default.nix` with direct Home Manager option assignments, named init order anchors, clearer local function collection, `completionInit` in `lib/completion-init.zsh`, and no duplicate direct `zsh-completions` package install; verified zsh snippets, generated rc files, activation build, and `nix flake check`.
- [x] 2026-07-05 00:13 - Removed `shZsh/lib/rc-profile-extra.zsh` and the `programs.zsh.profileExtra` hook because it only ran `/opt/homebrew/bin/brew shellenv`; verified generated zprofile still sources Home Manager session variables and `nix flake check` passes.
- [x] 2026-07-05 00:17 - Removed the `init-unmanaged-toolchains.zsh` zsh startup hook for Python user-bin and Cargo. These unmanaged toolchain bridges are deferred until their ownership boundary is designed deliberately.
- [x] 2026-07-05 00:22 - Trimmed `cfg-aliases.nix` to a commented, intentional set of daily aliases and removed legacy `nocorrect`/`noglob`, tmux clipboard, top sorting, `sman`, and `rm -i` aliases; verified generated aliases and `nix flake check`.
- [x] 2026-07-05 00:26 - Added `opn` as a parent shell-suite wrapper around macOS `open`, Linux `xdg-open`, and Linux `gio open`; changed the zsh `o` alias to call `opn` and verified the generated profile plus `nix flake check`.
- [x] 2026-07-05 00:33 - Promoted `opn` from an inline `writeShellApplication` in `home/shell/default.nix` to a proper Blueprint package at `packages/opn/default.nix`; verified `packages.aarch64-darwin.opn`, `checks.aarch64-darwin.pkgs-opn`, Home Manager activation, generated zsh aliases, and `nix flake check`.
- [x] 2026-07-05 00:33 - Added future-reader comments to every Nix file under `hosts/nonlogicals-mbp/users/nonlogical/home/shell`, covering parent shell ownership, session variables, zsh generation, aliases, shell options, and zsh plugins.
- [x] 2026-07-05 00:36 - Simplified `opn` to select `/usr/bin/open` or `xdg-open` at Nix evaluation time using `pkgs.stdenv.hostPlatform`; verified generated Darwin wrapper has no runtime OS probing and `nix flake check` passes.

## Unfinished Work

N/A
