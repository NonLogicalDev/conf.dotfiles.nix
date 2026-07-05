{ config, ... }:

{
  programs.nixvim.plugins.treesitter = {
    enable = true;
    highlight.enable = true;
    indent.enable = true;
    grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
      c
      go
      html
      javascript
      lua
      query
      rust
      typescript
      vim
      vimdoc
      yaml
    ];
  };
}
