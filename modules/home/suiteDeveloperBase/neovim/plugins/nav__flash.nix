{
  programs.nixvim = {
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
