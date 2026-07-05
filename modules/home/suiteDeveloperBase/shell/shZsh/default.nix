{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    concatMapStringsSep
    escapeShellArg
    mkMerge
    mkOrder
    ;

  aliases = import ./cfg-aliases.nix;
  plugins = import ./cfg-plugins.nix { inherit pkgs; };
  shellOptions = import ./cfg-options.nix;

  # Home Manager merges `programs.zsh.initContent` by numeric order. The chosen
  # values intentionally sit around Home Manager's own zsh anchors: plugin paths
  # at 560, compinit at 570, plugin sources at 900, aliases at 1100, syntax
  # highlighting at 1200, and history finalization at 1250.
  initOrder = {
    # Completion styling must exist before compinit reads completion state.
    beforeCompletion = 550;

    # Key bindings/widgets should exist before plugins such as fzf-tab inspect
    # or wrap completion behavior.
    beforePluginSources = 880;

    # Prompt selection happens after custom widgets but before plugin sources.
    prompt = 890;
  };

  # Keep generated zsh files under ~/.config/zsh so the unmanaged top-level
  # ~/.zshrc bridge can stay small and mutable.
  zshConfigDir = "${config.home.homeDirectory}/.config/zsh";

  # Put zsh history and completion caches outside the repo-managed config tree.
  zshCacheDir = "${config.home.homeDirectory}/.cache/zsh";

  # Companion zsh files are source files for readability, but the generated
  # Home Manager zshrc gets their text directly. That avoids runtime sourcing of
  # private Nix store paths for every small startup fragment.
  readFragments = files: concatMapStringsSep "\n\n" builtins.readFile files;

  # Home Manager writes each attrset entry as one file in zsh's site-functions
  # directory. The filename is the zsh autoload name, so keep the source files
  # named exactly as the commands or prompt functions they define.
  localFunctionFiles = lib.filter (path: pkgs.stdenv.isDarwin || builtins.baseNameOf path != "cdf") (
    lib.filesystem.listFilesRecursive ./lib/functions
  );
  localSiteFunctions = builtins.listToAttrs (
    map (path: {
      name = builtins.baseNameOf path;
      value = builtins.readFile path;
    }) localFunctionFiles
  );

  # `microprompt` is a zsh prompt theme, not a plugin. The function source lives
  # in `lib/functions/prompts/prompt_microprompt_setup` and is autoloaded by
  # Home Manager's `siteFunctions` support.
  promptTheme = "microprompt";

  # Use zsh's native prompt framework so prompt switching and hook cleanup
  # behave like normal zsh themes.
  promptInit = ''
    autoload -Uz promptinit
    promptinit
    prompt ${escapeShellArg promptTheme}
  '';

  # Early init is for terminal/completion policy that must be visible before
  # Home Manager runs compinit.
  earlyInit = readFragments [
    ./lib/init-terminal-iterm.zsh
    ./lib/init-completion-styles.zsh
  ];

  # Interactive init is for widgets and key bindings that Home Manager does not
  # model directly.
  interactiveInit = readFragments [
    ./lib/init-zle-keymap.zsh
  ];

in
{
  # This repo intentionally leaves conventional top-level ~/.zshrc and friends
  # mutable for Nix-oblivious tools. The unmanaged bridge copies Home Manager's
  # generated zsh content into numbered hooks under ~/.config/zsh/rc.
  programs.unmanaged.zsh.enable = true;

  programs.zsh = {
    # Home Manager still owns the zsh content generation even though the final
    # top-level startup files are managed by `programs.unmanaged.zsh`.
    enable = true;
    dotDir = zshConfigDir;

    # Start in vi insert mode. Custom terminal key bindings live in
    # `lib/init-zle-keymap.zsh`.
    defaultKeymap = "viins";

    # Use a custom compinit wrapper so completion dump files live in
    # ~/.cache/zsh and can use the faster cached path when fresh.
    enableCompletion = true;
    completionInit = builtins.readFile ./lib/completion-init.zsh;

    # Large history because shell history is a working-memory surface. The file
    # itself stays in ~/.cache/zsh rather than ~/.config/zsh.
    history = {
      append = true;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      path = "${zshCacheDir}/history";
      save = 10000000;
      share = true;
      size = 10000000;
    };

    # Let Up/Down search through matching history prefixes instead of always
    # moving linearly through history.
    historySubstringSearch = {
      enable = true;
      searchUpKey = "^[[A";
      searchDownKey = "^[[B";
    };

    # Keep syntax highlighting declarative. The alias style makes aliases stand
    # out while typing commands.
    syntaxHighlighting = {
      enable = true;
      styles.alias = "fg=magenta,bold";
    };

    shellAliases = aliases;
    setOptions = shellOptions;
    plugins = plugins;
    siteFunctions = localSiteFunctions;

    # Used by the custom compinit wrapper and completion zstyles.
    sessionVariables.ZSH_CACHE_DIR = "$HOME/.cache/zsh";

    # Home Manager also contributes ordered zshrc fragments: plugin paths at
    # 560, compinit at 570, plugin sources at 900, aliases at 1100, syntax
    # highlighting at 1200, and history finalization at 1250.
    initContent = mkMerge [
      (mkOrder initOrder.beforeCompletion earlyInit)
      (mkOrder initOrder.beforePluginSources interactiveInit)
      (mkOrder initOrder.prompt promptInit)
    ];
  };
}
