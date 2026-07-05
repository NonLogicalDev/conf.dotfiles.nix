{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # This module exists because some installers still mutate conventional files
  # such as ~/.bashrc directly. We still want Home Manager's native Bash module
  # to generate the real Bash content, but we do not want it to own the mutable
  # top-level files. The bridge writes HM content into numbered hook files and
  # places one managed source line in each conventional file.
  inherit (lib)
    concatStringsSep
    filter
    filterAttrs
    hasPrefix
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
    removePrefix
    types
    ;

  cfg = config.programs.unmanaged.bash;
  bashCfg = config.programs.bash;
  managedBlock = inputs.self.lib.home.managedBlock {
    inherit lib;
    awk = "${pkgs.gawk}/bin/awk";
  };

  # Hook layout mirrors the zsh unmanaged bridge:
  #   ~/.config/bash/rc/bashrc.d/50-nix-managed.bash
  #   ~/.config/bash/rc/bashrc.bash
  # The conventional ~/.bashrc only sources the dispatcher. The dispatcher then
  # sources numbered hooks, leaving room for non-Nix tools or humans to add
  # later numbered files without teaching those tools about Nix.
  hookDir = name: ".config/bash/rc/${name}.d";
  dispatcherPath = name: ".config/bash/rc/${name}.bash";
  targetPath = name: ".${name}";
  defaultHookName = "50-nix-managed.bash";

  nativeBashFileNames = [
    "bash_profile"
    "profile"
    "bashrc"
    "bash_logout"
  ];

  nativeBashFileKey = name: ".${name}";

  # Once unmanaged mode is enabled, Home Manager must not symlink the top-level
  # Bash files directly. It still computes their content above; we copy that
  # content into hooks and force-disable the native file links afterward.
  disableNativeBashFileLinks = listToAttrs (
    map (name: nameValuePair (nativeBashFileKey name) { enable = mkForce false; }) nativeBashFileNames
  );

  aliasesStr = concatStringsSep "\n" (
    lib.mapAttrsToList (k: v: "alias -- ${k}=${lib.escapeShellArg v}") bashCfg.shellAliases
  );

  shellOptionsStr =
    let
      switch = value: if hasPrefix "-" value then "-u" else "-s";
    in
    concatStringsSep "\n" (
      map (value: "shopt ${switch value} ${removePrefix "-" value}") bashCfg.shellOptions
    );

  sessionVariablesStr = config.lib.shell.exportAll bashCfg.sessionVariables;

  historyControlStr = concatStringsSep "\n" (
    (lib.mapAttrsToList (name: value: "${name}=${value}") (
      (optionalAttrs (bashCfg.historyFileSize != null) {
        HISTFILESIZE = toString bashCfg.historyFileSize;
      })
      // (optionalAttrs (bashCfg.historySize != null) {
        HISTSIZE = toString bashCfg.historySize;
      })
      // (optionalAttrs (bashCfg.historyFile != null) {
        HISTFILE = ''"${bashCfg.historyFile}"'';
      })
      // (optionalAttrs (bashCfg.historyControl != [ ]) {
        HISTCONTROL = concatStringsSep ":" bashCfg.historyControl;
      })
      // (optionalAttrs (bashCfg.historyIgnore != [ ]) {
        HISTIGNORE = lib.escapeShellArg (concatStringsSep ":" bashCfg.historyIgnore);
      })
    ))
    ++ (optional (bashCfg.historyFile != null) ''mkdir -p "$(dirname "$HISTFILE")"'')
  );

  # This mirrors Home Manager's bash module output while still letting native
  # programs.bash merge all of its options first. The generated content includes
  # snippets from unrelated Home Manager modules because they contribute to
  # programs.bash.initExtra, programs.bash.shellAliases, session variables, and
  # related options before these strings are evaluated.
  nativeBashFileText = {
    bash_profile = ''
      # include .profile if it exists
      [[ -f ~/.profile ]] && . ~/.profile

      # include .bashrc if it exists
      [[ -f ~/.bashrc ]] && . ~/.bashrc
    '';
    profile = ''
      . "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"

      ${sessionVariablesStr}

      ${bashCfg.profileExtra}
    '';
    bashrc = ''
      ${bashCfg.bashrcExtra}

      # Commands that should be applied only for interactive shells.
      [[ $- == *i* ]] || return

      ${historyControlStr}

      ${shellOptionsStr}

      ${aliasesStr}

      ${bashCfg.initExtra}
    '';
    bash_logout = bashCfg.logoutExtra;
  };

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

  # A hook file combines Home Manager's generated content with any explicit
  # extra text supplied through programs.unmanaged.bash.files.<name>.text. The
  # extra text comes last so a profile can deliberately append local behavior.
  mkHookFile = name: file: {
    text = concatStringsSep "\n" (
      filter (text: text != "") [
        (optionalString (cfg.includeHomeManagerBashContent && config.programs.bash.enable) (
          nativeBashFileText.${name}
        ))
        file.text
      ]
    );
  };

  mkBashHookSourceBlock =
    { hookDir, name }:
    ''
      _dotfiles_nix_source_${name}_hooks() {
        local dotfiles_nix_hook_dir="${hookDir}"
        local dotfiles_nix_hook
        local dotfiles_nix_had_nullglob

        if [ ! -d "$dotfiles_nix_hook_dir" ]; then
          return
        fi

        if shopt -q nullglob; then
          dotfiles_nix_had_nullglob=1
        else
          dotfiles_nix_had_nullglob=0
        fi
        shopt -s nullglob
        for dotfiles_nix_hook in "$dotfiles_nix_hook_dir"/[0-9][0-9]-*.bash; do
          if [ -r "$dotfiles_nix_hook" ]; then
            . "$dotfiles_nix_hook"
          fi
        done
        if [ "$dotfiles_nix_had_nullglob" -eq 0 ]; then
          shopt -u nullglob
        fi
      }

      _dotfiles_nix_source_${name}_hooks
      unset -f _dotfiles_nix_source_${name}_hooks
    '';

  mkPosixHookSourceBlock =
    { hookDir }:
    ''
      dotfiles_nix_hook_dir="${hookDir}"
      if [ -d "$dotfiles_nix_hook_dir" ]; then
        for dotfiles_nix_hook in "$dotfiles_nix_hook_dir"/[0-9][0-9]-*.bash; do
          if [ -e "$dotfiles_nix_hook" ] && [ -r "$dotfiles_nix_hook" ]; then
            . "$dotfiles_nix_hook"
          fi
        done
      fi
      unset dotfiles_nix_hook_dir dotfiles_nix_hook
    '';

  # For every enabled Bash startup file we generate two things:
  # 1. the numbered hook that contains Nix/Home Manager content;
  # 2. a dispatcher file that a tiny managed block in ~/.bashrc-like files can
  #    source. Keeping logic out of the top-level managed block makes it easier
  #    for humans and third-party tools to keep editing those files.
  mkBashFileConfig =
    { cfg }:
    let
      enabledFiles = filterAttrs (_: file: file.enable) cfg.files;
    in
    {
      home.file =
        (mapAttrs' (
          name: file: nameValuePair "${hookDir name}/${file.hookName}" (mkHookFile name file)
        ) enabledFiles)
        // (mapAttrs' (
          name: _:
          nameValuePair (dispatcherPath name) {
            text =
              if name == "profile" then
                mkPosixHookSourceBlock {
                  hookDir = "$HOME/${hookDir name}";
                }
              else
                mkBashHookSourceBlock {
                  inherit name;
                  hookDir = "$HOME/${hookDir name}";
                };
          }
        ) enabledFiles);

      home.activation = mapAttrs' (
        name: file:
        nameValuePair "unmanaged-bash-${name}" (
          managedBlock.mkActivation {
            name = "bash ${name}";
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
  options.programs.unmanaged.bash = {
    enable = mkEnableOption "unmanaged bash coexistence helpers";

    includeHomeManagerBashContent = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether unmanaged bash should copy the generated Home Manager bash
        file bodies into its numbered Nix-managed hooks.

        This enables Home Manager's native bash module as a content generator,
        then disables the native top-level bash file links. That preserves
        Home Manager internals such as hm-session-vars.sh, completion, history,
        shell options, aliases, logout content, and integrations from unrelated
        Home Manager program modules without requiring Home Manager to own the
        conventional top-level bash files.
      '';
    };

    files = {
      bash_profile = managedFileOption {
        target = "~/.bash_profile";
      };
      profile = managedFileOption {
        target = "~/.profile";
      };
      bashrc = managedFileOption {
        target = "~/.bashrc";
      };
      bash_logout = managedFileOption {
        target = "~/.bash_logout";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.includeHomeManagerBashContent || !config.programs.bash.enable;
          message = ''
            programs.unmanaged.bash cannot be combined with programs.bash.enable
            when programs.unmanaged.bash.includeHomeManagerBashContent is false.

            Either keep includeHomeManagerBashContent enabled so unmanaged bash
            can use native Home Manager bash as a content generator while
            suppressing native startup-file links, or disable programs.bash.enable.
          '';
        }
        {
          assertion = !cfg.includeHomeManagerBashContent || config.programs.bash.enable;
          message = ''
            programs.unmanaged.bash.includeHomeManagerBashContent requires
            programs.bash.enable so Home Manager can generate the complete bash
            file bodies that unmanaged bash copies into numbered hooks.
          '';
        }
      ];
    }
    (mkIf cfg.includeHomeManagerBashContent {
      programs.bash.enable = mkDefault true;
    })
    (mkIf (cfg.includeHomeManagerBashContent && config.programs.bash.enable) {
      home.file = disableNativeBashFileLinks;
    })
    (mkBashFileConfig {
      inherit cfg;
    })
  ]);
}
