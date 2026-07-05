{ ... }:

{
  # Phase 1 is review-only staging. These files are copied from the current
  # Dotter-era zsh setup, but activation should not replace live zsh paths yet.
  #
  # The cutover step should decide whether to preserve the legacy
  # ~/.config/zsh/hooks layout or translate it into programs.unmanaged.zsh's
  # ~/.config/zsh/rc/<startup-file>.d layout before enabling live ownership.
  home.file.".config/dotfiles-nix/staged/zsh" = {
    source = ./files;
    recursive = true;
  };
}
