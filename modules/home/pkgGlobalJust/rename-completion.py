"""Retarget Just's native completion without changing flags such as --justfile."""
import re
import sys

name = sys.argv[1]
if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_-]*", name) or name == "just":
    raise SystemExit("invalid global Just command name")
sys.stdout.write(re.sub(r"(?<![A-Za-z0-9])just(?![A-Za-z0-9])", lambda _: name, sys.stdin.read()))
