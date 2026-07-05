{
  programs.nixvim = {
    # One explicit colorscheme for the suite. Theme churn belongs in this small
    # file instead of being scattered through UI plugin config.
    colorscheme = "catppuccin-mocha";
    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "mocha";
    };
  };
}
