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
    mkOption
    types
    ;

  cfg = config.programs.unmanaged.git;
  managedBlock = inputs.self.lib.home.managedBlock {
    inherit lib;
    awk = "${pkgs.gawk}/bin/awk";
  };
  unmanagedProgram = inputs.self.lib.home.unmanagedProgram {
    inherit lib;
  };
in
{
  options.programs.unmanaged.git = {
    enable = mkEnableOption "unmanaged git coexistence helpers";

    nativeProgramPolicy = unmanagedProgram.nativeProgramPolicyOption "git";

    managedConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Nix-managed git config written to ~/.config/dotfiles-nix/git/config.";
    };

    includeTarget = mkOption {
      type = types.enum [
        ".gitconfig"
        ".config/git/config"
      ];
      default = ".gitconfig";
      description = ''
        Mutable Git config file that should receive the managed include block.

        Git reads both ~/.config/git/config and ~/.gitconfig for normal
        config loading, with later values winning. Git's own `git config
        --global` write target depends on which of those files already
        exists, so this option keeps the coexistence boundary explicit.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (unmanagedProgram.nativeProgramPolicyConfig {
      inherit config cfg;
      program = "git";
      optionName = "programs.unmanaged.git";
    })
    {
      home.file.".config/dotfiles-nix/git/config".text = cfg.managedConfig;

      home.activation.unmanaged-git-gitconfig = managedBlock.mkActivation {
        name = "git gitconfig";
        target = cfg.includeTarget;
        block = ''
          [include]
              path = ~/.config/dotfiles-nix/git/config
        '';
        placement = {
          # Git applies config in file order, and later entries override
          # earlier ones. Put the managed include near the top so ordinary
          # hand-written or tool-written config in ~/.gitconfig can still
          # override the Nix-managed defaults below it.
          mode = "after-preamble";
          relocateExisting = true;
          preambleLineRegexes = [
            "^#"
            "^[[:space:]]*$"
          ];
        };
      };
    }
  ]);
}
