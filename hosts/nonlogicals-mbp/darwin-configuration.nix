{ inputs, ... }:

{
  imports = [
    inputs.self.darwinModules.core
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.nonlogical.home = /Users/nonlogical;

  system.stateVersion = 6;
}

