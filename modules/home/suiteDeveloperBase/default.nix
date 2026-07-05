{
  lib,
  ...
}:

{
  # This suite is the reusable "feels like my development machine" layer. It
  # intentionally composes tools that are useful together: source control,
  # shell ergonomics, terminal multiplexer, command history, and editor setup.
  # Host/user profiles supply identity values and decide whether to import this
  # suite; the suite should not hardcode one machine or login name.
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
      # Git and Jujutsu share this identity surface so future profiles only
      # need to answer one question for normal source-control authorship. If a
      # profile ever needs per-tool divergence, add that explicitly rather than
      # smuggling literals into the tool modules.
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

      slug = lib.mkOption {
        type = lib.types.str;
        description = ''
          Short source-control identity slug used for personal namespaces, such
          as Jujutsu bookmark globs derived as `<slug>/*`.
        '';
      };
    };
  };
}
