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

      # Where to put a new block when the target file does not already have
      # one. Existing blocks are always replaced in place.
      #
      # The default `append` mode keeps current behavior: new managed blocks
      # are added at the end of the file.
      #
      # `after-preamble` inserts near the top, but only after leading lines
      # that match `preambleLineRegexes`. This lets a caller preserve things
      # that must stay first, such as shebangs, file headers, or doc comments.
      placement ? { },
    }:
    let
      placementMode = placement.mode or "append";
      validPlacementModes = [
        "append"
        "after-preamble"
      ];
      checkedPlacementMode =
        if builtins.elem placementMode validPlacementModes then
          placementMode
        else
          throw "managed-block placement.mode must be one of ${lib.concatStringsSep ", " validPlacementModes}";
      preambleLineRegexes = placement.preambleLineRegexes or [ ];

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
      placement_mode=${lib.escapeShellArg checkedPlacementMode}
      preamble_line_regexes=${lib.escapeShellArg (lib.concatStringsSep "\n" preambleLineRegexes)}

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

      # Write to temporary files first, then copy over the target only when
      # content changes. This keeps activation idempotent and avoids touching
      # mtimes unnecessarily.
      tmp="$(mktemp "$target.XXXXXX")"
      block_file="$(mktemp "$target.block.XXXXXX")"
      preamble_regex_file="$(mktemp "$target.preamble.XXXXXX")"

      # Do not pass multiline text to awk through `-v`; BSD awk rejects
      # embedded newlines in variable assignments. Store multiline inputs in
      # temporary files and let awk read them back line-by-line instead.
      printf '%s\n' "$block" > "$block_file"
      printf '%s\n' "$preamble_line_regexes" > "$preamble_regex_file"

      if [ "$begin_count" -eq 1 ]; then
        # Replace the existing managed block. Lines outside the marker pair
        # pass through unchanged.
        awk -v begin="$begin" -v end="$end" -v block_file="$block_file" '
          function print_block(line) {
            while ((getline line < block_file) > 0) {
              print line
            }
            close(block_file)
          }

          $0 == begin {
            print_block()
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
        ' "$target" > "$tmp" || {
          rm -f "$tmp" "$block_file" "$preamble_regex_file"
          exit 1
        }
      else
        if [ "$placement_mode" = "append" ]; then
          # No existing managed block: append one to the end of the file,
          # separating it from existing content with a blank line.
          cp "$target" "$tmp"
          if [ -s "$tmp" ]; then
            printf '\n' >> "$tmp"
          fi
          printf '%s\n' "$block" >> "$tmp"
        elif [ "$placement_mode" = "after-preamble" ]; then
          # Insert before the first non-preamble line. The preamble is
          # caller-defined because different file formats have different
          # header rules. For a shell file, useful regexes might be `^#!`
          # for a shebang and `^#($|[[:space:]])` for leading comments.
          awk -v block_file="$block_file" -v preamble_regex_file="$preamble_regex_file" '
            BEGIN {
              while ((getline regex < preamble_regex_file) > 0) {
                regexes[++regex_count] = regex
              }
              close(preamble_regex_file)
            }

            function print_block(line) {
              while ((getline line < block_file) > 0) {
                print line
              }
              close(block_file)
            }

            function is_preamble(line, i) {
              for (i = 1; i <= regex_count; i++) {
                if (regexes[i] != "" && line ~ regexes[i]) {
                  return 1
                }
              }
              return 0
            }

            !inserted && !is_preamble($0) {
              print_block()
              inserted = 1
            }

            {
              print
            }

            END {
              if (!inserted) {
                if (NR > 0) {
                  print ""
                }
                print_block()
              }
            }
          ' "$target" > "$tmp" || {
            rm -f "$tmp" "$block_file" "$preamble_regex_file"
            exit 1
          }
        else
          # Nix evaluation should prevent this path, but keep an activation
          # guard so a broken generated script fails loudly.
          echo "Unsupported managed-block placement mode: $placement_mode" >&2
          rm -f "$tmp" "$block_file" "$preamble_regex_file"
          exit 1
        fi
      fi

      if ! cmp -s "$target" "$tmp"; then
        cp "$tmp" "$target"
      fi

      rm -f "$tmp" "$block_file" "$preamble_regex_file"
    '';
}
