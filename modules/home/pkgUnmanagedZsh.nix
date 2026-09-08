{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # Zsh is the primary shell, and many non-Nix tools still append to ~/.zshrc,
  # ~/.zprofile, or ~/.zshenv. This module lets Home Manager generate complete
  # zsh startup content while conventional startup files remain editable.
  inherit (lib)
    attrByPath
    concatStringsSep
    filter
    filterAttrs
    listToAttrs
    mapAttrs'
    mkDefault
    mkEnableOption
    mkForce
    mkIf
    mkMerge
    mkOption
    nameValuePair
    optional
    optionalAttrs
    optionalString
    types
    unique
    ;

  cfg = config.programs.unmanaged.zsh;
  managedBlock = inputs.self.lib.home.managedBlock {
    inherit lib;
    awk = "${pkgs.gawk}/bin/awk";
  };

  # Hook layout:
  #   ~/.config/zsh/rc/zshrc.d/50-nix-managed.zsh
  #   ~/.config/zsh/rc/zshrc.zsh
  # The top-level ~/.zshrc only sources the dispatcher. The dispatcher owns the
  # glob over numbered hooks, so managed blocks never contain shell logic.
  hookDir = name: ".config/zsh/rc/${name}.d";
  dispatcherPath = name: ".config/zsh/rc/${name}.zsh";
  # Keep the editable startup files at their conventional locations so tools
  # that append to ~/.zshrc or ~/.zprofile continue to affect shell startup.
  targetPath = name: ".${name}";
  defaultHookName = "50-nix-managed.zsh";

  nativeZshFileNames = [
    "zshenv"
    "zprofile"
    "zshrc"
    "zlogin"
    "zlogout"
  ];

  nativeZshFileKey = name: "${config.lib.zsh.dotDirRel}/.${name}";

  # Let Home Manager's zsh module build the full file text after every zsh
  # option, plugin module, and unrelated program integration has contributed.
  # The unmanaged module then copies that final text into its own hook. This is
  # intentionally different from reimplementing Home Manager's zsh fragments:
  # it preserves native behavior such as fpath, HELPDIR, completion, history,
  # aliases, session variables, zplug/antidote/oh-my-zsh/prezto content, and
  # third-party modules that append to programs.zsh.initContent.
  nativeZshFileText =
    name:
    let
      text = attrByPath [
        "home"
        "file"
        (nativeZshFileKey name)
        "text"
      ] "" config;
    in
    if text == null then "" else text;

  nativeZshOwnedFileKeys = unique (
    (map nativeZshFileKey nativeZshFileNames) ++ (optional (config.lib.zsh.dotDirRel != ".") ".zshenv")
  );

  # Home Manager normally owns files below programs.zsh.dotDir. In unmanaged
  # mode those rendered files are copied into hooks instead, then disabled so
  # the mutable files that zsh actually reads can be maintained by activation
  # blocks.
  disableNativeZshFileLinks = listToAttrs (
    map (name: nameValuePair name { enable = mkForce false; }) nativeZshOwnedFileKeys
  );

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

  mkHookText =
    name: file:
    concatStringsSep "\n" (
      filter (text: text != "") [
        (optionalString (cfg.includeHomeManagerZshContent && config.programs.zsh.enable) (
          nativeZshFileText name
        ))
        file.text
      ]
    );

  # Zsh can use the `(N)` glob qualifier for "no match means empty list". Keep
  # this zsh-specific dispatcher here instead of pushing shell rules into the
  # generic managed-block helper.
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
      redirectedFiles = filterAttrs (name: _: name != "zshenv") enabledFiles;
      managedPlacement = file: {
        mode = "after-preamble";
        relocateExisting = true;
        preambleLineRegexes = [
          "^#!"
          "^#($|[[:space:]])"
          "^[[:space:]]*$"
        ];
      } // file.placement;
    in
    {
      home.file =
        (mapAttrs' (
          name: file:
          nameValuePair "${hookDir name}/${file.hookName}" {
            text = mkHookText name file;
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

      home.activation =
        (mapAttrs' (
          name: file:
          nameValuePair "unmanaged-zsh-${name}" (
            managedBlock.mkActivation {
              name = "zsh ${name}";
              target = targetPath name;
              block = ''. "$HOME/${dispatcherPath name}"'';
              placement = managedPlacement file;
            }
          )
        ) enabledFiles)
        // (optionalAttrs (config.lib.zsh.dotDirRel != ".") (
          mapAttrs' (
            name: file:
            nameValuePair "unmanaged-zsh-dotdir-${name}" (
              managedBlock.mkActivation {
                # Replace the existing dispatcher marker in the dot directory;
                # the dispatcher now runs once from the editable top-level file.
                name = "zsh ${name}";
                target = "${config.lib.zsh.dotDirRel}/.${name}";
                block = ''
                  if [ -r "$HOME/.${name}" ]; then
                    . "$HOME/.${name}"
                  fi
                '';
                placement = (managedPlacement file) // {
                  relocateExisting = false;
                };
              }
            )
          ) redirectedFiles
        ));
    };
in
{
  options.programs.unmanaged.zsh = {
    enable = mkEnableOption "unmanaged zsh coexistence helpers";

    includeHomeManagerZshContent = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether unmanaged zsh should copy the generated Home Manager zsh
        file bodies into its numbered Nix-managed hooks.

        This enables Home Manager's native zsh module as a content generator,
        then disables the native top-level zsh file links. That preserves
        Home Manager internals such as fpath, HELPDIR, completion, history,
        aliases, session variables, and integrations from unrelated Home
        Manager program modules without requiring Home Manager to own the
        conventional top-level zsh files.
      '';
    };

    files = {
      zshenv = managedFileOption {
        target = "~/.zshenv";
      };
      zprofile = managedFileOption {
        target = "~/${targetPath "zprofile"}";
      };
      zshrc = managedFileOption {
        target = "~/${targetPath "zshrc"}";
      };
      zlogin = managedFileOption {
        target = "~/${targetPath "zlogin"}";
      };
      zlogout = managedFileOption {
        target = "~/${targetPath "zlogout"}";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.includeHomeManagerZshContent || !config.programs.zsh.enable;
          message = ''
            programs.unmanaged.zsh cannot be combined with programs.zsh.enable
            when programs.unmanaged.zsh.includeHomeManagerZshContent is false.

            Either keep includeHomeManagerZshContent enabled so unmanaged zsh
            can use native Home Manager zsh as a content generator while
            suppressing native startup-file links, or disable programs.zsh.enable.
          '';
        }
        {
          assertion = !cfg.includeHomeManagerZshContent || config.programs.zsh.enable;
          message = ''
            programs.unmanaged.zsh.includeHomeManagerZshContent requires
            programs.zsh.enable so Home Manager can generate the complete zsh
            file bodies that unmanaged zsh copies into numbered hooks.
          '';
        }
      ];
    }
    (mkIf cfg.includeHomeManagerZshContent {
      programs.zsh.enable = mkDefault true;
    })
    (mkIf (cfg.includeHomeManagerZshContent && config.programs.zsh.enable) {
      home.file = disableNativeZshFileLinks;
    })
    (mkZshFileConfig {
      inherit cfg;
    })
  ]);
}
