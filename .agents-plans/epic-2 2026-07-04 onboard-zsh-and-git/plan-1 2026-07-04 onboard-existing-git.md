---
date: 2026-07-04
status: complete
subject: onboard-existing-git
---

# Onboard Existing Git

## Goal

Onboard the current personal Git behavior into this Nix dotfiles repo without preserving the old Dotter fragment tree as the target shape.

## Context

The current real home had `~/.config/git/config` as the only active global Git config; `~/.gitconfig` was absent. The old config included `gitconfig.d` fragments and a global ignore file that were Dotter-era symlinks. The migration needed to keep the conventional mutable `~/.config/git/config` available for Nix-oblivious tools while moving the durable Git behavior into Home Manager.

## Product Integration

- Existing product model: reusable unmanaged top-level file behavior lives in `modules/home/programs/unmanaged/git.nix`; host-user Git choices live under `hosts/nonlogicals-mbp/users/nonlogical/home/git/`.
- New requirement's real intent: move Git behavior to idiomatic Home Manager while leaving a small mutable include point for third-party tools.
- Cleanest integrated model: `programs.unmanaged.git` owns the include bridge, while `programs.git.settings` and `programs.git.ignores` own the managed behavior.
- Existing pieces that should move, change, or disappear: copied Dotter Git fragments should not remain as long-lived files once their behavior is expressed in Nix.
- Architecture impact: the host-user Git profile now uses `cfg-*.nix` sibling files for readable semantic sections.
- Why this is better than a local patch: it avoids preserving accidental Dotter file boundaries and keeps future Git edits reviewable.

## Decisions

- Use only `.config/git/config` as the unmanaged Git include target. Including both `.gitconfig` and `.config/git/config` would duplicate multi-valued settings such as credential helpers if Git reads both files.
- Replace the old concrete Nix store `gh` credential helper path with `!${lib.getExe pkgs.gh} auth git-credential`.
- Keep Git sections as sibling files named with the `cfg-` prefix: `cfg-settings.nix`, `cfg-aliases.nix`, `cfg-aliases-stgit.nix`, and `cfg-ignore-patterns.nix`.
- Keep plan 2 as the active zsh migration plan; this plan is now the completed Git record only.

## Implementation Steps

1. [x] Inventory current Git files, symlinks, top-level config, and line counts.
2. [x] Add `home/git/default.nix` and import it from the host-user Home Manager profile.
3. [x] Replace copied Git fragments with `programs.git.settings`, `programs.git.ignores`, `pkgs.gh`, and `programs.unmanaged.git`.
4. [x] Split the host-user Git profile into `cfg-*.nix` sibling section files.
5. [x] Verify generated Git config and run `nix flake check`.

## Learning Log

- `~/.gitconfig` was absent at the start of this epic.
- Existing `~/.config/git/config` is a real mutable file, not a symlink.
- Existing `~/.config/git/gitconfig.d` and `~/.config/git/gitignore.default` were Dotter symlinks.
- Home Manager renders `"stgit.alias"` as Git's `[stgit "alias"]` subsection, and `git config --file` reads the generated values as `stgit.alias.*`.
- The migrated Git module writes the managed fragment at `~/.config/git/config.d/50-nix-managed.conf`. `programs.unmanaged.git` inserts a small include block into mutable `~/.config/git/config`.
- The direct Home Manager inspection build needs `home.username` and `home.homeDirectory` supplied by the caller or system integration. This repo intentionally does not hardcode those values in reusable modules.

## Work Log

- [x] 2026-07-04 20:54 - Created epic-2 plan after inventorying current zsh and Git surfaces.
- [x] 2026-07-04 21:59 - Replaced staged Git file copies with `programs.git.settings`, `programs.git.ignores`, `pkgs.gh`, and `programs.unmanaged.git`.
- [x] 2026-07-04 21:59 - Built an inspection-only Home Manager activation package with inline `home.username` and `home.homeDirectory`, then verified the generated Git config and unmanaged include activation block.
- [x] 2026-07-04 22:12 - Split the host-user Git module into `cfg-*.nix` sibling files so aliases, StGit aliases, ignore patterns, and general settings can evolve independently.
- [x] 2026-07-04 22:12 - Verified the split by comparing the generated managed Git config against the pre-split output and running `nix flake check`.

## Unfinished Work

N/A
