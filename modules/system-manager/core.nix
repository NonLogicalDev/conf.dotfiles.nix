{ ... }:

{
  # system-manager uses a slightly different module shape, so the same shared
  # Nix baseline lives under `config`. Keep this parallel with the Darwin and
  # NixOS core modules unless system-manager needs a real divergence.
  config = {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
