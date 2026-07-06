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
#   DOTFILES_NIX_NAME/EMAIL/SLUG Test source-control identity passed into the
#                                reusable developer suite module.
#   DOTFILES_NIX_ACTIVATION_LINK Where `nix build --out-link` writes the Home
#                                Manager activation package symlink.
#   DOTFILES_NIX_ACTIVATION_EXPR Optional path to the Nix expression that
#                                builds the activation package.
#
# Outputs:
#   - A normal user account inside the container.
#   - A Home Manager profile activated into that user's home directory.
#   - A short README in the test home with inspection commands.
#
# This script deliberately does not define a fake host. The point of the
# harness is to exercise the reusable Home Manager module surface directly.

set -euo pipefail

# Keep all knobs environment-overridable so the same image can be reused for
# quick experiments without editing the container definition.
repo_dir="${DOTFILES_NIX_REPO:-/workspace/dotfiles-nix}"
test_user="${DOTFILES_NIX_USER:-devsuite}"
test_home="${DOTFILES_NIX_HOME:-/home/$test_user}"
test_name="${DOTFILES_NIX_NAME:-Developer Suite}"
test_email="${DOTFILES_NIX_EMAIL:-devsuite@example.test}"
test_slug="${DOTFILES_NIX_SLUG:-devsuite}"
activation_link="${DOTFILES_NIX_ACTIVATION_LINK:-/tmp/dotfiles-nix-devsuite-home}"
activation_expr="${DOTFILES_NIX_ACTIVATION_EXPR:-$repo_dir/integration/developer-suite/home-manager-activation.nix}"

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

if [ ! -f "$activation_expr" ]; then
  echo >&2 "Missing activation expression: $activation_expr"
  exit 1
fi

# Nix flakes often ask Git for metadata while evaluating. The checkout is owned
# by the host user but the container starts as root, so mark the mount safe for
# Git before `builtins.getFlake` has a chance to inspect it.
git config --global --add safe.directory "$repo_dir"

bash_path="$(command -v bash)"

# Create the inspection user only at container start. The image stays generic;
# the test account belongs to this run and can be changed through env vars.
if ! id -u "$test_user" >/dev/null 2>&1; then
  useradd --create-home --home-dir "$test_home" --shell "$bash_path" "$test_user"
fi

# Home Manager activation expects the home directory to be owned by the target
# user, even though root prepared the container and will run the Nix build.
mkdir -p "$test_home"
chown "$test_user:$test_user" "$test_home"

# Home Manager's standalone activation updates the per-user profile symlink.
# In this minimal container those per-user Nix directories do not exist until we
# create them explicitly.
mkdir -p \
  "/nix/var/nix/profiles/per-user/$test_user" \
  "/nix/var/nix/gcroots/per-user/$test_user"
chown -R "$test_user:$test_user" \
  "/nix/var/nix/profiles/per-user/$test_user" \
  "/nix/var/nix/gcroots/per-user/$test_user"

# Pass shell values into the Nix expression through the environment. That keeps
# the expression static enough to read while avoiding fragile shell string
# interpolation inside Nix source.
export DOTFILES_NIX_REPO="$repo_dir"
export DOTFILES_NIX_USER="$test_user"
export DOTFILES_NIX_HOME="$test_home"
export DOTFILES_NIX_NAME="$test_name"
export DOTFILES_NIX_EMAIL="$test_email"
export DOTFILES_NIX_SLUG="$test_slug"

echo "Building Home Manager activation package for $test_user at $test_home..."
nix build \
  --impure \
  --out-link "$activation_link" \
  --file "$activation_expr"

# The build happens as root so it can write the out-link and use the container
# Nix installation. Activation happens as the target user so Home Manager writes
# the profile, files, and XDG state with the same ownership a real login would
# have.
echo "Activating Home Manager profile as $test_user..."
su "$test_user" \
  --shell "$bash_path" \
  --command "HOME='$test_home' USER='$test_user' LOGNAME='$test_user' '$activation_link/activate'"

# Leave a breadcrumb inside the container because an interactive shell can be
# opened minutes or hours after activation logs have scrolled away.
cat > "$test_home/README-dotfiles-nix-devsuite.txt" <<EOF
dotfiles-nix developer suite container

Profile activated for:
  user:  $test_user
  home:  $test_home
  name:  $test_name
  email: $test_email
  slug:  $test_slug

Useful inspection commands:
  zsh -l
  git config --global --list --show-origin
  jj config list --include-defaults
  nvim --headless "+checkhealth" "+qa"
  ls -la ~/.config
  find ~/.config/zsh/rc -maxdepth 3 -type f -print
  find ~/.config/bash/rc -maxdepth 3 -type f -print
EOF
chown "$test_user:$test_user" "$test_home/README-dotfiles-nix-devsuite.txt"

echo
echo "Developer suite profile is active."
echo "Exec into it with:"
echo "  just -f integration/developer-suite/Justfile exec"
echo

exec "$@"
