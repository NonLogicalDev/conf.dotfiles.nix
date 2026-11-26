{ inputs, ... }:

{
  imports = [
    inputs.self.homeModules.core
    inputs.self.homeModules.suiteDeveloperBase
    inputs.self.homeModules.suiteGraphicalApps
    ./home/local-tools.nix
    ./home/commands.nix
    ./home/terminals
    ./home/vim
    ./home/vifm
    ./home/vscode
  ];

  dotfiles.suites.developerBase = {
    scmIdentity = {
      name = "Oleg Utkin";
      email = "hello@nonlogical.net";
      slug = "oleg.utkin";
    };
  };
}
