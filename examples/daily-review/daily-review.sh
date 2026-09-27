#!/usr/bin/env bash
# daily-review.sh: a read-only snapshot of your Arena paper account as one JSON document.
#
# It runs three read commands and never places, sells or cancels anything:
#   arena balance --json
#   arena positions --live --json
#   arena orders --status resting --json
#
# Usage:
#   ./daily-review.sh                 # print the JSON
#   ./daily-review.sh > review.json   # save it
#
# Needs the arena CLI (npm install -g arena-prediction-cli), signed in with `arena login`.
# Set ARENA_BIN to use a different arena executable.
# Exits with the CLI's own exit code when a command fails (4 means: run `arena login`).

set -euo pipefail

ARENA="${ARENA_BIN:-arena}"

if ! command -v "$ARENA" >/dev/null 2>&1; then
  echo "daily-review: '$ARENA' not found. Install it with: npm install -g arena-prediction-cli" >&2
  exit 127
fi

# Run one read command with --json and print its output.
# On failure, name the command and exit with the CLI's exit code.
read_json() {
  local out code=0
  out="$("$ARENA" "$@" --json)" || code=$?
  if [ "$code" -ne 0 ]; then
    echo "daily-review: 'arena $* --json' exited $code" >&2
    if [ "$code" -eq 4 ]; then
      echo "daily-review: not signed in. Run: arena login" >&2
    fi
    exit "$code"
  fi
  printf '%s' "$out"
}

balance="$(read_json balance)"
positions="$(read_json positions --live)"
orders="$(read_json orders --status resting)"

# Node.js is already installed, because the arena CLI runs on it.
# Merge the three answers into one document and drop the `help` hints.
node -e '
const [balance, positions, orders] = process.argv.slice(1).map((text) => JSON.parse(text));
const { help: _help, ...positionSummary } = positions;
const review = {
  generatedAt: new Date().toISOString(),
  balance: balance.balance,
  positions: positionSummary,
  restingOrders: orders,
};
process.stdout.write(JSON.stringify(review, null, 2) + "\n");
' "$balance" "$positions" "$orders"
