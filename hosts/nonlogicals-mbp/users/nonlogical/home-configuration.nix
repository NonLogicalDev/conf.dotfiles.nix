{ inputs, ... }:

{
  imports = [
    inputs.self.homeModules.core
    inputs.self.homeModules.suiteDeveloperBase
    inputs.self.homeModules.suiteGraphicalApps
  ];

  dotfiles.suites.developerBase = {
    scmIdentity = {
      name = "Oleg Utkin";
      email = "hello@nonlogical.net";
      slug = "oleg.utkin";
    };
  };
}
