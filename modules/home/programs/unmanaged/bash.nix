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

  cfg = config.programs.unmanaged.bash;
  unmanagedProgram = inputs.self.lib.home.unmanagedProgram {
    inherit lib;
    awk = "${pkgs.gawk}/bin/awk";
  };

  mkBashHookSourceBlock =
    {
      hookDir,
      hookExtension,
    }:
    ''
      dotfiles_nix_hook_dir="${hookDir}"
      if [ -d "$dotfiles_nix_hook_dir" ]; then
        if shopt -q nullglob; then
          dotfiles_nix_had_nullglob=1
        else
          dotfiles_nix_had_nullglob=0
        fi
        shopt -s nullglob
        for dotfiles_nix_hook in "$dotfiles_nix_hook_dir"/*.${hookExtension}; do
          if [ -r "$dotfiles_nix_hook" ]; then
            . "$dotfiles_nix_hook"
          fi
        done
        if [ "$dotfiles_nix_had_nullglob" -eq 0 ]; then
          shopt -u nullglob
        fi
      fi
      unset dotfiles_nix_hook_dir dotfiles_nix_hook dotfiles_nix_had_nullglob
    '';
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
      mkSourceBlock = mkBashHookSourceBlock;
    })
  ]);
}
