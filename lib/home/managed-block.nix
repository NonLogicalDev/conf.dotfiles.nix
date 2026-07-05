{ lib }:

let
  markerPrefix = "dotfiles-nix managed";

  stripTrailingNewline = text: lib.removeSuffix "\n" text;
in
{
  mkActivation =
    {
      name,
      target,
      block,
      after ? [ "writeBoundary" ],
    }:
    let
      begin = "# BEGIN ${markerPrefix} ${name}";
      end = "# END ${markerPrefix} ${name}";
      fullBlock = stripTrailingNewline ''
        ${begin}
        ${stripTrailingNewline block}
        ${end}
      '';
    in
    lib.hm.dag.entryAfter after ''
      target_rel=${lib.escapeShellArg target}
      target="$HOME/$target_rel"
      begin=${lib.escapeShellArg begin}
      end=${lib.escapeShellArg end}
      block=${lib.escapeShellArg fullBlock}

      mkdir -p "$(dirname "$target")"
      if [ ! -e "$target" ]; then
        : > "$target"
      fi

      begin_count="$(grep -Fxc "$begin" "$target" || true)"
      end_count="$(grep -Fxc "$end" "$target" || true)"

      if [ "$begin_count" -ne "$end_count" ]; then
        echo "Refusing to update $target because the managed markers for ${name} are unbalanced." >&2
        exit 1
      fi

      if [ "$begin_count" -gt 1 ]; then
        echo "Refusing to update $target because multiple managed blocks for ${name} are present." >&2
        exit 1
      fi

      tmp="$(mktemp "$target.XXXXXX")"

      if [ "$begin_count" -eq 1 ]; then
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
