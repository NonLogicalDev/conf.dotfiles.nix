{
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
