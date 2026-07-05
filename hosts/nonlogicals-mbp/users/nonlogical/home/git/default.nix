{ ... }:

{
  # Phase 1 is review-only staging. These files are copied from the current
  # Dotter-era Git setup, but activation should not replace live Git paths yet.
  #
  # The cutover step should rewrite the current credential helper before it
  # becomes durable Nix config, because the old config points at a concrete
  # /nix/store gh wrapper path.
  home.file.".config/dotfiles-nix/staged/git" = {
    source = ./files;
    recursive = true;
  };
}
