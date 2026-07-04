# dotfiles-nix

This repo is the slow reboot of my user profile management: move from a Dotter-controlled garden of chaos to a Nix-managed profile that is understandable, reversible, and boring to operate.

The goal is not to port everything at once. The first phase is inventory and boundaries:

- Identify what Dotter currently owns.
- Separate machine-specific state from portable user profile configuration.
- Decide which parts belong in Nix, which parts should stay as app state, and which parts should be deleted.
- Introduce Nix modules only after the current behavior is understood.

## Starting Principles

- Take small, reviewable steps.
- Prefer explicit ownership over clever abstraction.
- Keep migration reversible until each slice is proven.
- Do not move secrets into the repo.
- Do not rewrite working config just because it looks messy.

## Current Status

Bootstrapped with an empty `INIT` commit, then this README and the first `$Tasker_Plan` file. Next step is a read-only inventory of the current Dotter layout and existing dotfiles.

