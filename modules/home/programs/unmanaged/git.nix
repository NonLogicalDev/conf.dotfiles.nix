{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    concatStringsSep
    filter
    mkDefault
    mkEnableOption
    mkForce
    mkIf
    mkMerge
    mkOption
    optionalString
    types
    ;

  cfg = config.programs.unmanaged.git;
  managedBlock = inputs.self.lib.home.managedBlock {
    inherit lib;
    awk = "${pkgs.gawk}/bin/awk";
  };

  # Home Manager's native git module renders its main configuration to
  # xdg.configFile."git/config".text. In unmanaged mode we keep using that
  # native module as the Git config generator, but we copy the rendered text
  # into our managed include fragment instead of letting Home Manager own the
  # mutable ~/.config/git/config file directly.
  nativeGitConfigText = config.xdg.configFile."git/config".text or "";

  managedGitConfigText = concatStringsSep "\n" (
    filter (text: text != "") [
      (optionalString (
        cfg.includeHomeManagerGitContent && config.programs.git.enable
      ) nativeGitConfigText)
      cfg.managedConfig
    ]
  );
in
{
  options.programs.unmanaged.git = {
    enable = mkEnableOption "unmanaged git coexistence helpers";

    includeHomeManagerGitContent = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether unmanaged git should copy Home Manager's generated
        programs.git configuration into the managed include fragment.

        This enables Home Manager's native git module as a content generator,
        then disables only the native git/config file link. Other native Git
        side effects, such as the Git package, global ignore file, attributes
        file, hooks path, and maintenance integration, remain available.
      '';
    };

    managedConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional Nix-managed Git config appended after the generated
        Home Manager Git config in ~/.config/dotfiles-nix/git/config.
      '';
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
    {
      assertions = [
        {
          assertion = cfg.includeHomeManagerGitContent || !config.programs.git.enable;
          message = ''
            programs.unmanaged.git cannot be combined with programs.git.enable
            when programs.unmanaged.git.includeHomeManagerGitContent is false.

            Either keep includeHomeManagerGitContent enabled so unmanaged git
            can use native Home Manager git as a content generator while
            suppressing only the native git/config link, or disable
            programs.git.enable.
          '';
        }
        {
          assertion = !cfg.includeHomeManagerGitContent || config.programs.git.enable;
          message = ''
            programs.unmanaged.git.includeHomeManagerGitContent requires
            programs.git.enable so Home Manager can generate the complete Git
            configuration that unmanaged git writes to its include fragment.
          '';
        }
      ];
    }
    (mkIf cfg.includeHomeManagerGitContent {
      programs.git.enable = mkDefault true;
    })
    (mkIf (cfg.includeHomeManagerGitContent && config.programs.git.enable) {
      xdg.configFile."git/config".enable = mkForce false;
    })
    {
      home.file.".config/dotfiles-nix/git/config".text = managedGitConfigText;

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
