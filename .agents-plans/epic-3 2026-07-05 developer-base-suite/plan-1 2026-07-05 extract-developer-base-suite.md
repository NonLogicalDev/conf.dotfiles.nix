---
date: 2026-07-05
status: in-progress
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
- Keep per-user and per-machine values outside reusable modules. The first identity values to parameterize are username, home directory assumptions, Git identity, and Jujutsu identity.
- Prefer `config.home.username` and `config.home.homeDirectory` when Home Manager already knows the current user. Add suite options only when the suite needs a value that Home Manager does not already model clearly, such as Git/JJ identity defaults or profile-specific feature toggles.
- Git and Jujutsu identity must be configurable independently. Do not assume both tools use the same email address, because the current profile already uses different Git and Jujutsu emails.
- Make the suite cross-platform by default. Use `pkgs.stdenv.isDarwin` or platform-specific module conditionals only where behavior truly differs between macOS and Linux.
- Begin implementation with an inventory of all host-user files that contain personal literals, OS assumptions, or reusable behavior trapped in the host tree.

## Implementation Steps

1. [ ] Inventory host-user Home Manager files for personal literals, OS-specific assumptions, path assumptions, and reusable developer behavior.
2. [ ] Design the developer base suite option surface, including identity options, enabled tool families, and defaults that are safe for both macOS and Linux.
3. [ ] Decide which existing host-user app profiles move directly into `modules/home/suites/developer-base/` and which need lower-level modules under `modules/home/programs/` first.
4. [ ] Extract the first low-risk tool family into shared modules while keeping `hosts/nonlogicals-mbp/users/nonlogical/home-configuration.nix` behavior equivalent.
5. [ ] Parameterize Git identity and Jujutsu identity, preserving the current Mac profile's concrete values at the host-user boundary.
6. [ ] Replace hardcoded username and home path assumptions in reusable Home Manager code with `config.home.username`, `config.home.homeDirectory`, or explicit suite options.
7. [ ] Validate after each extraction with the Home Manager activation package and `nix flake check`.
8. [ ] Add a second host/user or Linux-oriented profile only after the suite boundary is proven with the current Mac profile.

## Learning Log

- The host-user tree was the correct first migration landing zone, but it is not the desired long-term reuse boundary.
- Current Git and Jujutsu identities are not identical, so a single `email` option would lose information. The suite needs either separate Git/JJ identity options or a shared default with per-tool overrides.
- `users.users.<name>.home` is a nix-darwin system option and should stay in the Darwin host configuration. Reusable Home Manager modules should use Home Manager's own user/home values or explicit options instead.
- The suite should convey the essence of the current developer environment, not preserve the host-user file structure. Existing files under `hosts/nonlogicals-mbp/users/nonlogical/home/` are source material for extraction, not the target layout.

## Work Log

- [x] 2026-07-05 02:17 - Created the developer base suite epic and initial self-contained plan.
- [x] 2026-07-05 02:20 - Removed turn-specific planning language so the plan describes project sequencing rather than freezing implementation.

## Unfinished Work

- [ ] Start the inventory pass for personal literals and reusable host-user developer behavior.
- [ ] Draft the suite option schema before moving any app configuration.
- [ ] Decide the first extraction slice after inventory; likely candidates are Git/Jujutsu identity plumbing or a small shell/tooling subset.
