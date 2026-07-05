---
date: 2026-07-05
status: in-progress
subject: migrate-neovim-to-nix
---

## Goal

Move the active Neovim configuration from Dotter-managed `~/.config/nvim` into this Nix/Home Manager repository without preserving the old file layout for its own sake. The migration should capture the useful editing behavior and use Nix for Neovim package, plugin, language server, formatter, and tool management wherever practical.

## Context

The active Neovim config is a symlink from `~/.config/nvim` to `/Users/nonlogical/.config/dotter/common/nvim/.config/nvim.xlink`. That tree contains a Lua-based Lazy.nvim setup with 46 files, including `init.lua`, `lua/config/*`, many `lua/plugins/<category>__<plugin>.lua` specs, `lsp/*.lua`, one Python ftplugin, a custom `colors/ao.vim`, and `lazy-lock.json`.

This plan intentionally excludes the deprecated Vim/Neovim hybrid tree under `/Users/nonlogical/.config/dotter/__deprecated/vim/nvim.xlink` unless a later inventory finds a still-needed behavior that is missing from the active config.

Prior migration rules still apply:

- Treat Dotter files as behavioral source material, not target structure.
- Assume Home Manager activates onto clean target paths; existing Dotter symlinks are cleanup chores, not compatibility logic to encode in Nix.
- Use `hosts/nonlogicals-mbp/users/nonlogical/home/<program>/default.nix` when a host-user app profile needs companion files.
- Keep package management in Nix instead of letting Neovim download package managers, language servers, or CLI tools at runtime.
- Prefer idiomatic Home Manager options and Nix package lists over large pasted Lua strings, but keep small Lua companion files when they are the clearest way to express editor behavior.

## Product Integration

- Existing product model: host-user applications live under `hosts/nonlogicals-mbp/users/nonlogical/home/`; Nix packages and Home Manager options own installed programs; companion files are used when an application needs native config files.
- New requirement's real intent: keep Neovim feeling like the existing editor while replacing ad-hoc Lazy.nvim/Mason runtime installation with declarative Nix-managed packages.
- Cleanest integrated model: create a `home/neovim/` profile that enables Home Manager's Neovim module, installs the chosen plugins/tools through Nix, and renders a smaller Lua config that describes behavior rather than old plugin-manager structure.
- Existing pieces that should move, change, or disappear: Lazy.nvim bootstrap and lockfile should disappear from the target shape if Nix manages plugins. Mason should not install language servers; Nix should provide them. Old `lua/plugins/<category>__<plugin>.lua` filenames are inventory labels, not target modules.
- Architecture impact: this plan will add a `home/neovim/` directory and import it from `home-configuration.nix`. It may add package/tool dependencies to that profile, but it should not add broad common editor packages elsewhere.
- Why this is better than a local patch: it avoids replacing a Dotter symlink with a Nix symlink to the same Lazy.nvim tree, and it makes the editor reproducible through the same profile-management model as the rest of the repo.

## Decisions

- Start with an inventory of active Neovim behavior and dependencies before writing the target Home Manager module.
- Do not migrate `lazy-lock.json` as an authority. Nix inputs and nixpkgs plugin packages become the package authority.
- Do not keep Lazy.nvim bootstrap in the target unless a specific plugin cannot reasonably be managed by Nix in this slice.
- Do not use Mason as a package manager. Language servers, formatters, debuggers, and tree-sitter grammars should be installed via Nix when included.
- Keep the first implementation slice small enough to build and smoke-test with `nvim --headless`; defer lower-value or uncertain plugins instead of porting all 46 files at once.
- Use NixVim as the Neovim module layer. The first NixVim pass should preserve the current Nix-managed plugin inventory through `programs.nixvim.extraPlugins`, then later slices can promote individual plugins to native NixVim module options when that improves clarity.

## Implementation Steps

1. [x] Inventory the active Dotter Neovim config: options, keymaps, autocommands, plugins, LSP servers, completion sources, tree-sitter languages, external commands, and custom files.
2. [x] Classify each plugin and external tool as Nix-managed now, deferred, dropped, or requiring a small Lua companion config.
3. [x] Create `hosts/nonlogicals-mbp/users/nonlogical/home/neovim/` with a Home Manager Neovim profile and minimal companion files.
4. [x] Wire the profile through `hosts/nonlogicals-mbp/users/nonlogical/home-configuration.nix`.
5. [x] Build the Home Manager activation package and inspect generated Neovim files and package paths.
6. [x] Smoke-test Neovim headlessly enough to catch Lua load errors and missing plugin/tool references.
7. [x] Update this plan with cleanup notes for the existing `~/.config/nvim` Dotter symlink before activation.
8. [x] Replace the generic Home Manager `programs.neovim` wrapper with NixVim's Home Manager module while preserving the first-slice behavior.
9. [x] Split plugin enablement and plugin-specific configuration into `modules/home/suites/developer-base/neovim/plugins/<namespace>__<plugin>.nix`, following the active Dotter Neovim config's namespace grouping.
10. [x] Validate the NixVim-backed profile with activation build, generated config inspection, headless Neovim smoke checks, synthetic Linux eval, and `nix flake check`.

