{ ... }:

{
  # Shared nix-darwin baseline. Keep this intentionally tiny: host-specific
  # users, services, and system defaults belong under hosts/<host>/, while this
  # module only provides flake-capable Nix for every Darwin machine.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
