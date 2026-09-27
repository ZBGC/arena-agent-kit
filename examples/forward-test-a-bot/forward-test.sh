#!/usr/bin/env bash
# forward-test.sh: one forward-test step for a trading bot on Arena, at live prices.
#
# It runs the arena CLI in agent mode, in four steps:
#   1. arena games --limit 20                                  (signed out is fine)
#   2. arena game <game_id>                                    (the next game that has not finished)
#   3. arena buy <ins_id> --side yes --contracts 1 --dry-run   (the game's first instrument)
#   4. arena stats                                             (your season, graded)
#
# Step 2 takes the first listed game that is scheduled or under way and has
# instruments, and prefers one that has not started. It never takes a finished,
# postponed or cancelled game. If there is none, the script says so and exits 0.
#
# Step 3 is a DRY RUN: it prices the trade and places nothing. Only --live
# places it, as a paper trade on your account.
#
# Usage:
#   ./forward-test.sh [--bot <command>] [--league <id>] [--max-price <cents>] [--live]
#   ./forward-test.sh --decision "<ins_id> <yes|no> <contracts>" [--max-price <cents>] [--live]
#
# Options:
#   --bot <command>      Let your bot choose the trade. The command reads the game's JSON
#                        (the output of `arena game <game_id> --json`) on stdin and prints
#                        one line: "<ins_id> <yes|no> <contracts>", or nothing to skip.
#                        Without it, the script takes the first instrument, side yes, 1 contract.
#   --decision "<ins_id> <yes|no> <contracts>"
#                        Skip steps 1 and 2 and the bot, and price exactly this trade. With
#                        --live, place exactly this trade. Use it to place what a dry run quoted.
#   --max-price <cents>  Refuse the trade if the ask is above this price (1 to 99 cents),
#                        checked when the trade is priced. With --live, pass the dry run's
#                        askCents so the trade never costs more than the quote you approved.
#   --league <id>        League for step 1 (default nfl, the league Arena game ids cover for now).
#   --live               Place the paper trade instead of pricing it. Needs `arena login`
#                        and an Arena Basic membership.
#
# Needs the arena CLI 0.3.0 or newer (npm install -g arena-prediction-cli) and Node.js 20
# or newer, which the CLI already needs. Steps 3 and 4 need `arena login`.
# Set ARENA_BIN to use a different arena executable.
# Exit codes: 0 done, or no game to test on. 1 the bot failed, or its input could not be read.
# 2 to 7 come from the arena CLI: 2 bad usage, 4 not signed in, 5 needs Arena Basic,
# 6 refused (for example no live ask, or an ask above --max-price), 7 network.
# 127 when arena is not installed.

set -euo pipefail

ARENA="${ARENA_BIN:-arena}"
# Agent mode: compact output, never a prompt, and a trade without the confirmation flag exits 2.
export ARENA_AGENT=1

# Print the comment block above as help, then exit with the given code.
usage() {
  awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0" >&2
  exit "${1:-2}"
}

say() {
  echo "forward-test: $1" >&2
}

fail() {
  say "$1"
  exit "${2:-2}"
}

bot=""
decision_arg=""
has_decision=0
league=""
max_price=""
live=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --live) live=1; shift ;;
    --bot)
      [ "$#" -ge 2 ] || fail "--bot needs a command"
      bot="$2"; shift 2 ;;
    --decision)
      [ "$#" -ge 2 ] || fail "--decision needs \"<ins_id> <yes|no> <contracts>\""
      decision_arg="$2"; has_decision=1; shift 2 ;;
    --max-price)
      [ "$#" -ge 2 ] || fail "--max-price needs a price in cents, like 55"
      max_price="$2"; shift 2 ;;
    --league)
      [ "$#" -ge 2 ] || fail "--league needs a league id, like nfl"
      league="$2"; shift 2 ;;
    *) fail "unknown argument $1. Run with --help for usage" ;;
  esac
done

if [ "$has_decision" -eq 1 ]; then
  [ -z "$bot" ] || fail "use --decision or --bot, not both"
  [ -z "$league" ] || fail "--league has no effect with --decision, which skips steps 1 and 2"
  [ -n "$decision_arg" ] || fail "--decision needs \"<ins_id> <yes|no> <contracts>\""
fi
if [ -n "$max_price" ]; then
  case "$max_price" in
    *[!0-9]*) fail "--max-price must be a whole number of cents, got \"$max_price\"" ;;
  esac
  { [ "$max_price" -ge 1 ] && [ "$max_price" -le 99 ]; } || fail "--max-price must be 1 to 99 cents, got $max_price"
fi

if ! command -v "$ARENA" >/dev/null 2>&1; then
  fail "'$ARENA' not found. Install it with: npm install -g arena-prediction-cli" 127
fi

