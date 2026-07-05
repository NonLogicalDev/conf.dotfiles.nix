{ config, lib, ... }:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;

  cfg = config.programs.unmanaged.zsh;
  unmanagedProgram = import ../../../../lib/home/unmanaged-program.nix { inherit lib; };
in
{
  options.programs.unmanaged.zsh = {
    enable = mkEnableOption "unmanaged zsh coexistence helpers";

    nativeProgramPolicy = unmanagedProgram.nativeProgramPolicyOption "zsh";

    files = {
      zshenv = unmanagedProgram.managedFileOption {
        tool = "zsh";
        target = "~/.zshenv";
      };
      zprofile = unmanagedProgram.managedFileOption {
        tool = "zsh";
        target = "~/.zprofile";
      };
      zshrc = unmanagedProgram.managedFileOption {
        tool = "zsh";
        target = "~/.zshrc";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (unmanagedProgram.nativeProgramPolicyConfig {
      inherit config cfg;
      program = "zsh";
      optionName = "programs.unmanaged.zsh";
    })
    (unmanagedProgram.mkShellFileConfig {
      inherit cfg;
      tool = "zsh";
    })
  ]);
}
