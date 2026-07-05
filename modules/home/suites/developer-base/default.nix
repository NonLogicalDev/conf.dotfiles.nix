{
  lib,
  ...
}:

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
    scmIdentity = {
      name = lib.mkOption {
        type = lib.types.str;
        description = ''
          Human name written to source-control tools such as Git and Jujutsu.
        '';
      };

      email = lib.mkOption {
        type = lib.types.str;
        description = ''
          Email address written to source-control tools such as Git and Jujutsu.
        '';
      };

      username = lib.mkOption {
        type = lib.types.str;
        description = ''
          Short source-control username used for personal namespaces, such as
          Jujutsu bookmark globs derived as `<username>/*`.
        '';
      };
    };
  };
}
