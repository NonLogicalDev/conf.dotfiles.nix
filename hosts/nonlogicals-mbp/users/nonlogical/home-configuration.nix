{ inputs, ... }:

{
  imports = [
    inputs.self.homeModules.core
    inputs.self.homeModules."developer-base"
  ];

  dotfiles.suites.developerBase = {
    scmIdentity = {
      name = "Oleg Utkin";
      email = "hello@nonlogical.net";
      username = "oleg.utkin";
    };
  };
}
