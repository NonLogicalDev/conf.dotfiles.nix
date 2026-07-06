#!/usr/bin/env bash
#
# Build and activate the reusable developer Home Manager suite inside a clean
# Linux container, then keep the container running for interactive inspection.
#
# Inputs:
#   DOTFILES_NIX_REPO            Mounted checkout path. Defaults to the path
#                                used by compose.yml.
#   DOTFILES_NIX_USER/HOME       Synthetic Linux account that receives the Home
#                                Manager profile.
#   DOTFILES_NIX_HOME_FLAKE      Flake URI containing the Home Manager profile.
#                                Defaults to `path:$DOTFILES_NIX_REPO`.
#   DOTFILES_NIX_HOME_PROFILE    Home Manager flake profile to activate.
#                                Defaults to the integration host profile.
#
# Outputs:
#   - A normal user account inside the container.
#   - A Home Manager profile activated through the repo flake.
#   - A short README in the test home with inspection commands.
#
# This script deliberately does not define a fake host. The point of the
# harness is to exercise the reusable Home Manager module surface directly.

set -euo pipefail

# Keep all knobs environment-overridable so the same image can be reused for
# quick experiments without editing the container definition.
repo_dir="${DOTFILES_NIX_REPO:-/workspace/dotfiles-nix}"
test_user="${DOTFILES_NIX_USER:-testuser}"
test_home="${DOTFILES_NIX_HOME:-/home/$test_user}"
home_flake="${DOTFILES_NIX_HOME_FLAKE:-path:$repo_dir}"
home_profile="${DOTFILES_NIX_HOME_PROFILE:-testuser@integration-test-suite}"

# The repo must be a mounted checkout, not copied into the image. That keeps
# rebuilds cheap and makes the container test the exact working tree the user is
# editing.
if [ ! -d "$repo_dir" ]; then
  echo >&2 "Missing mounted repo: $repo_dir"
  echo >&2 "Run the container with this checkout mounted at $repo_dir."
  exit 1
fi

if [ ! -f "$repo_dir/flake.nix" ]; then
  echo >&2 "Mounted path is not the dotfiles-nix flake: $repo_dir"
  exit 1
fi

# Nix flakes often ask Git for metadata while evaluating. The checkout is owned
# by the host user but the container starts as root, so mark the mount safe for
# Git before `builtins.getFlake` has a chance to inspect it.
git config --global --add safe.directory "$repo_dir"

bash_path="$(command -v bash)"

# Use the Home Manager CLI from this repo's locked flake input. That keeps the
# harness on the same Home Manager revision as the modules it is testing while
# still using the normal Home Manager command surface.
home_manager_flake="$(
  DOTFILES_NIX_REPO="$repo_dir" nix eval --impure --raw --expr '
    let
      flake = builtins.getFlake (builtins.getEnv "DOTFILES_NIX_REPO");
    in
    flake.inputs.home-manager.outPath
  '
)"

# Create the inspection user only at container start. The image stays generic;
# the test account belongs to this run and can be changed through env vars.
if ! id -u "$test_user" >/dev/null 2>&1; then
  useradd --create-home --home-dir "$test_home" --shell "$bash_path" "$test_user"
fi

# Home Manager activation expects the home directory to be owned by the target
# user before the user-owned switch runs.
mkdir -p "$test_home"
chown "$test_user:$test_user" "$test_home"

# The Home Manager config may call `builtins.getFlake` on the mounted checkout
# while running as the test user. Git refuses to inspect a checkout owned by a
# different uid unless it is explicitly marked safe for that user too.
printf -v git_safe_command \
  "HOME=%q USER=%q LOGNAME=%q git config --global --add safe.directory %q" \
  "$test_home" \
  "$test_user" \
  "$test_user" \
  "$repo_dir"
su "$test_user" \
  --shell "$bash_path" \
  --command "$git_safe_command"

# Home Manager's standalone activation updates the per-user profile symlink.
# In this minimal container those per-user Nix directories do not exist until we
# create them explicitly.
mkdir -p \
  "/nix/var/nix/profiles/per-user/$test_user" \
  "/nix/var/nix/gcroots/per-user/$test_user"
chown -R "$test_user:$test_user" \
  "/nix/var/nix/profiles/per-user/$test_user" \
  "/nix/var/nix/gcroots/per-user/$test_user"

# The official Nix image is effectively a single-user root Nix installation.
# To run the real Home Manager CLI as the test user, hand this disposable
# container's Nix store and metadata to that user. This would be inappropriate
# on a real machine, but it makes the integration harness exercise the same
# user-owned switch path a normal standalone Home Manager install uses.
chown -R "$test_user:$test_user" /nix

# Keep the command construction in Bash instead of nested quote soup. `printf
# %q` preserves spaces and other shell-sensitive characters in paths.
printf -v switch_command \
  "cd %q && HOME=%q USER=%q LOGNAME=%q nix run %q#home-manager -- --impure --no-write-lock-file --flake %q#%q switch -b hm-backup" \
  "$repo_dir" \
  "$test_home" \
  "$test_user" \
  "$test_user" \
  "$home_manager_flake" \
  "$home_flake" \
  "$home_profile"

echo "Switching Home Manager profile for $test_user at $test_home..."
echo "Selected profile: $home_profile"
su "$test_user" \
  --shell "$bash_path" \
  --command "$switch_command"

# Leave a breadcrumb inside the container because an interactive shell can be
# opened minutes or hours after activation logs have scrolled away.
cat > "$test_home/README-dotfiles-nix-test-suite.txt" <<EOF
dotfiles-nix test suite container

Profile activated for:
  user:  $test_user
  home:  $test_home
  flake: $home_flake
  profile: $home_profile

Useful inspection commands:
  zsh -l
  git config --global --list --show-origin
  jj config list --include-defaults
  nvim --headless "+checkhealth" "+qa"
  ls -la ~/.config
  find ~/.config/zsh/rc -maxdepth 3 -type f -print
  find ~/.config/bash/rc -maxdepth 3 -type f -print
EOF
chown "$test_user:$test_user" "$test_home/README-dotfiles-nix-test-suite.txt"

echo
echo "Test suite profile is active."
echo "Exec into it with:"
echo "  just -f integration/test-suite/Justfile exec"
echo

exec "$@"
