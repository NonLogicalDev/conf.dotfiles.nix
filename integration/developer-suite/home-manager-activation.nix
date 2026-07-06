# Build the Home Manager activation package for the developer-suite integration
# container.
#
# This file is intentionally not a flake output and not a fake host. It is test
# infrastructure: the container entrypoint points `nix build --file` at this
# expression after mounting the live checkout at `/workspace/dotfiles-nix`.

let
  # The expression is evaluated inside the container, but it points at the
  # mounted checkout. `builtins.getFlake` loads the live repo so the harness
  # follows uncommitted local changes instead of whatever was present when the
  # image was built.
  repo = builtins.getEnv "DOTFILES_NIX_REPO";

  # These values define the synthetic Home Manager user. They intentionally
  # come from the shell environment so the test identity can be overridden
  # without editing Nix files or creating a fake host.
  testUser = builtins.getEnv "DOTFILES_NIX_USER";
  testHome = builtins.getEnv "DOTFILES_NIX_HOME";
  testName = builtins.getEnv "DOTFILES_NIX_NAME";
  testEmail = builtins.getEnv "DOTFILES_NIX_EMAIL";
  testSlug = builtins.getEnv "DOTFILES_NIX_SLUG";

  # Load this repository as a flake and import the same nixpkgs input the rest
  # of the repo uses. `builtins.currentSystem` makes the expression follow the
  # container architecture rather than the host architecture.
  flake = builtins.getFlake repo;
  pkgs = import flake.inputs.nixpkgs {
    system = builtins.currentSystem;
  };

  # This is the only test-specific module. It supplies the minimum facts Home
  # Manager needs for a standalone profile plus the user identity that
  # suiteDeveloperBase requires. Reusable behavior must stay in
  # `flake.homeModules.*`, not in this inline module.
  testModule = { ... }: {
    home.username = testUser;
    home.homeDirectory = testHome;

    # The container does not run systemd as pid 1. Generate the user units so
    # they can be inspected, but do not try to switch/start them.
    systemd.user.startServices = "suggest";

    dotfiles.suites.developerBase.scmIdentity = {
      name = testName;
      email = testEmail;
      slug = testSlug;
    };
  };
in
# Build a Home Manager activation package directly instead of adding a
# synthetic flake output. The harness is integration infrastructure, not a real
# machine profile, so keeping it local to this file avoids polluting the repo's
# public outputs.
(flake.inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;

  # Exercise the same module composition a real user profile would use: the
  # light core module, the reusable developer suite, then the narrow test-only
  # facts above.
  modules = [
    flake.homeModules.core
    flake.homeModules.suiteDeveloperBase
    testModule
  ];

  # Repo modules expect normal Blueprint-style access to flake inputs. Add
  # `self = flake` so code that reaches through `inputs.self.lib` behaves the
  # same way it does during regular flake evaluation.
  extraSpecialArgs = {
    inputs = flake.inputs // {
      self = flake;
    };
  };
}).activationPackage
