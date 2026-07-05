rec {
  # Jujutsu aliases are rendered as argv arrays in TOML. Shell-backed aliases
  # therefore need the full `jj util exec -- bash ... -c <script> <arg0>` shape
  # every time. Keep that boilerplate here so alias files can focus on the
  # workflow script they are actually defining.
  jjAliasBash =
    {
      script,
      shellArg0 ? "",
      shellOptions ? "-euo",
    }:
    [
      "util"
      "exec"
      "--"
      "bash"
      shellOptions
      "pipefail"
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
      shellOptions ? "-euo",
    }:
    jjAliasBash {
      script = builtins.readFile file;
      inherit shellArg0 shellOptions;
    };
}
