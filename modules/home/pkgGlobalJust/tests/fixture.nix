let
 f = builtins.getFlake ("path:" + toString ../../../..);
 pkgs = f.inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
 testHome = builtins.getEnv "GLOBAL_JUST_TEST_HOME";
 m = import ../default.nix {
 inherit pkgs; lib = pkgs.lib;
 config = {
 xdg.configHome = "${testHome}/.config";
 programs.globalJust = {
   ajust.justfiles = [{ path = "${testHome}/agent.just"; optional = false; }];
   sjust.justfiles = [{ path = "${testHome}/system.just"; optional = false; } {path = "${testHome}/optional.just"; optional = true;}];
 };
 };
 };
 c = m.config.content;
in pkgs.runCommand "global-just-test-fixture" {} ''
 mkdir -p "$out/bin" "$out/entries"
 ${pkgs.lib.concatMapStringsSep "\n" (p: "for x in ${p}/bin/*; do ln -s \"$x\" \"$out/bin/$(basename \"$x\")\"; done") c.home.packages}
 ln -s ${pkgs.bashInteractive}/bin/bash "$out/bin/bash"
 ln -s ${pkgs.fish}/bin/fish "$out/bin/fish"
 ln -s ${pkgs.zsh}/bin/zsh "$out/bin/zsh"
 cp ${pkgs.writeText "bash-init" c.programs.bash.initExtra} "$out/bash"
 cp ${pkgs.writeText "fish-init" c.programs.fish.interactiveShellInit} "$out/fish"
 cp ${pkgs.writeText "zsh-init" c.programs.zsh.initContent.content} "$out/zsh"
 ${pkgs.lib.concatMapStringsSep "\n" (name: "cp ${pkgs.writeText name c.xdg.configFile.${"global-just/"+name+".just"}.text} \"$out/entries/${name}.just\"") ["ajust" "sjust"]}
''
