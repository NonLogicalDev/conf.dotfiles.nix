{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    filterAttrs
    mapAttrs'
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    nameValuePair
    types
    ;

  cfg = config.programs.unmanaged.bash;
  managedBlock = inputs.self.lib.home.managedBlock {
    inherit lib;
    awk = "${pkgs.gawk}/bin/awk";
  };
  unmanagedProgram = inputs.self.lib.home.unmanagedProgram { inherit lib; };

  hookDir = name: ".config/bash/config/${name}";
  targetPath = name: ".${name}";
  defaultHookName = "50-nix.bash";

  managedFileOption =
    { target }:
    mkOption {
      type = types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to maintain a managed source block in ${target}.";
          };

          text = mkOption {
            type = types.lines;
            default = "";
            description = "Nix-managed bash hook content.";
          };

          hookName = mkOption {
            type = types.str;
            default = defaultHookName;
            description = "Filename for the Nix-managed bash hook inside the ${target} hook directory.";
          };

          placement = mkOption {
            type = types.attrs;
            default = { };
            description = "Advanced managed-block placement settings passed to lib.home.managedBlock.";
          };
        };
      };
      default = { };
      description = "Unmanaged bash integration settings for ${target}.";
    };

  mkBashHookSourceBlock =
    { hookDir }:
    ''
      dotfiles_nix_hook_dir="${hookDir}"
      if [ -d "$dotfiles_nix_hook_dir" ]; then
        if shopt -q nullglob; then
          dotfiles_nix_had_nullglob=1
        else
          dotfiles_nix_had_nullglob=0
        fi
        shopt -s nullglob
        for dotfiles_nix_hook in "$dotfiles_nix_hook_dir"/*.bash; do
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

  mkBashFileConfig =
    { cfg }:
    let
      enabledFiles = filterAttrs (_: file: file.enable) cfg.files;
    in
    {
      home.file = mapAttrs' (
        name: file:
        nameValuePair "${hookDir name}/${file.hookName}" {
          text = file.text;
        }
      ) enabledFiles;

      home.activation = mapAttrs' (
        name: file:
        nameValuePair "unmanaged-bash-${name}" (
          managedBlock.mkActivation {
            name = "bash ${name}";
            target = targetPath name;
            block = mkBashHookSourceBlock {
              hookDir = "$HOME/${hookDir name}";
            };
            placement = {
              mode = "after-preamble";
              relocateExisting = true;
              preambleLineRegexes = [
                "^#!"
                "^#($|[[:space:]])"
                "^[[:space:]]*$"
              ];
            }
            // file.placement;
          }
        )
      ) enabledFiles;
    };
in
{
  options.programs.unmanaged.bash = {
    enable = mkEnableOption "unmanaged bash coexistence helpers";

    nativeProgramPolicy = unmanagedProgram.nativeProgramPolicyOption "bash";

    files = {
      bashrc = managedFileOption {
        target = "~/.bashrc";
      };
      bash_profile = managedFileOption {
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
    (mkBashFileConfig {
      inherit cfg;
    })
  ]);
}
