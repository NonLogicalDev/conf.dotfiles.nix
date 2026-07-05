{ inputs, ... }:

{
  imports = [
    inputs.self.homeModules.core
    inputs.self.homeModules.suiteDeveloperBase
  ];

  dotfiles.suites.developerBase = {
    scmIdentity = {
      name = "Oleg Utkin";
      email = "hello@nonlogical.net";
      slug = "oleg.utkin";
    };
  };
}
