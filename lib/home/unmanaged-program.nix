{
  lib,
}:

let
  # Pull only the library functions this file uses into local scope. This is
  # common Nix style and makes later call sites shorter without hiding where
  # the functions come from.
  inherit (lib)
    attrByPath
    mkForce
    mkIf
    mkMerge
    mkOption
    setAttrByPath
    types
    ;
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
}
