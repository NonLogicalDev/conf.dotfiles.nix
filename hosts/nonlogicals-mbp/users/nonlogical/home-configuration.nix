{ inputs, ... }:

{
  imports = [
    inputs.self.homeModules.core
    ./home/git
    ./home/shell
  ];
}
