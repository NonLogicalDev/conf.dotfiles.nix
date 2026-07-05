{
  lib,
  awk ? "awk",
}:

let
  # Pull only the library functions this file uses into local scope. This is
  # common Nix style and makes later call sites shorter without hiding where
  # the functions come from.
  inherit (lib)
    attrByPath
    filterAttrs
    mapAttrs'
    mkForce
    mkIf
    mkMerge
    mkOption
    nameValuePair
    setAttrByPath
    types
    ;

  # This helper is still generic Home Manager block surgery. The current
  # file adds conventions for unmanaged program modules on top of it.
  managedBlock = import ./managed-block.nix { inherit lib awk; };

  # Nix-managed fragments live below ~/.config so top-level files such as
  # ~/.zshrc remain ordinary mutable files for non-Nix-aware tools.
  fragmentPath = tool: name: ".config/dotfiles-nix/${tool}/${name}";

  # A managed shell entry targets the conventional dotfile name, for example
  # `zshrc` -> `.zshrc`.
  targetPath = name: ".${name}";

  # The block inserted into a shell startup file should be tiny: if the
  # generated fragment exists and is readable, source it. Keeping this small
  # reduces the blast radius in files that other tools may edit.
  mkShellSourceBlock =
    { fragmentPath }:
    ''
      if [ -r "${fragmentPath}" ]; then
        . "${fragmentPath}"
      fi
    '';
in
{
  # Shared option for deciding how an unmanaged module relates to Home
  # Manager's native `programs.<tool>` module.
  #
  # `forbid` is intentionally the default because silent mixing can make it
  # unclear which layer owns a top-level config file.
  nativeProgramPolicyOption =
    program:
    mkOption {
      type = types.enum [
        "forbid"
        "force-disable"
        "allow"
      ];
      default = "forbid";
      description = "How to handle Home Manager's native programs.${program} module when unmanaged ${program} is enabled.";
    };

  # Shared config fragment for the policy above. It returns module config,
  # so callers include it inside their module's `config = mkMerge [ ... ]`.
  nativeProgramPolicyConfig =
    {
      # The current Home Manager config tree. We use it only to inspect the
      # native module's enable flag.
      config,

      # The unmanaged module's config, usually bound as `cfg`.
      cfg,

      # Native Home Manager program name, such as `git` or `zsh`.
      program,

      # Full unmanaged option name used in human-readable assertion errors.
      optionName,
    }:
    mkMerge [
      {
        assertions = [
          {
            # `attrByPath` safely reads `programs.<program>.enable` and
            # returns `false` if any path segment is missing.
            assertion =
              cfg.nativeProgramPolicy != "forbid" || !(attrByPath [ "programs" program "enable" ] false config);
            message = "${optionName} conflicts with programs.${program}.enable; set ${optionName}.nativeProgramPolicy to \"allow\" or \"force-disable\" if this is intentional.";
          }
        ];
      }

      # `force-disable` is explicit and visible in config review. It uses
      # `mkForce` because native modules may set their own defaults or merged
      # values at lower priority.
      (mkIf (cfg.nativeProgramPolicy == "force-disable") (
        setAttrByPath [ "programs" program "enable" ] (mkForce false)
      ))
    ];

  # Shared option type for one top-level shell startup file. Each shell module
  # exposes a small attrset of these, for example zshenv/zprofile/zshrc.
  managedFileOption =
    {
      tool,
      target,
    }:
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
            description = "Nix-managed fragment written under ~/.config/dotfiles-nix/${tool}/.";
          };

          placement = mkOption {
            type = types.attrs;
            default = { };
            description = "Advanced managed-block placement settings passed to lib.home.managedBlock.";
          };
        };
      };
      default = { };
      description = "Unmanaged ${tool} integration settings for ${target}.";
    };

  # Expose this so a future shell-like unmanaged module can reuse the source
  # block without opting into the full `mkShellFileConfig` convention.
  inherit mkShellSourceBlock;

  # Shared implementation for shell startup files. Given `cfg.files`, it
  # writes one generated fragment per enabled file and injects a managed
  # source block into the matching top-level dotfile.
  mkShellFileConfig =
    {
      cfg,
      tool,
    }:
    let
      # Disabled file entries stay in the option tree but produce no file and
      # no activation block.
      enabledFiles = filterAttrs (_: file: file.enable) cfg.files;
    in
    {
      # `home.file` writes the Nix-managed fragments. The attr name is the
      # path relative to `$HOME`.
      home.file = mapAttrs' (
        name: file:
        nameValuePair (fragmentPath tool name) {
          text = file.text;
        }
      ) enabledFiles;

      # `home.activation` entries mutate the conventional top-level files at
      # activation time, preserving everything outside the managed block.
      home.activation = mapAttrs' (
        name: file:
        nameValuePair "unmanaged-${tool}-${name}" (
          managedBlock.mkActivation {
            name = "${tool} ${name}";
            target = targetPath name;
            block = mkShellSourceBlock {
              fragmentPath = "$HOME/${fragmentPath tool name}";
            };
            placement = {
              # Shell startup files should see the Nix-managed fragment
              # before installer snippets, aliases, functions, and PATH
              # edits that may depend on Nix-provided tooling. Still keep
              # shebangs and leading file comments first when they exist.
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
}
