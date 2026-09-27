{ pkgs, pname, ... }:

let
  inherit (pkgs) lib;
  runtimePath = lib.makeBinPath (
    (with pkgs; [
      bash
      zsh
      coreutils
      findutils
      gnugrep
      gnused
      gawk
      git
      stgit
      jq
      fzf
      gum
      perl
      file
      tig
      unixtools.column
    ])
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.procps ]
  );
in
pkgs.stdenvNoCC.mkDerivation {
  inherit pname;
  version = "1.0";
  src = ./src;

  nativeBuildInputs = with pkgs; [
    makeWrapper
    bash
    zsh
    python3
    ruby
  ];
  dontBuild = true;

  # Keep scripts as files: their help commands read comments from their own $0.
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/libexec"
    cp ./* "$out/libexec/"
    chmod +x "$out/libexec/"*
    patchShebangs "$out/libexec"
    ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
      substituteInPlace "$out/libexec/gman" \
        --replace-fail 'man #{args}' '/usr/bin/man #{args}' \
        --replace-fail 'man -t #{args}' '/usr/bin/man -t #{args}' \
        --replace-fail '| open -f' '| /usr/bin/open -f'
    ''}
    for script in "$out/libexec/"*; do
      makeWrapper "$script" "$out/bin/$(basename "$script")" \
        --prefix PATH : "$out/bin:${runtimePath}"
    done
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    for script in "$out/libexec/"*; do
      case "$(head -n 1 "$script")" in
        *python3*) python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read())' "$script" ;;
        *ruby*) ruby -c "$script" ;;
        *zsh*) zsh -n "$script" ;;
        *bash*) bash -n "$script" ;;
        *) echo "Unrecognized interpreter: $script" >&2; exit 1 ;;
      esac
    done
    # These entrypoints parse help before touching repository or Steam state.
    "$out/bin/steam-wine" --help >/dev/null
    "$out/bin/git-commit-stat" --help >/dev/null
    "$out/bin/git-ls-index" --help >/dev/null
    "$out/bin/stg-fixup" --help | grep -q 'DEPENDENCIES'
    for command in git-utils stg-utils; do
      status=0
      "$out/bin/$command" --help >help.txt || status=$?
      test "$status" -eq 125
      test -s help.txt
    done
    bash ${./test-push-confirmation.sh} "$out/libexec/stg-utils"
    runHook postInstallCheck
  '';

  meta = {
    description = "Personal Git, StGit, filesystem, manual, and Steam helper commands";
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
  };
}
