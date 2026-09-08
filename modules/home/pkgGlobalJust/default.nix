{ config, lib, pkgs, ... }:
let
  cfg = config.programs.globalJust;
  entryPath = name: "${config.xdg.configHome}/global-just/${name}.just";
  importLine = entry: "import${lib.optionalString entry.optional "?"} ${builtins.toJSON entry.path}";
  wrappers = lib.mapAttrs (name: _: pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = [ pkgs.just ];
    text = ''
      export JUST_JUSTFILE=${lib.escapeShellArg (entryPath name)}
      exec just "$@"
    '';
  }) cfg;
  completions = lib.mapAttrs (name: _: pkgs.runCommand "${name}-completions" {
    nativeBuildInputs = [ pkgs.just pkgs.python3 ];
  } ''
    mkdir -p "$out"
    for shell in bash fish zsh; do
      JUST_COMPLETE="$shell" just --completions "$shell" > "$shell.raw"
      python3 ${./rename-completion.py} ${lib.escapeShellArg name} < "$shell.raw" > "$out/$shell"
    done
  '') cfg;
in {
  options.programs.globalJust = lib.mkOption {
    default = { };
    description = "Named global Justfile commands with Bash, Fish, and Zsh completion.";
    type = lib.types.attrsOf (lib.types.submodule {
      options.justfiles = lib.mkOption {
        default = [ ];
        description = "Ordered runtime imports; optional files may appear without rebuilding.";
        type = lib.types.listOf (lib.types.submodule {
          options = {
            path = lib.mkOption {
              type = lib.types.str;
              description = "Absolute path or ~/ path to a Justfile outside the Nix store.";
            };
            optional = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Skip the import when the file is missing.";
            };
          };
        });
      };
    });
  };
  config = lib.mkIf (cfg != { }) {
    assertions = lib.mapAttrsToList (name: _: {
      assertion = name != "just" && builtins.match "[A-Za-z][A-Za-z0-9_-]*" name != null;
      message = "globalJust command names must be shell-safe names other than just.";
    }) cfg;
    home.packages = [ pkgs.just ] ++ lib.attrValues wrappers;
    xdg.configFile = lib.mapAttrs' (name: spec: lib.nameValuePair "global-just/${name}.just" {
      text = ''
        [private]
        _global-just-list:
            @just --justfile "{{justfile()}}" --list

        ${lib.concatMapStringsSep "\n" importLine spec.justfiles}
      '';
    }) cfg;
    programs.bash.initExtra = lib.concatMapStringsSep "\n" (name:
      "source ${completions.${name}}/bash"
    ) (lib.attrNames cfg);
    programs.fish.interactiveShellInit = lib.concatMapStringsSep "\n" (name:
      "source ${completions.${name}}/fish"
    ) (lib.attrNames cfg);
    programs.zsh.initContent = lib.mkOrder 580 (lib.concatMapStringsSep "\n" (name:
      "source ${completions.${name}}/zsh"
    ) (lib.attrNames cfg));
  };
}
