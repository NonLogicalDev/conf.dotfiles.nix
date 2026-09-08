# Global Just commands

Import this Home Manager module and define one entry per command:

```nix
{
  imports = [ ./modules/home/pkgGlobalJust ];

  programs.globalJust = {
    sjust.justfiles = [
      { path = "~/system-tasks/Justfile"; }
      { path = "~/system-tasks/local.just"; optional = true; }
    ];
    pjust.justfiles = [
      { path = "~/personal-tasks/Justfile"; }
    ];
  };
}
```

Each command gets an intermediate file at `$XDG_CONFIG_HOME/global-just/<name>.just` (normally `~/.config/global-just/`). Nix generates the imports and Home Manager links the file during activation. The command and its native Bash, Fish, and Zsh completions read imported files at runtime. Enable the desired shells through Home Manager; this module does not enable shells itself.

Missing optional imports are skipped. Creating, editing, or removing an optional file takes effect without rebuilding. Changing the configured import list requires rebuilding and activation. Required missing files and duplicate recipe names remain errors. A bare command lists recipes, including when no imports are present.

The wrapper sets `JUST_JUSTFILE` only for its own process and forwards arguments unchanged. Standard Just flags remain available, including an explicit `--justfile` override. Completion uses the same wrapper and Just version, so commands do not share recipe lists.

Imported files remain outside the Nix store. Use `source_directory()` to locate helpers beside an imported file: `justfile_directory()` refers to the generated entry file. Recipes normally run from the entry file's directory, so use explicit paths or Just's working-directory controls when a recipe depends on its current directory. Imported default recipes are not selected automatically; the generated listing recipe is the default.

## Tests

From the repository root:

```sh
python3 modules/home/pkgGlobalJust/tests/test_runtime.py
nix flake check --no-build --no-write-lock-file path:.
```

The runtime test builds two commands and checks execution, import isolation, missing optional and required files, and actual recipe completion in Bash, Fish, and Zsh. It uses a temporary directory and does not activate a Home Manager profile.
