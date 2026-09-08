{
  pkgs,
  supportsPluginFunctions,
  enableFzfTabNativeModule,
}:

[
  # Extra completion definitions. Home Manager's zsh plugin support adds this
  # package to fpath before compinit runs.
  ({
    name = "zsh-completions";
    src = pkgs.zsh-completions;
  } // (if supportsPluginFunctions then {
    functions = [ "share/zsh/site-functions" ];
  } else {
    completions = [ "share/zsh/site-functions" ];
  }))

  # Lightweight automatic quote/bracket pairing. This remains a zsh plugin
  # because Home Manager does not expose a higher-level option for it.
  {
    name = "zsh-autopair";
    src = pkgs.zsh-autopair;
    file = "share/zsh/zsh-autopair/autopair.zsh";
  }

  # Completion UI on top of fzf. This is distinct from `programs.fzf`; fzf gives
  # us the fuzzy finder and bindings, while fzf-tab replaces zsh's completion
  # selection UI.
  {
    name = "zsh-fzf-tab";
    src =
      if !enableFzfTabNativeModule then
        # Keep the upstream package substitutable. Rebuilding it just to
        # remove this incompatible module also recompiles all of Zsh.
        pkgs.runCommandLocal "zsh-fzf-tab-without-native-module-${pkgs.zsh-fzf-tab.version}" { } ''
          cp -a ${pkgs.zsh-fzf-tab} "$out"
          chmod -R u+w "$out"
          rm -f "$out/share/fzf-tab/modules/Src/aloxaf/fzftab.so"
        ''
      else
        pkgs.zsh-fzf-tab;
    file = "share/fzf-tab/fzf-tab.plugin.zsh";
  }
]
