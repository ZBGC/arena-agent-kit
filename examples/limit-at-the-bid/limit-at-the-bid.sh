#!/usr/bin/env bash
# limit-at-the-bid.sh: price a limit BUY at the current bid for one side of an Arena market.
#
# This is a DRY RUN unless you pass --place. A dry run prints the order it would
# place and places nothing. With --place it runs `arena buy ... --yes`, which
# places a paper order on your account.
#
# Usage:
#   ./limit-at-the-bid.sh <ticker> <yes|no> <contracts> [--tif gtc|ioc|fok] [--expires 30m|4h|2d|ISO-time] [--place]
#
# Examples:
#   ./limit-at-the-bid.sh <ticker> yes 10                 # dry run
#   ./limit-at-the-bid.sh <ticker> no 5 --expires 4h      # dry run of an order that would stop resting after 4 hours
#   ./limit-at-the-bid.sh <ticker> yes 10 --place         # places the paper order
#
# Needs the arena CLI (npm install -g arena-prediction-cli), signed in with `arena login`.
# Placing also needs an Arena Basic membership. Set ARENA_BIN to use a different arena executable.
# Exit codes follow the arena CLI: 2 bad usage, 4 not signed in, 5 needs Arena Basic, 6 refused, 7 network, and 127 when arena is not installed.

set -euo pipefail

ARENA="${ARENA_BIN:-arena}"

# Print the comment block above as help, then exit with the given code.
usage() {
  sed -n 's/^# \{0,1\}//; 2,18p' "$0" >&2
  exit "${1:-2}"
}

fail() {
  echo "limit-at-the-bid: $1" >&2
  exit "${2:-2}"
}

ticker=""
side=""
contracts=""
tif=""
expires=""
place=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --place) place=1; shift ;;
    --tif)
      [ "$#" -ge 2 ] || fail "--tif needs a value: gtc, ioc or fok"
      tif="$2"; shift 2 ;;
    --expires)
      [ "$#" -ge 2 ] || fail "--expires needs a value, like 4h or an ISO time"
      expires="$2"; shift 2 ;;
    -*) fail "unknown option $1. Run with --help for usage" ;;
    *)
      if [ -z "$ticker" ]; then ticker="$1"
      elif [ -z "$side" ]; then side="$1"
      elif [ -z "$contracts" ]; then contracts="$1"
      else fail "too many arguments. Run with --help for usage"
      fi
      shift ;;
  esac
done

[ -n "$ticker" ] && [ -n "$side" ] && [ -n "$contracts" ] || usage
case "$side" in
  yes|no) ;;
  *) fail "side must be yes or no, got \"$side\"" ;;
esac
case "$contracts" in
  ''|*[!0-9]*) fail "contracts must be a whole number, got \"$contracts\"" ;;
esac
[ "$contracts" -ge 1 ] || fail "contracts must be at least 1"
case "$tif" in
  ''|gtc|ioc|fok) ;;
  *) fail "--tif must be gtc, ioc or fok, got \"$tif\"" ;;
esac

if ! command -v "$ARENA" >/dev/null 2>&1; then
  fail "'$ARENA' not found. Install it with: npm install -g arena-prediction-cli" 127
fi

# 1. Read the market (read-only).
code=0
market_json="$("$ARENA" market "$ticker" --json)" || code=$?
if [ "$code" -ne 0 ]; then
  [ "$code" -eq 4 ] && echo "limit-at-the-bid: not signed in. Run: arena login" >&2
  fail "'arena market $ticker --json' exited $code" "$code"
fi

# 2. Pull out the market status and this side's bid. Node.js is already
#    installed, because the arena CLI runs on it.
fields="$(printf '%s' "$market_json" | node -e '
let text = "";
process.stdin.on("data", (chunk) => { text += chunk; });
process.stdin.on("end", () => {
  const market = JSON.parse(text).market ?? {};
  const bid = market[process.argv[1] + "_bid"];
  const title = String(market.title ?? "").replace(/\s+/g, " ");
  console.log([market.status ?? "unknown", Number.isInteger(bid) ? bid : "none", title].join("\t"));
});
' "$side")"
IFS=$'\t' read -r status bid title <<< "$fields"

case "$status" in
  active|open) ;;
  *) fail "$ticker is not open for trading (status: $status)" 6 ;;
esac
if [ "$bid" = "none" ] || [ "$bid" -lt 1 ] || [ "$bid" -gt 99 ]; then
  fail "no $side bid between 1 and 99 cents to join on $ticker (bid: $bid). Check: arena orderbook $ticker" 6
fi

echo "limit-at-the-bid: $ticker ($title): $side bid is ${bid}c" >&2

# 3. Build the order. A buy at the bid does not cross the spread, so it
#    usually rests until a seller comes down to your price.
cmd=("$ARENA" buy "$ticker" --side "$side" --contracts "$contracts" --limit "$bid")
[ -n "$tif" ] && cmd+=(--tif "$tif")
[ -n "$expires" ] && cmd+=(--expires "$expires")
if [ "$place" -eq 1 ]; then
  cmd+=(--yes --json)
  echo "limit-at-the-bid: placing: ${cmd[*]}" >&2
else
  cmd+=(--dry-run --json)
  echo "limit-at-the-bid: dry run, nothing will be placed. Add --place to place it." >&2
fi

exec "${cmd[@]}"