# Name a failed arena command, explain the common exit codes, and exit with the CLI's own code.
explain_and_exit() {
  local code="$1"
  shift
  say "'arena $*' exited $code"
  case "$code" in
    2) say "usage error. 'unknown command' means the CLI is older than 0.3.0: npm install -g arena-prediction-cli@latest" ;;
    4) say "not signed in. Run: arena login" ;;
    5) say "this needs an Arena Basic membership: https://arena-predictions.com/pro" ;;
    6) say "refused: for example an unknown instrument, a closed market, no live ask, or an ask above --max-price. Do not resend the same trade." ;;
    7) say "network or server error. After a trade, do not rerun: check arena positions and arena orders first." ;;
  esac
  exit "$code"
}

# Run one arena command and print its stdout. On failure, explain and exit.
run() {
  local out code=0
  out="$("$ARENA" "$@")" || code=$?
  [ "$code" -eq 0 ] || explain_and_exit "$code" "$@"
  printf '%s\n' "$out"
}

# Read one field from JSON on stdin with Node.js.
#   pick_game:  the first game that is scheduled or under way and has instruments,
#               preferring one that has not started; empty when there is none
#   pick_first: "<first instrument_id> yes 1"
json_pick() {
  node -e '
let text = "";
process.stdin.on("data", (chunk) => { text += chunk; });
process.stdin.on("end", () => {
  const doc = JSON.parse(text);
  if (process.argv[1] === "pick_game") {
    const games = Array.isArray(doc.games) ? doc.games : [];
    const open = games.filter((g) =>
      (g.status === "scheduled" || g.status === "inprogress") && Number(g.instrument_count) > 0);
    const now = Date.now();
    const notStarted = open.find((g) => g.status === "scheduled" && !(Date.parse(g.starts_at) <= now));
    const game = notStarted ?? open[0];
    process.stdout.write(game?.game_id ?? "");
  } else {
    const game = doc.game ?? {};
    const list = Array.isArray(game.instruments) ? game.instruments
      : Array.isArray(doc.instruments) ? doc.instruments : [];
    const first = list.find((i) => typeof i.instrument_id === "string");
    process.stdout.write(first ? `${first.instrument_id} yes 1` : "");
  }
});
' "$1"
}

if [ "$has_decision" -eq 1 ]; then
  say "steps 1 and 2 skipped: --decision names the trade"
  decision="$decision_arg"
else
  # 1. Upcoming games (read-only, works signed out). The list starts 6 hours back, so
  #    it can open with finished games; 20 rows reach past a full NFL Sunday slate.
  games_cmd=(games --limit 20)
  [ -n "$league" ] && games_cmd+=(--league "$league")
  say "step 1: arena ${games_cmd[*]}"
  games_json="$(run "${games_cmd[@]}" --json)"
  printf '%s\n' "$games_json"
  game_id="$(json_pick pick_game <<< "$games_json")" || fail "could not read the games list" 1
  [ -n "$game_id" ] || fail "no scheduled ${league:-nfl} game to test on in the next 20 listed. Try again closer to game day." 0

  # 2. Every instrument on that game (read-only, works signed out).
  say "step 2: arena game $game_id"
  game_json="$(run game "$game_id" --json)"
  printf '%s\n' "$game_json"

  # 3. The bot's decision. Replace the default with --bot. No pipes here: under
  #    pipefail, a bot that ignores stdin or prints a lot would fail the script.
  if [ -n "$bot" ]; then
    say "asking the bot: $bot"
    decision="$(sh -c "$bot" <<< "$game_json")" || fail "the bot command failed" 1
  else
    decision="$(json_pick pick_first <<< "$game_json")" || fail "could not read the game's instruments" 1
  fi
fi

# Keep the first line only, without a Windows line ending.
decision="${decision%%$'\n'*}"
decision="${decision%$'\r'}"
if [ -z "$decision" ]; then
  say "no trade this time"
else
  read -r ins_id side contracts <<< "$decision"
  case "$ins_id" in
    ins_*) ;;
    *) fail "the trade must start with an ins_ id, got \"$ins_id\"" ;;
  esac
  case "${side:-}" in
    yes|no) ;;
    *) fail "side must be yes or no, got \"${side:-}\"" ;;
  esac
  case "${contracts:-}" in
    ''|*[!0-9]*) fail "contracts must be a whole number, got \"${contracts:-}\"" ;;
  esac
  [ "$contracts" -ge 1 ] || fail "contracts must be at least 1"

  cmd=(buy "$ins_id" --side "$side" --contracts "$contracts")
  [ -n "$max_price" ] && cmd+=(--max-price "$max_price")
  if [ "$live" -eq 1 ]; then
    # --live: the caller asked for a real paper trade, so pass the CLI's consent flag.
    # This is the only place the script adds --yes. Each run is a new order, so
    # running the script twice places two trades.
    cmd+=(--yes)
    say "step 3: placing a paper trade: arena ${cmd[*]}"
    run "${cmd[@]}"
  else
    cmd+=(--dry-run)
    say "step 3: dry run, nothing will be placed. Add --live to place it."
    run "${cmd[@]}"
  fi
fi

# 4. The season so far, graded (read-only).
say "step 4: arena stats"
run stats
