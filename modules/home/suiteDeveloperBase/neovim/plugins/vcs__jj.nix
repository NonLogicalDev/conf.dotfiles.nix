{ pkgs, ... }:

{
  programs.nixvim = {
    # Keep the editor integration independent of personal Jujutsu identity.
    extraPlugins = [ pkgs.vimPlugins.jj-nvim ];

    extraConfigLuaPost = ''
      require("jj").setup({})
    '';
  };
}
