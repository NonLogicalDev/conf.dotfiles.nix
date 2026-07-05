{
  programs.nixvim = {
    # Fast in-buffer jump target selection. It owns `s`, replacing the old
    # character-search muscle memory with a richer jump UI.
    plugins.flash.enable = true;

    keymaps = [
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "s";
        action.__raw = ''
          function()
            require("flash").jump()
          end
        '';
        options.desc = "Flash";
      }
    ];
  };
}
