{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Fish already has the shape we wished legacy shells had: an XDG config tree
  # plus native drop-ins under ~/.config/fish/conf.d, functions, and
  # completions. This module does not create a parallel rc.d/hook system. It
  # only moves Home Manager's generated top-level config.fish into a fish-native
  # conf.d drop-in, then leaves ~/.config/fish/config.fish as a regular mutable
  # file for humans and Nix-oblivious tools.
  inherit (lib)
    attrByPath
    mkDefault
    mkEnableOption
    mkForce
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.programs.unmanaged.fish;

  nativeFishConfigSource = attrByPath [
    "xdg"
    "configFile"
    "fish/config.fish"
    "source"
  ] null config;

  hasNativeFishConfigSource = nativeFishConfigSource != null;

  managedDropInPath = "fish/conf.d/${cfg.managedDropInName}";

  # Only config.fish stops being a Home Manager link. Other fish files stay
  # native: generated completions, plugin loaders, functions, and translated
  # hm-session-vars.fish still belong in the normal XDG fish tree.
  disableNativeFishConfigLink = {
    xdg.configFile."fish/config.fish".enable = mkForce false;
  };

  managedDropInFile =
    if cfg.includeHomeManagerFishContent && config.programs.fish.enable then
      {
        source =
          pkgs.runCommandLocal "unmanaged-fish-managed-drop-in"
            {
              nativeConfig = nativeFishConfigSource;
              extraText = cfg.managedDropInText;
              passAsFile = [ "extraText" ];
            }
            ''
              cat "$nativeConfig" > "$out"
              if [ -s "$extraTextPath" ]; then
                printf '\n' >> "$out"
                cat "$extraTextPath" >> "$out"
              fi
            '';
      }
    else
      {
        text = cfg.managedDropInText;
      };
in
{
  options.programs.unmanaged.fish = {
    enable = mkEnableOption "unmanaged fish top-level config bridge";

    includeHomeManagerFishContent = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether unmanaged fish should copy Home Manager's generated
        config.fish body into a fish-native conf.d drop-in.

        This enables Home Manager's native fish module as a content generator,
        then disables only its native config.fish link. Native fish support
        files remain Home Manager-managed in their normal XDG locations.
      '';
    };

    managedDropInName = mkOption {
      type = types.str;
      default = "50-nix-managed.fish";
      description = "Filename for the Home Manager-generated fish drop-in under ~/.config/fish/conf.d.";
    };

    managedDropInText = mkOption {
      type = types.lines;
      default = "";
      description = "Extra Nix-managed fish code appended after Home Manager's generated fish startup code.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.includeHomeManagerFishContent || config.programs.fish.enable;
          message = ''
            programs.unmanaged.fish.includeHomeManagerFishContent requires
            programs.fish.enable so Home Manager can generate the fish startup
            code that unmanaged fish copies into a conf.d drop-in.
          '';
        }
        {
          assertion = cfg.includeHomeManagerFishContent || !config.programs.fish.enable;
          message = ''
            programs.unmanaged.fish cannot be combined with programs.fish.enable
            when programs.unmanaged.fish.includeHomeManagerFishContent is false.

            Either keep includeHomeManagerFishContent enabled so unmanaged fish
            can use native Home Manager fish as a content generator while
            suppressing the native config.fish link, or disable programs.fish.enable.
          '';
        }
        {
          assertion = !cfg.includeHomeManagerFishContent || hasNativeFishConfigSource;
          message = ''
            programs.unmanaged.fish.includeHomeManagerFishContent expected
            Home Manager to expose xdg.configFile."fish/config.fish".source,
            but no generated fish config source was found.
          '';
        }
      ];
    }
    (mkIf cfg.includeHomeManagerFishContent {
      programs.fish.enable = mkDefault true;
    })
    (mkIf (
      cfg.includeHomeManagerFishContent && config.programs.fish.enable
    ) disableNativeFishConfigLink)
    {
      xdg.configFile.${managedDropInPath} = managedDropInFile;

      # If a previous Home Manager generation left config.fish as a /nix/store
      # symlink, replace it with an empty regular file. The generated content
      # now lives in conf.d, so copying the old store file here would duplicate
      # startup behavior. Existing regular files are left untouched.
      home.activation.unmanaged-fish-config = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        target="$HOME/.config/fish/config.fish"

        mkdir -p "$(dirname "$target")"
        if [ -L "$target" ]; then
          link_target="$(readlink "$target")"
          case "$link_target" in
            /nix/store/*)
              rm "$target"
              : > "$target"
              ;;
            *)
              echo "Refusing to replace $target because it is a symlink to $link_target." >&2
              echo "Replace it with a regular file before enabling unmanaged fish." >&2
              exit 1
              ;;
          esac
        elif [ ! -e "$target" ]; then
          : > "$target"
        fi
      '';
    }
  ]);
}
