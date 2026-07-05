{
  programs.nixvim.plugins.bufferline = {
    enable = true;
    settings.options = {
      indicator = {
        icon = "|";
        style = "icon";
      };
      buffer_close_icon = "x";
      modified_icon = "*";
      close_icon = "x";
      left_trunc_marker = "<";
      right_trunc_marker = ">";
      separator_style = "thin";
      show_buffer_icons = true;
      show_buffer_close_icons = true;
      show_close_icon = true;
      diagnostics = "nvim_lsp";
      diagnostics_indicator.__raw = ''
        function(count, level)
          local icon = level:match("error") and "E " or "W "
          return " " .. icon .. count
        end
      '';
    };
  };
}
