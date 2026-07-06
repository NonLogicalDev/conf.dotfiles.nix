{ lib, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/profiles/docker-container.nix>
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # This file defines only the disposable Linux container substrate used by the
  # integration harness. The Home Manager profile under test still comes from
  # the repo flake as `testuser@integration-test-suite`.
  users.mutableUsers = false;
  users.allowNoPasswordLogin = true;
  users.groups.testuser.gid = 1000;
  users.users.testuser = {
    isNormalUser = true;
    uid = 1000;
    group = "testuser";
    home = "/home/testuser";
    createHome = true;
    shell = pkgs.zsh;
  };

  environment.systemPackages = [
    pkgs.bashInteractive
    pkgs.coreutils
    pkgs.git
    pkgs.shadow
    pkgs.util-linux
    pkgs.zsh
  ];

  programs.zsh.enable = true;

  # The Containerfile runs the generated activation script during image build,
  # not as PID 1 in a booted NixOS container. Docker owns the special filesystems
  # and injects files such as /etc/hosts, so those activation phases are not
  # meaningful here. The phases we care about for this harness are still NixOS
  # phases: create the declared users/groups and expose /run/current-system.
  system.activationScripts.specialfs = lib.mkForce "";
  system.activationScripts.etc = lib.mkForce "";

  documentation.doc.enable = false;
  networking.hostName = "dotfiles-nix-test-suite";

  system.stateVersion = "25.05";
}
