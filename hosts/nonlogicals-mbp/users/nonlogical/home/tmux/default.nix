{
  # Tmux is a good Home Manager fit for the stable behavior: package install,
  # prefix, indexing, mouse mode, history, terminal, and vi copy mode. The
  # remaining config is tmux-native syntax because Home Manager does not model
  # detailed status bar and key table bindings.
  programs.tmux = {
    enable = true;

    # Old Dotter config used C-a as the prefix and passed C-a through to nested
    # programs. Home Manager emits the pass-through binding for `prefix`.
    prefix = "C-a";

    # Keep windows and panes one-indexed for quick keyboard selection.
    baseIndex = 1;

    # Match the old copy-mode and command editing expectations.
    keyMode = "vi";

    # Preserve the old responsiveness and scrollback size.
    escapeTime = 10;
    historyLimit = 20000;

    # Keep the terminal/color behavior close to the existing profile.
    terminal = "screen-256color";
    mouse = true;

    extraConfig = builtins.readFile ./extra.conf;
  };

  # The live Dotter setup owns top-level `~/.tmux.conf`. Home Manager writes the
  # real config to `~/.config/tmux/tmux.conf`; this small bridge keeps tmux
  # startup compatible and gives activation permission to replace the Dotter
  # symlink.
  home.file.".tmux.conf" = {
    text = ''
      source-file ~/.config/tmux/tmux.conf
    '';
    force = true;
  };
}
