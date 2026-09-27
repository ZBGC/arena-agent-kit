# Forward-test a bot

`forward-test.sh` runs one forward-test step for a trading bot on Arena: it lists upcoming games, reads every instrument on the next one that has not finished, prices a trade and shows your season's grades. **It is a dry run by default:** it places nothing unless you pass `--live`.

```bash
./forward-test.sh                                    # dry run: the first instrument, YES, 1 contract
./forward-test.sh --bot "python3 my_bot.py"          # dry run: your bot picks the trade
./forward-test.sh --bot "python3 my_bot.py" --live   # places your bot's pick as a paper trade
./forward-test.sh --decision "ins_MBZ9SWMJTB0K yes 2" --max-price 55 --live
                                                     # places exactly the trade a dry run quoted
```

It needs the `arena` CLI 0.3.0 or newer (`npm install -g arena-prediction-cli`). Steps 1 and 2 work signed out. Pricing a trade and reading stats need `arena login`, and placing one needs an Arena Basic membership ($9.99 a month or $49.99 a year; there is no free tier).

## Forward testing, not backtesting

- **A backtest** replays a strategy over past markets to see how it would have done. **Arena does not backtest today**: there is no replay of past markets and no bulk historical data download.
- **A forward test** runs the strategy on markets that have not settled yet, at the prices it would really see, and waits for the real outcomes. That is what Arena does. Your bot decides now, Arena prices the paper trade from the live market, and a trade held to the end settles against the real result.

A backtest can tell you a strategy fit the past. A forward test tells you how it does on games it has never seen, before you risk real money. They answer different questions. You can backtest with other tools first, then forward-test here.

## What the script runs

The CLI runs in agent mode (`ARENA_AGENT=1`), so it never prompts.

1. `arena games --limit 20 --json`: games with their `game_id` and `status`. The list starts 6 hours back, so after kickoff it can open with finished games. The script takes the first game that is scheduled or under way and has instruments, and prefers one that has not started. It never takes a finished, postponed or cancelled game. If none qualifies, it says so and exits 0.
2. `arena game <game_id> --json`: every instrument on that game, each with a permanent `instrument_id` (`ins_...`), a `label` such as `NE ML`, and `yes_means`.
3. `arena buy <ins_id> --side yes --contracts 1 --dry-run`: the quote. It shows the price, the stake and `venue_fee_est_dollars`, and places nothing. With `--live`, the script runs the same command with `--yes` instead of `--dry-run`, and that is the only place it adds `--yes`. With `--max-price <cents>`, it adds `--max-price`, so the CLI refuses the trade (exit 6) if the ask is above that price.
4. `arena stats`: your season graded, with win rate against the prices paid, calibration by price band, closing-line value, return on stake and max drawdown.

JSON goes to stdout and progress lines go to stderr. On an error the script stops with the CLI's exit code: 4 means run `arena login`, 5 means the trade needs Arena Basic, 6 means the trade was refused. Exit 1 means the bot command failed.

## Plug in your bot

`--bot <command>` hands the choice to your code. The script gives the command the game's JSON (the output of step 2) on stdin. The command prints one line, `<ins_id> <yes|no> <contracts>`, or nothing to skip this run. Only the first line counts, so the bot may log more after it, and it does not have to read stdin:

```text
ins_MBZ9SWMJTB0K yes 2
```

- The side is the instrument's side: `yes` holds the `label` (for example `NE ML`), and `no` holds the other outcome. Arena maps it to the right side of the market that lists it.
- Keep the `instrument_id` your bot traded, with its side. The id never changes, so it is the key to join your bot's own log with Arena's `arena positions --json` and `arena history --json`, which carry `instrument_id`, `instrument_label` and `instrument_side`.
- Your bot runs on your machine. The arena CLI and MCP server do not read, transmit or store your bot's code, models, prompts, rules or methods. Arena does store the orders and trades your bot places (see https://arena-predictions.com/terms#your-strategies).

## Before you use --live

- A run with `--live` and no `--decision` asks the bot again at the prices of that moment, so it can place a different trade from the one an earlier dry run showed. To place exactly the trade you approved, pass that dry run's values: `--decision "<ins_id> <side> <contracts>"` skips the game lookup and the bot, and `--max-price <askCents>` refuses the trade if the ask has risen since. If it exits 6 for the price, run the dry run again and decide on the new quote.
- `--live` places a paper trade on your account every time it runs. Each run is a new order, so running it twice places two trades. If you schedule the script, adding `--live` to the schedule is your decision.
- If a live run stops with exit 7, the trade may still have gone through. Check `arena positions` and `arena orders` before running it again.
- The trade goes on your record. A trade held to the end settles against the real outcome, and closed trades outside private lists are public, on your profile and the monthly leaderboard.

## Read the results honestly

- **Fills are simpler than a real venue.** A market order fills the whole size at the best displayed price, with no fee and no queue. The dry run's `venue_fee_est_dollars` and, when the book can be read, `walk_vwap_cents`, `walk_slippage_cents` and `walk_fillable` show what a real venue might charge and what walking the book would cost. They are for reference and are never charged. On a thin book, a paper result can look better than a real one would.
- **Grades come after settlement.** `arena stats` grades only trades that settle won or lost. Sold and pushed trades count in P&L but carry no win or loss. `arena settle` settles resolved trades now instead of waiting for the automatic run.
- **Seasons reset.** A season is one calendar month in America/New_York, and every account restarts at the season's starting stake. `arena stats --month YYYY-MM` reads a past season.
- **Coverage is narrow for now.** Game and instrument ids cover NFL full-game moneylines, spreads and totals. Spreads and totals are added closer to kickoff, so early in the week a game may list only its moneylines.

## On a server

A bot on a machine with no browser can use a login saved to a file. Sign in on a machine that has a browser with `ARENA_CREDENTIALS_FILE="$HOME/arena-credentials.json" arena login`, move the file, keep it readable only by you (`chmod 600`) and set `ARENA_CREDENTIALS_FILE` to its path there. Keep one copy only: every refresh replaces the stored token. The CLI docs have the details: https://arena-predictions.com/docs/cli
