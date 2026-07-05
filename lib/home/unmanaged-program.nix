{ lib }:

let
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

  managedBlock = import ./managed-block.nix { inherit lib; };

  fragmentPath = tool: name: ".config/dotfiles-nix/${tool}/${name}";
  targetPath = name: ".${name}";
  mkShellSourceBlock =
    { fragmentPath }:
    ''
      if [ -r "${fragmentPath}" ]; then
        . "${fragmentPath}"
      fi
    '';
in
{
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

  nativeProgramPolicyConfig =
    {
      config,
      cfg,
      program,
      optionName,
    }:
    mkMerge [
      {
        assertions = [
          {
            assertion =
              cfg.nativeProgramPolicy != "forbid" || !(attrByPath [ "programs" program "enable" ] false config);
            message = "${optionName} conflicts with programs.${program}.enable; set ${optionName}.nativeProgramPolicy to \"allow\" or \"force-disable\" if this is intentional.";
          }
        ];
      }

      (mkIf (cfg.nativeProgramPolicy == "force-disable") (
        setAttrByPath [ "programs" program "enable" ] (mkForce false)
      ))
    ];

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
        };
      };
      default = { };
      description = "Unmanaged ${tool} integration settings for ${target}.";
    };

  inherit mkShellSourceBlock;

  mkShellFileConfig =
    {
      cfg,
      tool,
    }:
    let
      enabledFiles = filterAttrs (_: file: file.enable) cfg.files;
    in
    {
      home.file = mapAttrs' (
        name: file:
        nameValuePair (fragmentPath tool name) {
          text = file.text;
        }
      ) enabledFiles;

      home.activation = mapAttrs' (
        name: _:
        nameValuePair "unmanaged-${tool}-${name}" (
          managedBlock.mkActivation {
            name = "${tool} ${name}";
            target = targetPath name;
            block = mkShellSourceBlock {
              fragmentPath = "$HOME/${fragmentPath tool name}";
            };
          }
        )
      ) enabledFiles;
    };
}
