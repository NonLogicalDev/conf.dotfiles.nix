{ inputs, ... }:

{
  imports = [
    inputs.self.homeModules.core
    inputs.self.homeModules."developer-base"
  ];

  dotfiles.suites.developerBase = {
    git = {
      userName = "Oleg Utkin";
      userEmail = "hello@nonlogical.net";
    };

    jujutsu = {
      userName = "Oleg Utkin";
      userEmail = "oleg@nonlogical.net";
      immutableBookmarkGlobs = [ "oleg.utkin/*" ];
    };
  };
}
