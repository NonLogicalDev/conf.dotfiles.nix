{ lib }:

let
  # Every block managed by this helper gets a stable marker pair:
  #
  #   # BEGIN dotfiles-nix managed <name>
  #   ...
  #   # END dotfiles-nix managed <name>
  #
  # Tool modules pass `<name>` so one top-level file can hold distinct
  # managed blocks without confusing them.
  markerPrefix = "dotfiles-nix managed";

  # Home Manager activation snippets are shell scripts generated from Nix
  # strings. Trimming here prevents accidental extra blank lines from
  # becoming part of the marker block itself.
  stripTrailingNewline = text: lib.removeSuffix "\n" text;
in
{
  # Build a Home Manager activation DAG entry that inserts or replaces one
  # marked block inside a normal mutable file under `$HOME`.
  #
  # This intentionally does not know about zsh, bash, git, or any other
  # tool. Callers provide the exact block body they want inserted.
  mkActivation =
    {
      # Human-readable identifier used in the marker lines and error text.
      name,

      # Path relative to `$HOME`, for example `.zshrc` or `.gitconfig`.
      target,

      # Text to place between the marker lines. The helper owns only this
      # marked block; all other file content is preserved.
      block,

      # Home Manager activation ordering. `writeBoundary` is the standard
      # point after Home Manager has finished preparing its generation and
      # before later activation actions may depend on files being present.
      after ? [ "writeBoundary" ],

      # Comment syntax for the target file. Most shell-like files use `#`.
      # Callers can set `{ prefix = ";"; }` for INI-like files or add a
      # suffix when a file format needs closing comment text.
      comment ? { },
    }:
    let
      # `or` is Nix's "attribute with default" operator. If the caller did
      # not provide `comment.prefix`, use `#`.
      commentPrefix = comment.prefix or "#";
      commentSuffix = comment.suffix or "";

      # Marker lines are built from non-empty pieces so callers can omit a
      # suffix without leaving trailing whitespace.
      mkMarker =
        label:
        lib.concatStringsSep " " (
          lib.filter (part: part != "") [
            commentPrefix
            label
            markerPrefix
            name
            commentSuffix
          ]
        );
      begin = mkMarker "BEGIN";
      end = mkMarker "END";

      # The full managed block includes markers plus caller-provided body.
      # It is shell-escaped before insertion into the activation script.
      fullBlock = stripTrailingNewline ''
        ${begin}
        ${stripTrailingNewline block}
        ${end}
      '';
    in
    # `lib.hm.dag.entryAfter` returns an ordered Home Manager activation
    # entry. The string below is not executed at evaluation time; it becomes
    # part of the generated activation script.
    lib.hm.dag.entryAfter after ''
      # Keep the target relative in Nix, then resolve against the runtime
      # `$HOME`. This avoids baking a specific user home path into the Nix
      # expression.
      target_rel=${lib.escapeShellArg target}
      target="$HOME/$target_rel"

      # Escape Nix strings before injecting them into shell. These variables
      # are plain shell strings by the time activation runs.
      begin=${lib.escapeShellArg begin}
      end=${lib.escapeShellArg end}
      block=${lib.escapeShellArg fullBlock}

      # The unmanaged top-level file may not exist yet. Create the parent
      # directory and an empty file so later logic can treat creation and
      # replacement uniformly.
      mkdir -p "$(dirname "$target")"
      if [ ! -e "$target" ]; then
        : > "$target"
      fi

      # Exact-line marker counts are safer than substring search. A half
      # present marker pair usually means a user edit or failed prior run,
      # so activation should stop instead of guessing how to repair it.
      begin_count="$(grep -Fxc "$begin" "$target" || true)"
      end_count="$(grep -Fxc "$end" "$target" || true)"

      if [ "$begin_count" -ne "$end_count" ]; then
        echo "Refusing to update $target because the managed markers for ${name} are unbalanced." >&2
        exit 1
      fi

      # Multiple complete blocks with the same name are ambiguous. Refuse to
      # edit rather than deleting user content around the wrong block.
      if [ "$begin_count" -gt 1 ]; then
        echo "Refusing to update $target because multiple managed blocks for ${name} are present." >&2
        exit 1
      fi

      # Write to a temporary file first, then copy over the target only when
      # content changes. This keeps activation idempotent and avoids touching
      # mtimes unnecessarily.
      tmp="$(mktemp "$target.XXXXXX")"

      if [ "$begin_count" -eq 1 ]; then
        # Replace the existing managed block. Lines outside the marker pair
        # pass through unchanged.
        awk -v begin="$begin" -v end="$end" -v block="$block" '
          $0 == begin {
            print block
            skipping = 1
            next
          }
          $0 == end {
            skipping = 0
            next
          }
          !skipping {
            print
          }
        ' "$target" > "$tmp"
      else
        # No existing managed block: append one to the end of the file,
        # separating it from existing content with a blank line.
        cp "$target" "$tmp"
        if [ -s "$tmp" ]; then
          printf '\n' >> "$tmp"
        fi
        printf '%s\n' "$block" >> "$tmp"
      fi

      if ! cmp -s "$target" "$tmp"; then
        cp "$tmp" "$target"
      fi

      rm -f "$tmp"
    '';
}
