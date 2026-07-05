---
date: 2026-07-05
status: complete
subject: extract-developer-base-suite
---

# Extract Developer Base Suite

## Goal

Create a reusable Home Manager developer base suite from the current host-user configuration.

The suite should carry the reusable essence of the migrated development environment across macOS and Linux, while keeping personal and machine-specific identity values configurable at the host/user boundary. The target outcome is that a future macOS or Linux user profile can opt into the same developer baseline without copying `hosts/nonlogicals-mbp/users/nonlogical/home/*` or hardcoding `nonlogical`, `/Users/nonlogical`, Git identity, or Jujutsu identity inside reusable modules.

## Context

The repository currently has a real host-user Home Manager profile at `hosts/nonlogicals-mbp/users/nonlogical/home-configuration.nix`. That profile imports app-specific configuration under `hosts/nonlogicals-mbp/users/nonlogical/home/`, including shell, Git, Jujutsu, tmux, Atuin, and Neovim slices migrated from the previous Dotter setup.

Those host-user files were a good migration landing zone because they preserved behavior while each tool was understood. They are now starting to mix two different kinds of ownership:

- reusable developer behavior, such as Git aliases, Jujutsu templates, shell defaults, tmux ergonomics, Neovim package/tool choices, and terminal history/search behavior;
- personal or host-specific facts, such as the username `nonlogical`, Darwin home path `/Users/nonlogical`, Git email `hello@nonlogical.net`, and Jujutsu user email `oleg@nonlogical.net`.

Known hardcoded identity surfaces at the start of this epic include:

- `hosts/nonlogicals-mbp/darwin-configuration.nix`: `users.users.nonlogical.home = /Users/nonlogical;` belongs to the Darwin host layer, but should not leak into reusable Home Manager suites.
- `hosts/nonlogicals-mbp/users/nonlogical/home/git/cfg-settings.nix`: Git user email is currently literal profile data.
- `hosts/nonlogicals-mbp/users/nonlogical/home/jujutsu/default.nix`: Jujutsu user email is currently literal profile data.

The target suite must work for both Darwin and Linux Home Manager users. Darwin-only system facts stay in `hosts/<host>/darwin-configuration.nix`; Linux-specific system facts should stay in a future NixOS or standalone Home Manager host layer. Reusable Home Manager behavior should live under Blueprint's shared module area, not under one machine's `hosts/nonlogicals-mbp/users/nonlogical/home/` tree.

This plan starts with design and inventory because the existing host-user tree mixes reusable behavior with personal facts. Implementation should proceed in small extraction slices after the reusable option surface is clear.

## Product Integration

- Existing product model: host-user app configs under `hosts/<host>/users/<username>/home/` are the migration workspace; reusable behavior belongs in `modules/home/programs/` or `modules/home/suites/`; host system facts belong under `hosts/<host>/`.
- New requirement's real intent: turn the proven personal development setup into a reusable, configurable developer baseline that can be enabled for multiple users and operating systems.
- Cleanest integrated model: add a shared Home Manager suite under `modules/home/suites/developer-base/` with explicit options for identity and included tool families, then let each host-user profile enable the suite and provide concrete values.
- Existing pieces that should move, change, or disappear: reusable Git, Jujutsu, shell, tmux, Atuin, and Neovim behavior should move out of `hosts/nonlogicals-mbp/users/nonlogical/home/` over time; personal identity literals should become option values supplied by the host-user profile; Darwin-only user-home facts should remain in the Darwin host layer.
- Architecture impact: this epic will likely introduce shared suite modules, option definitions, and host-user enablement blocks. It should not create fake hosts or move Linux/Darwin system facts into Home Manager modules.
- Why this is better than a local patch: changing a few literals would make the current Mac profile less hardcoded, but would still leave the reusable developer environment trapped inside one host-user path. A suite gives the project a real reuse boundary before adding Linux profiles.

## Decisions

