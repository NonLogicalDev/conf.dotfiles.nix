#!/usr/bin/env bash
#
# Build and activate the reusable developer Home Manager suite inside a clean
# Linux container, then keep the container running for interactive inspection.

set -euo pipefail

repo_dir="${DOTFILES_NIX_REPO:-/workspace/dotfiles-nix}"
test_user="${DOTFILES_NIX_USER:-devsuite}"
test_home="${DOTFILES_NIX_HOME:-/home/$test_user}"
test_name="${DOTFILES_NIX_NAME:-Developer Suite}"
test_email="${DOTFILES_NIX_EMAIL:-devsuite@example.test}"
test_slug="${DOTFILES_NIX_SLUG:-devsuite}"
activation_link="${DOTFILES_NIX_ACTIVATION_LINK:-/tmp/dotfiles-nix-devsuite-home}"

if [ ! -d "$repo_dir" ]; then
  echo >&2 "Missing mounted repo: $repo_dir"
  echo >&2 "Run the container with this checkout mounted at $repo_dir."
  exit 1
fi

if [ ! -f "$repo_dir/flake.nix" ]; then
  echo >&2 "Mounted path is not the dotfiles-nix flake: $repo_dir"
  exit 1
fi

git config --global --add safe.directory "$repo_dir"

bash_path="$(command -v bash)"

if ! id -u "$test_user" >/dev/null 2>&1; then
  useradd --create-home --home-dir "$test_home" --shell "$bash_path" "$test_user"
fi

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
  --expr '
    let
      repo = builtins.getEnv "DOTFILES_NIX_REPO";
      testUser = builtins.getEnv "DOTFILES_NIX_USER";
      testHome = builtins.getEnv "DOTFILES_NIX_HOME";
      testName = builtins.getEnv "DOTFILES_NIX_NAME";
      testEmail = builtins.getEnv "DOTFILES_NIX_EMAIL";
      testSlug = builtins.getEnv "DOTFILES_NIX_SLUG";

      flake = builtins.getFlake repo;
      pkgs = import flake.inputs.nixpkgs {
        system = builtins.currentSystem;
      };

      testModule = { ... }: {
        home.username = testUser;
        home.homeDirectory = testHome;

        # The container does not run systemd as pid 1. Generate the user units
        # so they can be inspected, but do not try to switch/start them.
        systemd.user.startServices = "suggest";

        dotfiles.suites.developerBase.scmIdentity = {
          name = testName;
          email = testEmail;
          slug = testSlug;
        };
      };
    in
    (flake.inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        flake.homeModules.core
        flake.homeModules.suiteDeveloperBase
        testModule
      ];
      extraSpecialArgs = {
        inputs = flake.inputs // {
          self = flake;
        };
      };
    }).activationPackage
  '

echo "Activating Home Manager profile as $test_user..."
su "$test_user" \
  --shell "$bash_path" \
  --command "HOME='$test_home' USER='$test_user' LOGNAME='$test_user' '$activation_link/activate'"

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
echo "  docker exec -it ${HOSTNAME:-dotfiles-nix-devsuite} su - $test_user"
echo

exec "$@"
