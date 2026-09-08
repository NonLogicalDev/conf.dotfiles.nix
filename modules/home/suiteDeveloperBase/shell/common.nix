{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  sessionVariables = import ./cfg-session-variables.nix { inherit pkgs; };
in
{
  programs = {
    atuin = {
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableBashIntegration = false;
    };

    bat.enable = true;

    direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    eza = {
      enable = true;
      enableZshIntegration = false;
      extraOptions = [ "--group-directories-first" ];
    };

    fzf =
      {
        enable = true;
        enableZshIntegration = true;
        defaultOptions = [
          "--height 40%"
          "--reverse"
          "--border"
        ];
      }
      // lib.optionalAttrs (lib.hasAttrByPath [ "programs" "fzf" "historyWidget" "command" ] options) {
        # Atuin owns history search when this Home Manager release can disable it.
        historyWidget.command = "";
      };

    less = {
      enable = true;
      options = [
        "-g"
        "-i"
        "-M"
        "-R"
        "-S"
        "-w"
        "-z-4"
      ];
    };

    mise = {
      enable = true;
      enableZshIntegration = true;
    };

    vivid = {
      enable = true;
      enableZshIntegration = true;
      colorMode = "24-bit";
      activeTheme = "one-dark";
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/bin"
    "${config.home.homeDirectory}/.local/bin"
    "/usr/local/bin"
    "/usr/local/sbin"
  ];

  home.sessionVariables = sessionVariables;
}
