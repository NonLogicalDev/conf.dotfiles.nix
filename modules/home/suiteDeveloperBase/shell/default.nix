{
  config,
  inputs,
  pkgs,
  ...
}:

let
  # Load this repo's packages against the same nixpkgs instance that Home
  # Manager is using for this profile. That avoids mixing two package sets when
  # installing small local utilities such as `opn`.
  selfPackages = inputs.self.mkPackagesFor pkgs;

  # Keep broad login/session environment here rather than in zsh-specific
  # startup files. These variables should apply to any shell Home Manager owns.
  sessionVariables = import ./cfg-session-variables.nix { inherit pkgs; };
in
{
  # `shZsh` contains the zsh implementation details. This parent module is
  # for shell-adjacent tools and cross-shell policy.
  imports = [
    ./shBash
    ./shFish
    ./shZsh
  ];

  programs = {
    # Shell integration toggles live with shell policy, not with the app's core
    # client settings. Zsh is the primary shell; fish is kept as a lightweight
    # compatibility shell because Atuin has native fish integration.
    atuin = {
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableBashIntegration = false;
    };

    # Better pager-friendly file preview. The zsh alias file maps `cat` to this
    # package for interactive reads, but the program itself is shell-neutral.
    bat.enable = true;

    # Let direnv manage per-directory environments, with Home Manager emitting
    # the zsh hook so we do not carry handwritten `eval "$(direnv hook zsh)"`.
    direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    # Directory listings are intentionally eza-backed. We disable Home Manager's
    # generated zsh aliases because `shZsh/cfg-aliases.nix` owns the exact
    # short aliases and comments explaining them.
    eza = {
      enable = true;
      enableZshIntegration = false;
      extraOptions = [ "--group-directories-first" ];
    };

    # Fuzzy finder plus Home Manager's zsh integration. This covers key bindings
    # and completion integration without keeping old plugin-manager snippets.
    fzf = {
      enable = true;
      enableZshIntegration = true;

      # Atuin is the history UI in this profile, so fzf should not also bind
      # Ctrl-R. Keeping fzf enabled still provides the command-line fuzzy finder
      # and completion integration used by other tools.
      historyWidget.command = "";
    };

    # Pager defaults. These options keep output searchable, color-capable, and
    # horizontally scrollable without requiring zsh-specific LESS exports.
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

    # Runtime/tool-version manager. Home Manager owns the zsh activation hook;
    # ad-hoc PATH mutation for toolchains is intentionally deferred.
    mise = {
      enable = true;
      enableZshIntegration = true;
    };

    # Generate LS_COLORS declaratively instead of carrying a pasted color table
    # in zsh startup.
    vivid = {
      enable = true;
      enableZshIntegration = true;
      colorMode = "24-bit";
      activeTheme = "one-dark";
    };

    # `cd` acceleration and frecency navigation. Home Manager emits the zsh hook.
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  # Small local commands that should exist as real executables, not aliases or
  # zsh functions. `opn` is packaged under `packages/opn`.
  home.packages = [
    pkgs.dnsutils
    selfPackages.opn
  ];

  # General user bin directories. App-specific paths such as Cargo, Krew, or
  # LM Studio should be added by explicit integration slices when they are
  # intentionally brought under Nix management.
  home.sessionPath = [
    "${config.home.homeDirectory}/bin"
    "${config.home.homeDirectory}/.local/bin"
    "/usr/local/bin"
    "/usr/local/sbin"
  ];

  # Cross-shell environment defaults for this host-user profile.
  home.sessionVariables = sessionVariables;
}
