{
  # Minimal statusline: no icon dependency in the statusline itself, no heavy
  # separators, and theme follows the active colorscheme.
  programs.nixvim.plugins.lualine = {
    enable = true;
    settings.options = {
      theme = "auto";
      icons_enabled = false;
      component_separators = "";
      section_separators = "";
    };
  };
}
