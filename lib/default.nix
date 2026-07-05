{ ... }:

{
  home = {
    hmManagedBlock = import ./home/hm-managed-block.nix;
    unmanagedProgram = import ./home/unmanaged-program.nix;
  };
}
