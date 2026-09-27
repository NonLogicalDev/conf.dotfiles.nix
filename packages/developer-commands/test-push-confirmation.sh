#!/usr/bin/env bash
set -euo pipefail

readonly script="$1"
fixture="$(mktemp -d)"
readonly fixture
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/bin"

cat >"$fixture/bin/stg" <<'STG'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  series)
    if [[ "$2" == --count ]]; then
      echo 1
    else
      echo '- example-patch # Example patch'
    fi
    ;;
  push) printf '%s\n' "$*" >>"$PUSH_LOG" ;;
  *) echo "Unexpected stg command: $*" >&2; exit 1 ;;
esac
STG

cat >"$fixture/bin/gum" <<'GUM'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  choose) cat ;;
  confirm) exit "$CONFIRM_STATUS" ;;
  *) echo "Unexpected gum command: $*" >&2; exit 1 ;;
esac
GUM

chmod +x "$fixture/bin/"*
export PATH="$fixture/bin:$PATH"
export PUSH_LOG="$fixture/push.log"

# Nonzero statuses cover an explicit decline and cancellation of the prompt.
for status in 1 130; do
  : >"$PUSH_LOG"
  CONFIRM_STATUS="$status" "$script" push-interactive >"$fixture/output"
  grep -q 'Cancelled Apply' "$fixture/output"
  test ! -s "$PUSH_LOG"
done

: >"$PUSH_LOG"
CONFIRM_STATUS=0 "$script" push-interactive >"$fixture/output"
test "$(cat "$PUSH_LOG")" = 'push example-patch'
