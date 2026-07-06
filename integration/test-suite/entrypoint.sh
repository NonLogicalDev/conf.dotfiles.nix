#!/usr/bin/env bash
#
# Activate the repo's standalone Home Manager profile inside the static NixOS
# container substrate defined by ./configuration.nix, then keep the container
# alive for interactive inspection.
#
# Inputs:
#   DOTFILES_NIX_REPO            Mounted checkout path. Defaults to compose.yml.
#   DOTFILES_NIX_HOME_FLAKE      Flake URI containing the Home Manager profile.
#                                Defaults to `path:$DOTFILES_NIX_REPO`.
#   DOTFILES_NIX_HOME_PROFILE    Home Manager profile to activate.
#                                Defaults to `testuser@integration-test-suite`.
#
# Outputs:
#   - Home Manager activation for testuser.
#   - A short README in /home/testuser with inspection commands.

set -euo pipefail

repo_dir="${DOTFILES_NIX_REPO:-/workspace/dotfiles-nix}"
test_user="testuser"
test_home="/home/testuser"
home_flake="${DOTFILES_NIX_HOME_FLAKE:-path:$repo_dir}"
home_profile="${DOTFILES_NIX_HOME_PROFILE:-testuser@integration-test-suite}"

run_as_test_user() {
  /run/current-system/sw/bin/setpriv \
    --reuid "$test_user" \
    --regid "$test_user" \
    --init-groups \
    --reset-env \
    /run/current-system/sw/bin/env \
    HOME="$test_home" \
    USER="$test_user" \
    LOGNAME="$test_user" \
    NIX_CONFIG="experimental-features = nix-command flakes" \
    PATH="/run/current-system/sw/bin:/bin" \
    "$@"
}

if [ ! -f "$repo_dir/flake.nix" ]; then
  echo >&2 "Mounted path is not the dotfiles-nix flake: $repo_dir"
  exit 1
fi

# The image is built from a NixOS configuration, but the container does not run
# systemd as pid 1. Start only the Nix daemon needed for an unprivileged user to
# build and activate a Home Manager profile without owning /nix.
/run/current-system/sw/bin/nix-daemon --daemon &

# Git refuses to inspect a checkout owned by another uid unless it is marked
# safe. Configure this in testuser's home because Home Manager evaluates the
# mounted flake as that user.
run_as_test_user git config --global --add safe.directory "$repo_dir"

home_manager_flake="$(
  DOTFILES_NIX_REPO="$repo_dir" /run/current-system/sw/bin/nix \
    --extra-experimental-features "nix-command flakes" \
    eval --impure --raw --expr '
    let
      flake = builtins.getFlake (builtins.getEnv "DOTFILES_NIX_REPO");
    in
    flake.inputs.home-manager.outPath
  '
)"

echo "Switching Home Manager profile for $test_user at $test_home..."
echo "Selected profile: $home_profile"

run_as_test_user /run/current-system/sw/bin/bash -c "
  set -euo pipefail
  cd '$repo_dir'
  NIX_REMOTE=daemon \
    nix --extra-experimental-features 'nix-command flakes' \
      run '$home_manager_flake#home-manager' -- \
      --impure \
      --no-write-lock-file \
      --flake '$home_flake#$home_profile' \
      switch \
      -b hm-backup
"

cat > "$test_home/README-dotfiles-nix-test-suite.txt" <<EOF
dotfiles-nix test suite container

Profile activated for:
  user:    $test_user
  home:    $test_home
  flake:   $home_flake
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
chown "$test_user:testuser" "$test_home/README-dotfiles-nix-test-suite.txt"

echo
echo "Test suite profile is active."
echo "Exec into it with:"
echo "  just -f integration/test-suite/Justfile exec"
echo

exec "$@"
