{ ... }:

# Blueprint imports this directory as the flake's `lib` output.
# In Nix, importing a directory means evaluating its `default.nix`.
#
# Keep this file as a small index. The helpers themselves stay in
# narrower files under `lib/home/`, while users of the flake can reach
# them through `inputs.self.lib.home.*`.
{
  home = {
    # Helpers for Home Manager modules and activation scripts.
    #
    # These are functions that still need to be called with the caller's
    # `lib`, for example:
    #
    #   inputs.self.lib.home.managedBlock { inherit lib; }
    #
    # Passing `lib` at the call site keeps these helpers usable from the
    # exact Nixpkgs/Home Manager library instance that is evaluating the
    # module.
    managedBlock = import ./home/managed-block.nix;
    unmanagedProgram = import ./home/unmanaged-program.nix;
  };
}
