{ ... }:

{
  # Shared NixOS baseline. This mirrors the Darwin/system-manager core modules
  # so every future system profile can evaluate flakes without repeating the
  # setting in each host.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
