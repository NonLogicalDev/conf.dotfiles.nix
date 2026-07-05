{
  # Fish is not the primary shell for this host-user profile. We still enable
  # the Home Manager fish module so shell-neutral integrations can generate fish
  # startup code from their own options.
  programs.fish.enable = true;
}
