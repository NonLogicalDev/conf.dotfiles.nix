{
  config,
  lib,
  ...
}:

let
  cfg = config.dotfiles.suites.developerBase;
in

{
  imports = [
    ./atuin
    ./git
    ./jujutsu
    ./neovim
    ./shell
    ./tmux
  ];

  options.dotfiles.suites.developerBase = {
    git = {
      userName = lib.mkOption {
        type = lib.types.str;
        description = ''
          Human name written to Git's `user.name` for this Home Manager user.
        '';
      };

      userEmail = lib.mkOption {
        type = lib.types.str;
        description = ''
          Email address written to Git's `user.email` for this Home Manager user.
        '';
      };
    };

    jujutsu = {
      userName = lib.mkOption {
        type = lib.types.str;
        default = cfg.git.userName;
        defaultText = lib.literalExpression "config.dotfiles.suites.developerBase.git.userName";
        description = ''
          Human name written to Jujutsu's `user.name`. Defaults to the Git
          identity name, but can differ when jj should use a separate identity.
        '';
      };

      userEmail = lib.mkOption {
        type = lib.types.str;
        default = cfg.git.userEmail;
        defaultText = lib.literalExpression "config.dotfiles.suites.developerBase.git.userEmail";
        description = ''
          Email address written to Jujutsu's `user.email`. Defaults to the Git
          identity email, but can differ when jj should use a separate identity.
        '';
      };

      immutableBookmarkGlobs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "alice/*" ];
        description = ''
          Personal bookmark namespaces that Jujutsu should treat as immutable in
          addition to jj's built-in immutable heads.
        '';
      };
    };
  };
}