## Learning Log

- Active Neovim config lives at `/Users/nonlogical/.config/dotter/common/nvim/.config/nvim.xlink`; `~/.config/nvim` is currently a symlink to that directory.
- The active config is already a modern Lua/Lazy.nvim setup. The target migration should preserve editor behavior, not the old plugin-manager architecture.
- Existing-machine cleanup before activating the migrated Neovim profile: remove the Dotter-owned `~/.config/nvim` symlink so Home Manager can own the clean target path.
- The first slice used Home Manager's generic `programs.neovim` module, but the current target uses NixVim's `programs.nixvim` module for the editor package, aliases, providers, plugin inventory, generated Lua, and external tools.
- The first Nix-managed plugin set includes treesitter parsers, completion/snippets, LSP helpers, Telescope, tree explorer, git signs, statusline/bufferline, terminal, Trouble, Flash, OSC52, and core editing helpers. `gopls`, `lua-language-server`, `ripgrep`, `fd`, and `stylua` are installed through `programs.nixvim.extraPackages` or NixVim LSP server modules so Neovim sees them on its wrapper `PATH`.
- `vim-jinja` and `vim-polyglot` were deferred because the pinned nixpkgs marks them unfree. `bookmarks.nvim` and `nvim-aider` were deferred because they were not available in the pinned nixpkgs plugin set during this slice.
- The old generic Home Manager wrapper required explicit `packpath`/`runtimepath` wiring through `pkgs.vimUtils.packDir`. NixVim replaces that workaround by generating the plugin pack wiring itself from `programs.nixvim.plugins.*` and `programs.nixvim.extraPlugins`.
- NixVim is now the desired module layer because it can generate Neovim Lua from Nix modules while still allowing raw Lua through `extraConfigLua` and non-module plugins through `extraPlugins`.
- The NixVim-backed profile imports `inputs.nixvim.homeModules.nixvim`, sets `programs.nixvim`, and pins `programs.nixvim.nixpkgs.source = pkgs.path` because the flake intentionally follows this repo's `nixpkgs`.
- Plugin-specific behavior now lives under `modules/home/suites/developer-base/neovim/plugins/<namespace>__<plugin>.nix`, using the same namespace grouping idea as the source files such as `editing__luasnip.lua`, `lsp__nvim-cmp.lua`, `nav__telescope.lua`, `ui__lualine.lua`, and `vcs__gitsigns.lua`. The old `lua/dotfiles/completion.lua`, `lua/dotfiles/lsp.lua`, and `lua/dotfiles/plugins.lua` companion files were removed after their behavior moved into NixVim modules.
- Some plugin settings still need raw Lua values inside their Nix files because the plugin APIs require callback functions, for example completion mappings, gitsigns `on_attach`, LSP attach behavior, and Telescope/toggleterm function options. Those raw snippets are scoped to the owning plugin module instead of living in a broad plugin Lua file.

## Work Log

- [x] 2026-07-05 01:53 - Created plan 4 after identifying the active Dotter Neovim tree and confirming the deprecated Vim tree is out of scope for the initial migration.
- [x] 2026-07-05 02:18 - Added the first Nix-managed Neovim profile under `hosts/nonlogicals-mbp/users/nonlogical/home/neovim/`, imported it from `home-configuration.nix`, and migrated the first slice of editor behavior into small Lua companion files.
- [x] 2026-07-05 02:18 - Validated the activation package with `nix build '.#homeConfigurations."nonlogical@nonlogicals-mbp".activationPackage'`, isolated `nvim --headless +qa`, explicit plugin `require()` checks, executable checks for Nix-provided tools, and `nix flake check`.
- [x] 2026-07-05 10:15 - Switched the Neovim profile to NixVim, pinned the `nixvim` flake input, and made provider settings explicit.
- [x] 2026-07-05 10:23 - Split plugin enablement and associated configuration into `neovim/plugins/<name>.nix`, removed the broad plugin Lua companion files, and validated activation build, generated config, headless plugin requires, synthetic Linux eval, and `nix flake check`.
- [x] 2026-07-05 10:28 - Renamed the NixVim plugin modules to the source config's namespace convention, `plugins/<namespace>__<plugin>.nix`, and moved leftover unmanaged plugin packages out of `default.nix` into matching plugin files.

## Unfinished Work

- [ ] Before activating on the real machine, remove or move the existing Dotter-owned `~/.config/nvim` symlink so Home Manager can create the target path on a clean system model.
- [ ] Decide later whether deferred plugins need packaging, replacement, or deletion: `vim-jinja`, `vim-polyglot`, `bookmarks.nvim`, and `nvim-aider`.
- [ ] Do an interactive Neovim pass after activation for behaviors headless tests cannot prove: theme appearance, Telescope UX, tree explorer mappings, terminal mappings, OSC52 clipboard behavior, and LSP attach/keymaps inside real projects.
