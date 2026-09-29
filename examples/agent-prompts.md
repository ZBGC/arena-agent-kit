# Agent prompts

Prompts to paste into Claude Code, Cursor or any coding agent that can run the `arena` CLI or has the Arena MCP server. Replace anything in angle brackets.

Arena is paper trading, so nothing here can spend real money. The prompts still tell the agent to ask before it changes your account, because the positions and the record are yours.

## First session

```text
I have the Arena CLI installed as `arena`. Run `arena` on its own and tell me my balance
and how many positions I have open. If I am not signed in, tell me to
run `arena login` and stop. Do not place, sell or cancel anything.
```

## Find a market

```text
List this week's NFL markets with
`arena markets --league NFL --limit 50 --fields event_title,ticker,yes_sub_title,yes_bid,yes_ask,no_bid,no_ask`.
Group them by event_title, and for each game show both sides (yes_sub_title) with their
bid and ask in cents. Read-only: do not place anything.
```

```text
Find the Arena market for "<city or topic>". Start with
`arena search "<city or topic>" --fields ticker,title,event_ticker,yes_ask,no_ask`,
then use `arena markets --event <event_ticker>` to see every market in that event.
For the best match, run
`arena market <ticker> --fields title,yes_sub_title,event_ticker,yes_bid,yes_ask,no_bid,no_ask,volume,status,close_time`
and `arena orderbook <ticker> --depth 5`, and tell me what YES means (the title and
yes_sub_title), the spread and the volume. Read-only.
```

## Look up a game (no sign-in needed)

```text
Run `arena games` and pick the next game. Then run `arena game <game_id>` and list its
instruments: label, instrument_id, market type and line. For the moneylines, run
`arena instrument <ins_id>` and tell me what YES means. Read-only. Needs arena-prediction-cli
0.3.0 or newer.
```

## Compare venues (no sign-in needed)

```text
Run `arena quotes "<bet in words>"` and show me each venue's price for YES, with its time and
its note. Then run `arena gaps "<bet in words>"` and show me each pair's cost after fees and
why it is or is not labelled arbitrage, word for word. Read-only. Needs arena-prediction-cli
0.4.0 or newer.
```

## Forward-test my bot

```text
I want to forward-test my trading bot on Arena at live prices before it trades real money.
My bot is `<command that runs my bot>`. It reads a game's JSON on stdin and prints one line,
"<ins_id> <yes|no> <contracts>", or nothing to skip.

Run `examples/forward-test-a-bot/forward-test.sh --bot "<command that runs my bot>"` (a dry
run) and show me, for the trade it picked: the game, the instrument label and what YES means,
the side, contracts, price, stake and the estimated venue fee (not charged on paper). Then
summarize `arena stats`: graded trades, win rate against the prices paid, closing-line value
and max drawdown.

Do not add --live and do not run anything with --yes. If I say "go live", place exactly the trade
the dry run showed me, once: run `examples/forward-test-a-bot/forward-test.sh --decision
"<ins_id> <side> <contracts>" --max-price <askCents> --live` with the values from that dry run.
Do not rerun the bot or pick another game. Show me the receipt. If it exits 6 because the ask
rose above my price, show me a new dry run and wait for me. If it exits 7, run `arena positions`
and `arena orders` instead of running it again.
```

```text
Grade my bot's trading with `arena stats --by band`. Tell me where my win rate beats
the prices I paid and where it does not, using the calibration table. Say how many trades are
graded, and do not draw conclusions from a band with fewer than 10 trades. Read-only.
```

## Price a trade, then wait for me

```text
Price a buy of <N> YES contracts on <ticker> with
`arena buy <ticker> --side yes --contracts <N> --dry-run`.
Tell me the venue it would fill on, the price, Kalshi's ask and bid, the stake in dollars
and what it pays if it wins. Do not run it with --yes until I reply "place it".
```

```text
I want to buy YES on <ticker> but not pay the spread. Show me the current bid, then run
`examples/limit-at-the-bid/limit-at-the-bid.sh <ticker> yes <N>` (it is a dry run) and
tell me how much it would hold from my balance while it rests.
Only rerun it with --place if I say so.
```

## Manage what I have

```text
Run
`arena positions --live --fields id,market_ticker,market_title,side,contracts,entry_price_cents,markPriceCents,unrealizedPnlDollars`
and `arena orders --fields orderId,ticker,side,limitPriceCents,remaining,expiresAt,holdDollars`.
For each open position show the market, side, contracts, entry price, current mark and
unrealized P&L. For each resting order show the limit price, contracts left and expiry. Suggest at most two changes, each as an exact
arena command: a buy or sell with --dry-run, or a cancel as `arena cancel <order-id>` with
no --dry-run and no --yes (cancel has no --dry-run). Do not change anything.
```

```text
Cancel my resting order <order-id>. First run `arena orders` and show me that order.
After I confirm, run `arena cancel <order-id> --yes` and tell me how much hold came back.
```

```text
Run ./examples/daily-review/daily-review.sh and give me my daily review
(see examples/daily-review/prompt.md). Read-only.
```

## Public records (no sign-in needed)

```text
Show the top 10 on the Arena leaderboard with `arena leaderboard --top 10`, then open the
record of the leader with `arena trader <name>` and their recent picks with
`arena trader <name> picks`. Summarize their record in three sentences.
```

## With the MCP server instead of the CLI

```text
Using the arena MCP tools, call get_balance and get_positions and summarize my paper account.
Then call search_markets for "<city or topic>" and get_market on the best match.
Do not call place_trade, sell_trade or cancel_order.
```

```text
Using the arena MCP tools, call list_games, then get_game on the first game, then get_market
with contracts: 10 on its first instrument_id. Show me the price, the stake and the estimated
venue fee (paper fills do not pay it). Then call get_my_stats. Do not call place_trade.
```

```text
Using the arena MCP tools, prepare a limit buy of <N> NO contracts on <ticker> at <price> cents.
If place_trade has no limit_price_cents argument, stop and tell me: the server is older than 0.2.0.
Show me the exact place_trade arguments first. Only call it, with confirm: true and a fresh
UUID idempotency_key, after I say "go".
```

The trade tools exist only when the server runs with `ARENA_MCP_ALLOW_TRADE=1`. Without it, the MCP server is read-only. Limit prices, `get_orders` and `cancel_order` need arena-mcp-server 0.2.0 or newer. `list_games`, `get_game`, `get_instrument`, `get_price_history`, `screen_markets` and `get_my_stats` need 0.3.0 or newer. `find_price_gaps`, and `route` and `dry_run` on `place_trade` and `sell_trade`, need 0.4.0 or newer; with `route: "best"`, the default, call `dry_run: true` first and show the venue before `confirm: true`.
