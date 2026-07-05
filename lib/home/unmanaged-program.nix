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

  # Shell hook directories live below ~/.config so top-level files such as
  # ~/.zshrc remain ordinary mutable files for non-Nix-aware tools. Each
  # startup file gets its own directory so users can add ordered entries next
  # to the Nix-managed hook, for example:
  #
  #   ~/.config/zsh/config/zshenv/99-conda.zsh
  hookDir = tool: name: ".config/${tool}/config/${name}";

  # The Nix-managed hook uses a middle order number. Earlier user hooks can
  # prepare state before Nix, while later hooks can override or extend it.
  defaultHookName = extension: "50-nix.${extension}";

  # A managed shell entry targets the conventional dotfile name, for example
  # `zshrc` -> `.zshrc`.
  targetPath = name: ".${name}";

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
      hookExtension ? tool,
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
            description = "Nix-managed hook content written under ~/.config/${tool}/config/.";
          };

          hookName = mkOption {
            type = types.str;
            default = defaultHookName hookExtension;
            description = "Filename for the Nix-managed hook inside the ${target} hook directory.";
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

  # Shared implementation for shell startup files. Given `cfg.files`, it
  # writes one generated fragment per enabled file and injects a managed
  # source block into the matching top-level dotfile.
  #
  # Shell modules provide `mkSourceBlock` because glob and null-match behavior
  # is shell-specific, and this shared helper should not know those details.
  mkShellFileConfig =
    {
      cfg,
      tool,
      hookExtension ? tool,
      mkSourceBlock,
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
        nameValuePair "${hookDir tool name}/${file.hookName}" {
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
            block = mkSourceBlock {
              hookDir = "$HOME/${hookDir tool name}";
              inherit hookExtension;
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
