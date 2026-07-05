{ config, ... }:

{
  # Treesitter owns parsing/highlighting/indent for languages that are common
  # in this environment. The grammar list is explicit to keep closure size and
  # startup behavior understandable.
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
