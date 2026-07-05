{ config, lib, ... }:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;

  cfg = config.programs.unmanaged.bash;
  unmanagedProgram = import ../../../../lib/home/unmanaged-program.nix { inherit lib; };
in
{
  options.programs.unmanaged.bash = {
    enable = mkEnableOption "unmanaged bash coexistence helpers";

    nativeProgramPolicy = unmanagedProgram.nativeProgramPolicyOption "bash";

    files = {
      bashrc = unmanagedProgram.managedFileOption {
        tool = "bash";
        target = "~/.bashrc";
      };
      bash_profile = unmanagedProgram.managedFileOption {
        tool = "bash";
        target = "~/.bash_profile";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (unmanagedProgram.nativeProgramPolicyConfig {
      inherit config cfg;
      program = "bash";
      optionName = "programs.unmanaged.bash";
    })
    (unmanagedProgram.mkShellFileConfig {
      inherit cfg;
      tool = "bash";
    })
  ]);
}
