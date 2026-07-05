{ ... }:

{
  home = {
    managedBlock = import ./home/managed-block.nix;
    unmanagedProgram = import ./home/unmanaged-program.nix;
  };
}