- Create the reusable developer baseline as a Home Manager suite under `modules/home/suites/developer-base/`, not as another host-user `home/` directory.
- Keep low-level single-program integrations under `modules/home/programs/` when a reusable program module is needed. The developer base suite should compose program modules and Home Manager options; it should not become a dumping ground for every app's internal implementation.
- Keep per-user and per-machine values outside reusable modules. Source-control identity is supplied by the host-user profile as `dotfiles.suites.developerBase.scmIdentity.{name,email,username}`.
- Prefer `config.home.username` and `config.home.homeDirectory` when Home Manager already knows the current user. Add suite options only when the suite needs a value that Home Manager does not already model clearly, such as Git/JJ identity defaults or profile-specific feature toggles.
- Git and Jujutsu intentionally share one SCM identity surface in the developer base suite. `scmIdentity.name` and `scmIdentity.email` feed both tools, while `scmIdentity.username` derives personal namespace globs such as the Jujutsu immutable bookmark glob `<username>/*`.
- Make the suite cross-platform by default. Use `pkgs.stdenv.isDarwin` or platform-specific module conditionals only where behavior truly differs between macOS and Linux.
- Begin implementation with an inventory of all host-user files that contain personal literals, OS assumptions, or reusable behavior trapped in the host tree.

## Implementation Steps

1. [x] Inventory host-user Home Manager files for personal literals, OS-specific assumptions, path assumptions, and reusable developer behavior.
2. [x] Design the developer base suite option surface, including identity options, enabled tool families, and defaults that are safe for both macOS and Linux.
3. [x] Decide which existing host-user app profiles move directly into `modules/home/suites/developer-base/` and which need lower-level modules under `modules/home/programs/` first.
4. [x] Extract the tool profiles into shared modules while keeping `hosts/nonlogicals-mbp/users/nonlogical/home-configuration.nix` behavior equivalent.
5. [x] Parameterize shared SCM identity for Git and Jujutsu, preserving the current Mac profile's concrete values at the host-user boundary.
6. [x] Replace hardcoded username and home path assumptions in reusable Home Manager code with `config.home.username`, `config.home.homeDirectory`, or explicit suite options.
7. [x] Validate the extracted suite with the Home Manager activation package and `nix flake check`.
8. [x] Prove the suite boundary with a synthetic Linux Home Manager evaluation before adding a real second host/user profile.

## Learning Log

- The host-user tree was the correct first migration landing zone, but it is not the desired long-term reuse boundary.
- The starting Mac profile used different Git and Jujutsu email literals, but the reusable suite now chooses a single SCM identity surface for consistency. If a future profile needs per-tool identity divergence, that should be added as an explicit extension rather than preserved as accidental migration shape.
- `users.users.<name>.home` is a nix-darwin system option and should stay in the Darwin host configuration. Reusable Home Manager modules should use Home Manager's own user/home values or explicit options instead.
- The suite should convey the essence of the current developer environment, not preserve the host-user file structure. Existing files under `hosts/nonlogicals-mbp/users/nonlogical/home/` are source material for extraction, not the target layout.
- The implemented suite lives at `modules/home/suites/developer-base/`, with a small Blueprint export wrapper at `modules/home/developer-base.nix`. Host-user profiles import it as `inputs.self.homeModules."developer-base"`.
- Concrete personal identity values now live in `hosts/nonlogicals-mbp/users/nonlogical/home-configuration.nix` under `dotfiles.suites.developerBase.scmIdentity`. The shared suite no longer contains `nonlogical`, `/Users/nonlogical`, `hello@nonlogical.net`, `oleg@nonlogical.net`, `Oleg Utkin`, or `oleg.utkin/*` literals.
- Jujutsu's personal immutable bookmark glob is derived from `scmIdentity.username`, so the Mac profile's `username = "oleg.utkin";` produces `bookmarks(glob:'oleg.utkin/*')` without storing the glob separately.
- Atuin's launchd-backed local server helpers are guarded with `pkgs.stdenv.isDarwin`. A synthetic `x86_64-linux` Home Manager evaluation imports the same suite with different Git/JJ identities and emits no launchd agents.

## Work Log

- [x] 2026-07-05 02:17 - Created the developer base suite epic and initial self-contained plan.
- [x] 2026-07-05 02:20 - Removed turn-specific planning language so the plan describes project sequencing rather than freezing implementation.
- [x] 2026-07-05 02:31 - Moved the migrated shell, Git, Jujutsu, tmux, Atuin, and Neovim profiles into `modules/home/suites/developer-base/`, added the exported `homeModules."developer-base"` wrapper, and wired the Mac host-user profile through the suite.
- [x] 2026-07-05 02:31 - Parameterized Git and Jujutsu identities, moved current concrete values to the host-user profile, guarded Darwin-only Atuin launchd behavior, and validated with activation build, synthetic Linux Home Manager eval, formatting, and `nix flake check`.
- [x] 2026-07-05 09:43 - Collapsed Git and Jujutsu identity options into `scmIdentity.{name,email,username}` and derived the Jujutsu immutable bookmark glob from `scmIdentity.username`.

## Unfinished Work

N/A
