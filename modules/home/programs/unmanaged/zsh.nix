{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;

  cfg = config.programs.unmanaged.zsh;
  unmanagedProgram = inputs.self.lib.home.unmanagedProgram {
    inherit lib;
    awk = "${pkgs.gawk}/bin/awk";
  };

  mkZshHookSourceBlock =
    {
      hookDir,
      hookExtension,
    }:
    ''
      dotfiles_nix_hook_dir="${hookDir}"
      if [ -d "$dotfiles_nix_hook_dir" ]; then
        for dotfiles_nix_hook in "$dotfiles_nix_hook_dir"/*.${hookExtension}(N); do
          if [ -r "$dotfiles_nix_hook" ]; then
            . "$dotfiles_nix_hook"
          fi
        done
      fi
      unset dotfiles_nix_hook_dir dotfiles_nix_hook
    '';
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
      mkSourceBlock = mkZshHookSourceBlock;
    })
  ]);
}
