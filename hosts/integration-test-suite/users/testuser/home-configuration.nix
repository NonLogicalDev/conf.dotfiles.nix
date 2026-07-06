{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  # Integration-only standalone Home Manager profile for the test-suite
  # container. Blueprint sees this path and exposes it as the profile
  # `testuser@integration-test-suite`.
  imports = [
    inputs.self.homeModules.core
    inputs.self.homeModules.suiteDeveloperBase
  ];

  # Containers used for profile inspection normally do not run systemd as pid 1.
  # On Linux, generate user units for inspection but do not try to switch or
  # start them during activation. On Darwin this option should disappear.
  systemd.user.startServices = lib.mkIf pkgs.stdenv.isLinux "suggest";

  dotfiles.suites.developerBase = {
    scmIdentity = {
      name = "Test User";
      email = "testuser@example.test";
      slug = "testuser";
    };
  };
}
