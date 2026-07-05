{
  config,
  lib,
  pkgs,
  ...
}:

let
  aliases = import ./cfg-aliases.nix;
  plugins = import ./cfg-plugins.nix { inherit pkgs; };
  shellOptions = import ./cfg-options.nix;
  sessionVariables = import ./cfg-session-variables.nix;

  sourceZshLib = name: ''
    . "${./lib + "/${name}.zsh"}"
  '';
in
{
  programs.unmanaged.zsh.enable = true;

  programs.zsh = {
    enable = true;
    dotDir = "${config.home.homeDirectory}/.config/zsh";
    defaultKeymap = "viins";

    enableCompletion = true;
    completionInit = ''
      autoload -Uz compinit

      zsh_cache_dir="''${ZSH_CACHE_DIR:-$HOME/.cache/zsh}"
      mkdir -p "$zsh_cache_dir"

      zsh_comp_files=("$zsh_cache_dir"/compdump(Nm-20))
      if (( $#zsh_comp_files )); then
        compinit -i -C -d "$zsh_cache_dir/compdump"
      else
        compinit -i -d "$zsh_cache_dir/compdump"
      fi
      unset zsh_cache_dir zsh_comp_files
    '';

    history = {
      append = true;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      path = "${config.home.homeDirectory}/.cache/zsh/history";
      save = 10000000;
      share = true;
      size = 10000000;
    };

    historySubstringSearch = {
      enable = true;
      searchUpKey = "^[[A";
      searchDownKey = "^[[B";
    };

    syntaxHighlighting = {
      enable = true;
      styles.alias = "fg=magenta,bold";
    };

    shellAliases = aliases;
    setOptions = shellOptions;
    sessionVariables = sessionVariables;
    plugins = plugins;

    envExtra = ''
      export ZSH_CACHE_DIR="''${ZSH_CACHE_DIR:-$HOME/.cache/zsh}"

      case "$(uname 2>/dev/null)" in
        Darwin) export PLATFORM=MAC ;;
        Linux) export PLATFORM=LINUX ;;
        MINGW32_NT*) export PLATFORM=WIN ;;
        *) export PLATFORM=UNKNOWN ;;
      esac

      if [[ -n "''${ZSH_PROFILE-}" ]]; then
        zmodload zsh/zprof
      fi
    '';

    profileExtra = ''
      if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv zsh)"
      fi

      export TERM="''${TERM:-dumb}"
      export PAGER="''${PAGER:-${lib.getExe pkgs.less}}"
      path=(
        "$HOME/bin"
        "$HOME/.local/bin"
        /usr/local/{bin,sbin}
        $path
      )
    '';

    loginExtra = ''
      if (( $+commands[fortune] )); then
        login_fortune=(fortune)
        if (( $+commands[lolcat] )); then
          login_decorator=(lolcat)
        else
          login_decorator=(cat)
        fi

        if [[ -t 0 || -t 1 ]]; then
          "''${login_fortune[@]}" | "''${login_decorator[@]}"
        fi
        unset login_fortune login_decorator
      fi
    '';

    logoutExtra = ''
      cat <<-'EOF'

      Thank you. Come again!
        -- Dr. Apu Nahasapeemapetilon
      EOF
    '';

    initContent = lib.mkMerge [
      (lib.mkOrder 540 ''
        ${sourceZshLib "path"}
        ${sourceZshLib "terminal"}
        ${sourceZshLib "completion-styles"}
      '')
      (lib.mkOrder 880 ''
        ${sourceZshLib "functions"}
        ${sourceZshLib "keymap"}
        ${sourceZshLib "iterm-tabs"}
        ${sourceZshLib "prompt-microprompt"}
      '')
      (lib.mkOrder 1300 ''
        ${sourceZshLib "integrations"}
      '')
    ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.bat.enable = true;

  programs.eza = {
    enable = true;
    enableZshIntegration = false;
    extraOptions = [ "--group-directories-first" ];
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.lmstudio/bin"
    "${config.home.homeDirectory}/.krew/bin"
  ];

  home.packages = [
    pkgs.zsh-completions
  ];
}
