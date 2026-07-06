{
  # Fish is not the primary shell for this host-user profile. We still enable
  # the Home Manager fish module so shell-neutral integrations can generate fish
  # startup code from their own options. Unlike bash and zsh, fish already has
  # a first-class XDG config tree with drop-in-style locations such as
  # ~/.config/fish/conf.d, functions, and completions. The unmanaged bridge
  # below is therefore only about keeping ~/.config/fish/config.fish writable;
  # native fish support files stay under Home Manager's normal ownership.
  programs.fish.enable = true;
  programs.unmanaged.fish.enable = true;
}
