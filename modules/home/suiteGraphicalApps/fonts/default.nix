{
  config,
  lib,
  pkgs,
  ...
}:

let
  fontRoot = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono";
  fontDir = "${config.home.homeDirectory}/Library/Fonts";
  fontFiles = [
    "JetBrainsMonoNerdFontMono-Regular.ttf"
    "JetBrainsMonoNerdFontMono-Bold.ttf"
    "JetBrainsMonoNerdFontMono-Italic.ttf"
    "JetBrainsMonoNerdFontMono-BoldItalic.ttf"
  ];
  fontTargets = map (fontFile: "${fontDir}/${fontFile}") fontFiles;
  quotedFontTargets = lib.concatMapStringsSep " " lib.escapeShellArg fontTargets;
  installCommands = lib.concatMapStringsSep "\n" (
    fontFile:
    "/usr/bin/install -m 0644 "
    + lib.escapeShellArg "${fontRoot}/${fontFile}"
    + " "
    + lib.escapeShellArg "${fontDir}/${fontFile}"
  ) fontFiles;
in
{
  # CoreText ignores Home Manager symlinks in Library/Fonts.
  home.activation.installJetBrainsMonoNerdFont = lib.mkIf pkgs.stdenv.isDarwin (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      font_dir=${lib.escapeShellArg fontDir}
      marker="$font_dir/.home-manager-jetbrains-mono-nerd-font"

      mkdir -p "$font_dir"
      if [ -f "$marker" ]; then
        rm -f ${quotedFontTargets}
      else
        for target in ${quotedFontTargets}; do
          if [ -L "$target" ]; then
            rm -f "$target"
          elif [ -e "$target" ]; then
            echo "refusing to replace unmanaged font: $target" >&2
            exit 1
          fi
        done
      fi

      ${installCommands}
      printf '%s\n' ${lib.escapeShellArg fontRoot} > "$marker"
    ''
  );
}
