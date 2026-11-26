"""Build and exercise two commands and native completion in all three shells."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def run(args, env, **kwargs):
    return subprocess.check_output(args, env=env, text=True, **kwargs)


with tempfile.TemporaryDirectory(prefix="global-just-") as directory:
    root = Path(directory)
    env = {**os.environ, "GLOBAL_JUST_TEST_HOME": str(root)}
    fixture = root / "fixture"
    subprocess.run([
        "nix", "build", "--impure", "--file", str(Path(__file__).with_name("fixture.nix")),
        "--out-link", str(fixture),
    ], env=env, check=True)
    env["PATH"] = str(fixture / "bin") + os.pathsep + env["PATH"]
    entries = root / ".config/global-just"
    entries.mkdir(parents=True)
    for name in ["ajust", "sjust"]:
        shutil.copyfile(fixture / f"entries/{name}.just", entries / f"{name}.just")
    (root / "agent.just").write_text('agent-task:\n    @echo agent\n')
    (root / "system.just").write_text('system-task:\n    @echo system\n')
    assert run(["ajust", "agent-task"], env).strip() == "agent"
    assert run(["sjust", "system-task"], env).strip() == "system"
    assert "agent-task" in run(["ajust"], env)
    assert "system-task" not in run(["ajust", "--list"], env)
    (root / "optional.just").write_text('optional-task:\n    @echo optional\n')
    assert run(["sjust", "optional-task"], env).strip() == "optional"

    def complete(shell, command, prefix):
        if shell == "bash":
            code = f'''source "{fixture}/bash"
COMP_WORDS=({command} {prefix}); COMP_CWORD=1; COMP_TYPE=9
COMP_LINE="{command} {prefix}"; COMP_POINT=${{#COMP_LINE}}
fn=$(complete -p {command}); fn=${{fn#* -F }}; fn=${{fn%% *}}
"$fn" {command} {prefix} ""
printf '%s\\n' "${{COMPREPLY[@]}}"
'''
        elif shell == "fish":
            code = f'source "{fixture}/fish"; complete -C "{command} {prefix}"'
        else:
            code = f'''autoload -Uz compinit; compinit -D -d /dev/null
source "{fixture}/zsh"
_describe() {{ local array_name=$3; print -rl -- "${{(@P)array_name}}"; }}
words=({command} {prefix}); CURRENT=2
"${{_comps[{command}]}}"
'''
        return run([str(fixture / "bin" / shell), "-c", code], env)

    for shell in ["bash", "fish", "zsh"]:
        assert "agent-task" in complete(shell, "ajust", "agent-"), shell
        assert "system-task" in complete(shell, "sjust", "system-"), shell
        assert "optional-task" in complete(shell, "sjust", "optional-"), shell
        assert "system-task" not in complete(shell, "ajust", "system-"), shell
    (root / "optional.just").unlink()
    assert "optional-task" not in run(["sjust", "--list"], env)
    (root / "agent.just").unlink()
    assert subprocess.run(["ajust", "--list"], env=env, capture_output=True).returncode != 0
print("Passed execution, isolation, optional imports, and Bash/Fish/Zsh completion.")
