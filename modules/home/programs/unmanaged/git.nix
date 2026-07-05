{
  config,
  inputs,
  lib,
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
  managedBlock = inputs.self.lib.home.managedBlock { inherit lib; };
  unmanagedProgram = inputs.self.lib.home.unmanagedProgram { inherit lib; };
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
        target = ".gitconfig";
        block = ''
          [include]
              path = ~/.config/dotfiles-nix/git/config
        '';
      };
    }
  ]);
}
