{ inputs, ... }:

{
  imports = [
    inputs.self.homeModules.core
    ./home/atuin
    ./home/git
    ./home/shell
  ];
}
