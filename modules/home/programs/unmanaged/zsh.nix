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

  cfg = config.programs.unmanaged.zsh;
  managedBlock = inputs.self.lib.home.managedBlock {
    inherit lib;
    awk = "${pkgs.gawk}/bin/awk";
  };
  unmanagedProgram = inputs.self.lib.home.unmanagedProgram { inherit lib; };

  hookDir = name: ".config/zsh/rc/${name}.d";
  dispatcherPath = name: ".config/zsh/rc/${name}.zsh";
  targetPath = name: ".${name}";
  defaultHookName = "50-nix-managed.zsh";

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
            description = "Nix-managed zsh hook content.";
          };

          hookName = mkOption {
            type = types.str;
            default = defaultHookName;
            description = "Filename for the Nix-managed zsh hook inside the ${target} hook directory.";
          };

          placement = mkOption {
            type = types.attrs;
            default = { };
            description = "Advanced managed-block placement settings passed to lib.home.managedBlock.";
          };
        };
      };
      default = { };
      description = "Unmanaged zsh integration settings for ${target}.";
    };

  mkZshHookSourceBlock =
    { hookDir }:
    ''
      dotfiles_nix_hook_dir="${hookDir}"
      if [ -d "$dotfiles_nix_hook_dir" ]; then
        for dotfiles_nix_hook in "$dotfiles_nix_hook_dir"/[0-9][0-9]-*.zsh(N); do
          if [ -r "$dotfiles_nix_hook" ]; then
            . "$dotfiles_nix_hook"
          fi
        done
      fi
      unset dotfiles_nix_hook_dir dotfiles_nix_hook
    '';

  mkZshFileConfig =
    { cfg }:
    let
      enabledFiles = filterAttrs (_: file: file.enable) cfg.files;
    in
    {
      home.file =
        (mapAttrs' (
          name: file:
          nameValuePair "${hookDir name}/${file.hookName}" {
            text = file.text;
          }
        ) enabledFiles)
        // (mapAttrs' (
          name: _:
          nameValuePair (dispatcherPath name) {
            text = mkZshHookSourceBlock {
              hookDir = "$HOME/${hookDir name}";
            };
          }
        ) enabledFiles);

      home.activation = mapAttrs' (
        name: file:
        nameValuePair "unmanaged-zsh-${name}" (
          managedBlock.mkActivation {
            name = "zsh ${name}";
            target = targetPath name;
            block = ''. "$HOME/${dispatcherPath name}"'';
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
  options.programs.unmanaged.zsh = {
    enable = mkEnableOption "unmanaged zsh coexistence helpers";

    nativeProgramPolicy = unmanagedProgram.nativeProgramPolicyOption "zsh";

    files = {
      zshenv = managedFileOption {
        target = "~/.zshenv";
      };
      zprofile = managedFileOption {
        target = "~/.zprofile";
      };
      zshrc = managedFileOption {
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
    (mkZshFileConfig {
      inherit cfg;
    })
  ]);
}
