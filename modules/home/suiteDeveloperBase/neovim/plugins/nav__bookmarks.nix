{ pkgs, ... }:

let
  bookmarks = pkgs.vimUtils.buildVimPlugin {
    pname = "bookmarks.nvim";
    version = "3.2.0";
    doCheck = false;

    src = pkgs.fetchFromGitHub {
      owner = "LintaoAmons";
      repo = "bookmarks.nvim";
      rev = "refs/tags/3.2.0";
      hash = "sha256-VwE3RWMJrY7qXwE85yJIvm6KA3zyEDid7ZeQ6LRu8hk=";
    };
  };
in

{
  programs.nixvim = {
    # Keep bookmarks and their SQLite storage dependency together.
    extraPlugins = [
      bookmarks
      pkgs.vimPlugins.sqlite-lua
    ];

    extraConfigLuaPost = ''
      require("bookmarks").setup({})
    '';
  };
}
