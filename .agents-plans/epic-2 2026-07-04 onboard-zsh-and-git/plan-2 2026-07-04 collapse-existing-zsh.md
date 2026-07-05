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

- Existing product model: host-user app config lives under `hosts/nonlogicals-mbp/users/nonlogical/home/<program>/`; reusable unmanaged shell bridge modules live under `modules/home/programs/unmanaged/`.
- New requirement's real intent: let Home Manager own zsh behavior without losing the ability for Nix-oblivious tools to append to conventional top-level startup files.
- Cleanest integrated model: enable `programs.zsh` and native Home Manager integrations; use `programs.unmanaged.zsh` only as a bridge into Home Manager-generated files; keep custom code in small `cfg-*.nix` or `lib/*.zsh` files with clear ownership.
- Existing pieces that should move, change, or disappear: the staged `files/config/plugins/*.zsh` mirror should disappear as each semantic group is represented by Home Manager or a focused companion file.
- Architecture impact: zsh follows the Git pattern of a small `default.nix` plus `cfg-*` section files, but shell snippets should be smaller and more intentional than the old plugin tree.
- Why this is better than a local patch: it makes zsh startup understandable as Nix configuration instead of a numbered shell-file pipeline.

## Decisions

- Use Home Manager `programs.zsh` native options for history, shell options, completion, syntax highlighting, autosuggestions, history substring search, aliases, session variables, and startup-file extras where possible.
- Use Home Manager `programs.fzf`, `programs.direnv`, and `programs.zoxide` for those integrations instead of hand-written `eval "$(tool init zsh)"` snippets.
- Keep the custom `microprompt` prompt as a small companion file for now because it is bespoke behavior rather than a packaged zsh plugin.
- Keep custom functions and unusual key bindings as companion snippets initially, then continue shrinking them in later zsh slices.
- Remove staged files that become fully represented by Nix or focused companion snippets.
- Keep `path_list` as a small interactive utility, but do not keep custom path mutation helpers. Direct zsh `path=(...)` array edits are clear enough at the remaining call sites.

## Implementation Steps

1. [x] Fork plan 2 from the combined zsh/Git onboarding plan and make plan 1 Git-only.
2. [x] Inventory existing zsh plugin files and classify behavior by Home Manager coverage.
3. [x] Replace the review-only `home.file.".config/dotfiles-nix/staged/zsh"` module with an active Home Manager zsh profile.
4. [x] Move simple shell policy into `programs.zsh` options and `cfg-*.nix` sections.
5. [x] Replace package integrations with Home Manager modules where available.
6. [x] Keep only focused companion zsh files for custom prompt, functions, key bindings, and terminal-specific behavior.
7. [x] Remove staged Dotter mirror files whose behavior has been converted.
8. [x] Build/evaluate the Home Manager profile and run `nix flake check`.

## Learning Log

- The old zsh history behavior maps mostly to `programs.zsh.history`: large `size`/`save`, `path = "$HOME/.cache/zsh/history"`, `share = true`, `extended = true`, `ignoreSpace = true`, and `ignoreDups = true`.
- The old plugin list overlaps Home Manager-native integrations: `zsh-syntax-highlighting`, `zsh-history-substring-search`, `fzf`, `direnv`, and `zoxide`.
- The old Nix-specific fpath/helpdir/session variable behavior is already handled by Home Manager's zsh module when `programs.zsh.enable = true`.
- The old `~/.config/zsh/plugins/10-plug-bundle.zsh` mixes plugin manager bootstrapping, prompt selection, terminal detection, and tool integrations; it should be split by responsibility instead of copied.
- `programs.zsh.dotDir` should remain compatible with the unmanaged top-level bridge. The bridge should source Home Manager-owned files without hardcoding the user home path in reusable modules.
- The collapsed zsh profile uses an absolute `programs.zsh.dotDir` derived from `config.home.homeDirectory` to avoid Home Manager's relative-dotDir deprecation warning while still avoiding a hardcoded user path.
- `programs.unmanaged.zsh` successfully copies Home Manager's generated zsh file bodies into `~/.config/zsh/rc/<startup-file>.d/50-nix-managed.zsh` hooks and keeps conventional top-level zsh files mutable.
- The old `path_prepend`, `path_append`, and `path_drop` helpers were unnecessary after the collapse. The remaining path mutations are local and clearer as direct `path=( "$dir" ${path:#"$dir"} )` expressions.

## Work Log

- [x] 2026-07-04 22:31 - Renamed plan 1 to the Git-only plan and created this zsh-specific plan.
- [x] 2026-07-04 22:31 - Read the staged zsh plugin, hook, top-level, prompt, and extra files and mapped several behaviors to Home Manager options.
- [x] 2026-07-04 22:54 - Replaced the staged zsh mirror with a Home Manager profile using native zsh, fzf, direnv, zoxide, mise, bat, eza, syntax highlighting, history substring search, and packaged zsh plugins.
- [x] 2026-07-04 22:54 - Removed the copied Dotter zsh file tree and kept focused companion snippets under `home/zsh/lib/`.
- [x] 2026-07-04 22:54 - Verified generated zsh hook files with `zsh -n` and ran `nix flake check`.
- [x] 2026-07-04 22:48 - Removed custom path mutation helpers while keeping `path_list` available as an interactive utility.

## Unfinished Work

N/A
