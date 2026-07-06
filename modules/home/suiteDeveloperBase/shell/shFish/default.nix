{
  # Fish is not the primary shell for this host-user profile. We still enable
  # the Home Manager fish module so shell-neutral integrations can generate fish
  # startup code from their own options. Unlike bash and zsh, fish already has
  # a first-class XDG config tree with drop-in-style locations such as
  # ~/.config/fish/conf.d, functions, and completions, so this profile should
  # not force it through the unmanaged top-level-file bridge by default.
  programs.fish.enable = true;
}
