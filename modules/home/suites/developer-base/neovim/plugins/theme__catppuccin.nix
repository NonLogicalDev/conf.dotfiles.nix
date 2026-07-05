{
  programs.nixvim = {
    colorscheme = "catppuccin-mocha";
    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "mocha";
    };
  };
}
