{ inputs, ... }:

{
  imports = [
    inputs.self.homeModules.core
    ./home/atuin
    ./home/git
    ./home/jujutsu
    ./home/neovim
    ./home/shell
    ./home/tmux
  ];
}
