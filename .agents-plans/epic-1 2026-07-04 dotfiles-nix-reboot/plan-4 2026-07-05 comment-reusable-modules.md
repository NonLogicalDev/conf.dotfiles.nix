---
date: 2026-07-05
status: complete
subject: comment-reusable-modules
---

# Comment Reusable Modules

## Goal

Add durable explanatory comments to reusable Nix modules so a future reader can understand what each module owns, why it exists, and why non-obvious choices were made.

## Context

The repository is growing from a Dotter migration workspace into a reusable Blueprint Nix flake. The module tree now contains low-level Home Manager integrations, a reusable developer suite, Nixvim plugin modules, and platform module placeholders.

Many modules are structurally clear to the person who just wrote them, but a future reader returning years later should not need the chat thread or commit history to answer basic questions:

- What problem does this module solve?
- Why does this module exist instead of using a native Home Manager option directly?
- Which parts are migration scaffolding, platform convention, personal preference, or reusable suite policy?
- Which adjacent files own related behavior?

Target scope for this plan is the Nix module surface under `modules/`: shared system modules, Home Manager core modules, unmanaged bridge modules, developer-suite modules, and Nixvim plugin modules. Companion runtime files such as Lua, zsh, Vimscript, and tmux snippets can keep their own comments, but the Nix modules that wire them should explain why those files are present.

## Decisions

- Add comments where they explain ownership, intent, migration history, or cross-platform behavior.
- Avoid comments that merely restate the option name, such as "enable zsh" beside `programs.zsh.enable = true`.
- Keep comments close to the decision they explain rather than collecting a large prose block at the top of every file.
- Do not change behavior while adding comments unless validation exposes a small naming or convention fix that clearly belongs with the comment pass.
- Keep the existing module layout intact. This plan documents the current model; it is not a refactor plan.
- Include dense config-data modules such as `git/cfg-aliases.nix`, `git/cfg-aliases-stgit.nix`, and `jujutsu/cfg-aliases.nix`. These files are where future readers are most likely to forget what a short alias does, so group comments and oddball command comments are part of the scope.

## Implementation Steps

1. [x] Add module-level and decision-level comments to core and unmanaged bridge modules.
2. [x] Add comments to the developer suite root and app modules for Atuin, Git, Jujutsu, shell, tmux, and Neovim.
3. [x] Add concise intent comments to Nixvim plugin modules so plugin ownership is recognizable without reading Lua docs.
4. [x] Update this plan with any durable naming or OS-convention learning found while commenting.
5. [x] Run formatting, Home Manager activation build, synthetic Linux eval if cross-platform modules changed, and `nix flake check`.
6. [x] Checkpoint the verified comment pass.

## Learning Log

- Comments should answer "what is this and why is this here" for a reader who understands Nix syntax but does not remember the migration history.
- Alias maps need comments by workflow cluster. A future reader does not need a paragraph for `git co`, but aliases like `lguu`, `fix-div`, `send`, `begone`, and StGit queue helpers need enough context to avoid archaeology.

## Work Log

- [x] 2026-07-05 11:20 - Created this separate plan item for the reusable-module comment pass so it is not hidden inside Atuin service or layout work.
- [x] 2026-07-05 11:25 - Added explanatory comments across reusable modules, including core/platform modules, unmanaged bridges, developer-suite app modules, Git/JJ alias maps, and Nixvim plugin modules.
- [x] 2026-07-05 11:31 - Verified formatting, whitespace, module comment coverage, macOS Home Manager activation build, synthetic Linux Home Manager service shape, and full `nix flake check`.
- [x] 2026-07-05 11:32 - Checkpointed the completed comment pass.

## Unfinished Work

- N/A
