---
date: 2026-09-27
status: in-progress
subject: complete-local-cutover
---

# Complete the local Nix cutover

## Outcome

Activate this repository's standalone `nonlogical@nonlogicals-mbp` Home Manager profile on the local Mac and remove all live Dotter dependencies. The user explicitly requested full cutover and removal on 2026-09-27. Keep existing personal data, credentials, mutable app state, and unrelated configuration. Finish locally; do not push or publish.

## Coordination and current state

The execution plan is `/Users/nonlogical/.agents-shared/oracles/dev-env/theme-001-configuration/active/plan-02 Complete Nix cutover.md`; owner authorization is recorded in that root's OWNERS.md. Existing repository history and plans remain in place. This plan extends the prior source migration to actual deployment and covers remaining terminal/editor/helper surfaces.

- Source baseline: clean main at `1663cbf09593a41200898a7e9d636838db22828d`.
- The active Mac uses Dotter files alongside 31 individually installed Nix packages.
- Use standalone Home Manager; no system-level dotfile behavior requires nix-darwin. Determinate owns the Nix installation and its config. The existing result symlink is dangling and must not be treated as a verified build.
- Audit deployed links and source before adding modules. Prefer native Home Manager options and focused companion files; preserve meaningful behavior.
- Back up the affected configuration and old checkout outside live paths before replacement. No activation dry-run on the live home: the custom mutable-file activation helpers do not honor DRY_RUN.

## Work and checks

- [ ] Inventory and map every deployed Dotter surface to Nix ownership or deliberate retirement.
- [ ] Build missing host-local configuration and preserve mutable integrations.
- [ ] Record and verify rollback copies before modifying live paths.
- [ ] Build the profile, run `nix flake check`, and review the complete change.
- [ ] Activate; validate shell entrypoints, key tools, profile state, and removal of live references.
- [ ] Save a local checkpoint and document the resulting workflow and recovery limits.

## Work log

- 2026-09-27: Read current source and instructions, confirmed clean baseline, began independent read-only inventory and activation audits. Started a fresh Home Manager activation-package build. No live changes yet.
- 2026-09-27: Inventory confirms missing terminal profiles (Ghostty shader/themes, WezTerm, Alacritty), Vim fallback, Vifm, VS Code settings, and user helper commands. Delegate host-local terminal/editor/Vifm modules to /root/legacy_inventory; owner keeps home-configuration.nix and shared modules. Preserve existing Cargo/Bun/LM Studio paths, Jujutsu's local email override, and Atuin's existing server database path. Standalone Home Manager activation is the chosen route; no nix-darwin switch is needed for this scope.
- 2026-09-27: Preserve the 18 deployed user helper commands as a Blueprint package `packages/developer-commands`; use explicit interpreters/dependencies and validate syntax and non-mutating entrypoints. Do not execute Git/StGit rewriting helpers against real repositories. The empty tmux startup hook and old init-zsh-hooks utility can retire after backup because Home Manager replaces their wiring. Restore omitted Git/StGit aliases only where they depend on these preserved commands. Current local Atuin server files and listener are absent; retain the old server database filename to avoid divergence if that state is restored later.
- 2026-09-27: Baseline build succeeded. Its Jujutsu 0.42.0 would downgrade current 0.44.0; assign /root/activation_audit the narrowly pinned `nixpkgs-jujutsu` input and host `home/local-tools.nix` for package selection, existing Jujutsu email, Cargo/Bun/LM Studio PATH, Homebrew shell initialization, and the prior Atuin database filename. Other eight overlapping package versions are equal or newer. Backup: `/Users/nonlogical/.agents-shared/oracles/dev-env/_owner/artifacts/cutover-2026-09-27/`, including old config archive and profile manifest. Source-writing workers: /root/legacy_inventory and /root/helper_commands; owner integrates and activates.
- 2026-09-27: All replacements build. Added the existing local Git ignore for `.claude/settings.local.json` to host configuration before replacing its regular file. Restored working helper aliases; omitted three legacy aliases targeting nonexistent functions. Fixed the verified StGit cancellation bypass and tested rejection, cancellation, and acceptance with isolated stubs. Backup restore check reproduced 374 file hashes and 50 symlinks; prior Nix profile is protected by a GC root. Preserve the dirty old checkout (two modified Zsh files and untracked Vifm rsync.sh) in rollback material; relevant behavior is migrated.
- 2026-09-27: Independent review found no actionable P0-P2 defects. Full `nix flake check --no-write-lock-file` passed for the current aarch64-darwin system; other systems were omitted as incompatible. An earlier formatter attempt through `nix develop` hit a dependency's intermittent Statix snapshot-test failure; direct cached nixfmt is used for the changed files. Imported legacy sources retain their original whitespace. Prepared a checked one-shot home cleanup script in the private rollback directory; no live configuration has been changed yet.
