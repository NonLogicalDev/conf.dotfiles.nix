{ lib, pkgs }:

let
  bashExe = lib.getExe pkgs.bash;
in
rec {
  # Jujutsu aliases are rendered as argv arrays in TOML. Shell-backed aliases
  # therefore need the full `jj util exec -- bash -c <script> <arg0>` shape
  # every time. Keep that boilerplate here so alias files can focus on the
  # workflow script they are actually defining. Shell modes such as
  # `set -euo pipefail` belong in the script body because `pipefail` is not a
  # cleanly separable argv concern.
  jjAliasBash =
    {
      script,
      shellArg0 ? "",
    }:
    [
      "util"
      "exec"
      "--"
      bashExe
      "-c"
      script
      shellArg0
    ];

  # Most shell aliases are long enough that keeping their script bodies in Nix
  # strings makes the config hard to skim. This helper preserves the same argv
  # contract while letting the Bash live in editor-friendly files under `lib/`.
  jjAliasBashFile =
    {
      file,
      shellArg0 ? "",
    }:
    jjAliasBash {
      script = builtins.readFile file;
      inherit shellArg0;
    };
}
