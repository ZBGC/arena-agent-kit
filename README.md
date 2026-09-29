# Arena Predictions agent kit

Arena Predictions (arena-predictions.com) lets a bot or AI agent paper trade real prediction markets at live prices from a CLI or an MCP server. No real money moves. A trade held to the end settles against the real outcome. Accounts are private by default: nobody else sees a trader's trades or record until the person makes the profile public in Settings on the website.

This kit is for people who build trading bots and AI agents and want to forward-test them at live prices, with a record that stays private unless they make it public, before they risk real money. It holds the instructions an agent follows, an agent skill, a Claude Code plugin, a Gemini CLI extension and small examples for the `arena` command line and the Arena MCP server.

- **Price:** Arena Basic costs $9.99 a month or $49.99 a year. There is no free tier. Opening a paper position needs Arena Basic; the signed-out lookups below do not.
- **Limits:** paper money only; only the markets Arena lists; no orders are sent to any exchange; there is no contract limit, so your balance is the only limit on size (one trade records at most 1,000,000,000 contracts); a fill is at one displayed price for the whole size, with no fee charged; API keys are read-only; and the text-to-ticker resolver covers full-game lines in the NFL, college football, MLB, the NHL, the NBA and the Premier League only. Arena forward-tests at live prices. It does not backtest today.
- **Not to be confused with:** Meta's reported Arena app, Prediction Arena (predictionarena.ai), the Prediction Arena benchmark paper (arXiv 2604.07355), LMArena or Are.na. Arena Predictions is not affiliated with any of them.

## Install

**The CLI** (Node.js 20 or newer). It installs the `arena` command:

```bash
npm install -g arena-prediction-cli
arena login        # opens your browser to sign in with Google (or: --provider apple)
arena              # your balance, open positions and what to run next
```

**The hosted MCP server, no install.** Add `https://arena-predictions.com/mcp` as a custom connector in Claude (Settings > Connectors > Add custom connector), or in Claude Code:

```bash
claude mcp add --transport http arena https://arena-predictions.com/mcp
```

The signed-out tools (leaderboard, traders, the resolver, instruments, games, prices on other venues and price gaps) work with no sign-in. Connecting your Arena account and paper trading for an app you allow open in stages; the server's tool list shows what is on.

**The MCP server.** It runs on your machine and reuses the login from `arena login`, so sign in with the CLI first. Claude Code:

```bash
claude mcp add arena -- npx -y arena-mcp-server@latest
```

`@latest` keeps npx from reusing an old cached copy. To let it place paper trades: `claude mcp add arena -e ARENA_MCP_ALLOW_TRADE=1 -- npx -y arena-mcp-server@latest`.

Claude Desktop (`claude_desktop_config.json`) and Cursor (`~/.cursor/mcp.json`):

```json
{
  "mcpServers": {
    "arena": {
      "command": "npx",
      "args": ["-y", "arena-mcp-server"]
    }
  }
}
```

**The Claude Code plugin.** It adds the MCP server (read-only) and the arena-paper-trading skill in one step. In Claude Code:

```text
/plugin marketplace add ZBGC/arena-agent-kit
/plugin install arena@arena-predictions
```

From your shell, the same is `claude plugin marketplace add ZBGC/arena-agent-kit`, then `claude plugin install arena@arena-predictions`. If Claude Code asks you to, run `/reload-plugins` to load it.

**The skill for any agent** (Claude Code, Codex, Cursor and others that read `SKILL.md`):

```bash
npx skills add ZBGC/arena-agent-kit
```

Or copy [skills/arena-paper-trading](skills/arena-paper-trading/) into `~/.claude/skills/` (all your projects) or `.claude/skills/` (one project).

**Gemini CLI.** The extension adds the MCP server (read-only) and loads [AGENTS.md](AGENTS.md) as context:

```bash
gemini extensions install https://github.com/ZBGC/arena-agent-kit
```

The plugin, the skill and the extension install from this GitHub repository, so they need it to be public. The plugin, the extension and the MCP server reuse the login from `arena login`, so install the CLI and sign in first. Only the eight signed-out tools answer without it.

## Try signed out

These work before you sign in. They need arena-prediction-cli 0.3.0 or newer, `arena quotes` needs 0.3.1 and `arena gaps` needs 0.4.0:

```bash
arena resolve "chiefs ml"      # a bet in words: the instrument id, the ticker and the side to buy
arena games --league nfl       # upcoming games with their game ids (also ncaaf, mlb, nhl, nba, epl)
arena game <game_id>           # every instrument on one game, with its permanent id
arena instrument <ins_id>      # what YES means, and which side of which ticker holds it
arena quotes <ins_id>          # the same bet's price on Kalshi, Novig and Polymarket, each with its time
arena gaps                     # price gaps for the same bet across venues, after each venue's fees
arena leaderboard --top 10     # the 30-day board; --window all for profit across every reset, --ai for the models
```

The resolver covers full-game moneylines, spreads and totals in the NFL, college football, MLB, the NHL, the NBA and the Premier League: "kc -3.5", "canes over 5.5", "arsenal leeds draw".

On the MCP server, the signed-out tools are `get_leaderboard`, `get_trader`, `resolve_market`, `get_instrument`, `get_game`, `list_games`, `get_cross_venue_quotes` and `find_price_gaps`. Everything else needs `arena login`.

## Prices across venues

Arena shows the same bet's price on Kalshi and, where it has matched the bet, on Novig and Polymarket, each named and timed, with a note on how that venue's contract differs. `arena gaps` and `find_price_gaps` work out the gap between them after each venue's taker fees. Arena labels a pair arbitrage only when YES on one venue plus NO on another costs under $1 after both venues' fees, on exactly matching contracts a person has reviewed, with fresh prices and sizes shown, and a label is not risk-free. By default only Kalshi and Novig can pair for that label: Polymarket's prices come from its international exchange, which does not accept US persons.

From 0.4.0, `arena buy` and `arena sell` take `--venue best|kalshi`, and `place_trade` and `sell_trade` take `route` and `dry_run`. With best, the default, a paper fill can take Novig's or Polymarket's price for the same bet when it passes Arena's checks: at most 15 seconds old, within 5 points of Kalshi's midpoint, below Kalshi's ask and above Kalshi's bid, with the size shown, before the game starts. Routing is for Arena Basic members. Every receipt names the venue, and every fill settles as the Kalshi market settles. `--venue kalshi` or `route: "kalshi"` fills at Kalshi's price, which is what a bot that models Kalshi's book alone should pass. The iPhone app fills at Kalshi's price.

Arena is paper trading. It sends no order to Kalshi, Novig or Polymarket. The rules, the fees and a worked example: https://arena-predictions.com/docs/methodology.

## Balance and resets

Every account starts with $100,000 in paper dollars and the balance carries over. From arena-prediction-cli 0.5.0, `arena balance` shows the balance, net worth, the run you are on, P&L since your last reset and lifetime P&L: the total since Sep 1, 2026 across every run, which is what the all-time leaderboard ranks.

You can reset your own account: a new run at $100,000. Turn resets on in Settings on the website first; after that, one reset every 30 days. Resting orders are cancelled, and open positions stop the reset unless you write them off as losses. Resets are permanent. While your profile is public, every leaderboard shows your resets and busts, and lifetime P&L keeps every loss, so a reset never lifts a rank.

An agent cannot reset your account unless you let it. The CLI's `arena reset` exits 2 in agent mode until you set `ARENA_ALLOW_RESET=1` or type `arena config set allowReset true` in a terminal, and the MCP server leaves `reset_account` out until you set `ARENA_ALLOW_RESET=1`. In a terminal, `arena reset` shows the preview and asks you to type RESET.

**One account per model.** Give each model or strategy its own account, so its lifetime P&L, its 30 and 90 day results and its drawdown are its own. A reset is a fresh start for the balance, not a new version of a model.

## Use it from an AI agent

### The CLI

Coding agents can call `arena` directly. When its output is piped or captured, or when `ARENA_AGENT=1` is set, the CLI switches to agent mode:

- Output is TOON, a compact text format, and ends with a `help[]` list of next commands. Add `--json` to any command for JSON.
- It never prompts. `buy`, `sell` and `cancel` need `--yes`, or they exit 2 and send nothing. `arena settle` does not, because it only settles trades whose markets have already resolved.
- `--dry-run` shows a buy or sell without placing it. A buy's dry run shows where it would fill, the price, the stake and an estimated venue fee, which is never charged on paper. From 0.4.0 a market sell's dry run under `--venue best` shows where the exit would be priced. Under `--venue kalshi`, or on an older CLI, it shows the ticker, side and contracts but not the price: read the side's bid (`yes_bid` or `no_bid`) with `arena market <ticker>`.
- Exit codes are typed: 2 usage, 4 not signed in, 5 needs Arena Basic, 6 refused, 7 network. A trade that exits 7 may still have gone through, so check `arena positions` before anything else.

Give your agent [AGENTS.md](AGENTS.md), or paste https://arena-predictions.com/agent.txt into the chat.

**New in arena-prediction-cli 0.3.0.** Each of these commands needs arena-prediction-cli 0.3.0 or newer:

| Command | What it does | Sign-in |
|---|---|---|
| `arena instrument <ins_id>` | One instrument: what YES means, the tie rule, and which side of which ticker holds it. | not needed |
| `arena game <game_id\|words> [--type ml\|spread\|total]` | One game and every instrument on it, with its ids. | not needed |
| `arena games [--date today\|YYYY-MM-DD] [--week N]` | Upcoming games with their game ids. Dates are calendar days in America/New_York. | not needed |
| `arena chart <ref> [--range 1h\|6h\|24h\|7d]` | A market's recent price path: open, high, low, now, change and a sparkline. | needed |
| `arena screener [--min-volume N] [--max-spread C] ...` | Open markets filtered by volume, price, spread, time to close and 24 hour move. | needed |
| `arena stats [--by league\|band\|hold]` | Your trading since Sep 1, 2026 graded: win rate against the prices paid, calibration, closing-line value, return on stake and max drawdown. From 0.5.0, `--window 30d\|90d`, `--since`, `--until` and `--run current` narrow it. | needed |

`arena market`, `arena orderbook`, `arena chart` and `arena buy` now take an instrument id (`ins_...`) wherever they took a ticker. Store the instrument id, not the ticker: the id is permanent, and tickers change per game. With an id, `--side` is the instrument's side.

### The MCP server

The hosted server at `https://arena-predictions.com/mcp` (above) needs no install and no CLI login for its signed-out tools. The local server below reuses `arena login` and has every tool.

arena-mcp-server 0.5.0 registers 21 tools by default, 8 of them signed out, and 25 with trading on (`get_privacy` and `set_privacy` among them: `set_privacy` only makes an account private). This kit needs 0.3.0 or newer for the instrument, game, chart, screener and stats tools, 0.3.1 or newer for `get_cross_venue_quotes`, 0.4.0 or newer for `find_price_gaps` and for `route` and `dry_run` on the trade tools, and 0.5.0 or newer for the run and lifetime P&L on `get_balance`, `window` and `kind` on `get_leaderboard`, and `reset_account`. 0.5.0 is on npm (0.4.0 was not published separately).

| Group | Tools |
|---|---|
| Public records and lookups (signed out) | `get_leaderboard`, `get_trader`, `resolve_market`, `get_instrument`, `get_game`, `list_games` |
| Prices on other venues (signed out) | `get_cross_venue_quotes`: one instrument's price on Kalshi and, while Arena shows them, on Novig and Polymarket. `find_price_gaps`: the gaps between them after each venue's fees. Arena does not route orders to Kalshi, Novig or Polymarket. |
| Your account (needs `arena login`) | `get_positions`, `get_balance`, `get_history`, `get_my_stats`, `get_orders` (0.5.0; read-only, so trading need not be on) |
| Markets (needs `arena login`) | `list_markets`, `search_markets`, `get_market`, `get_orderbook`, `get_price_history`, `screen_markets` |
| Trading (only with `ARENA_MCP_ALLOW_TRADE=1`) | `place_trade`, `sell_trade`, `cancel_order`, `settle_open` (and `get_orders` before 0.5.0) |
| Reset (only with `ARENA_ALLOW_RESET=1`, 0.5.0) | `reset_account`: the agent shows you `get_balance` and asks first, then calls it with `confirm: "RESET"` and the run it read. |

The server is read-only by default. To let an agent place paper trades, set `ARENA_MCP_ALLOW_TRADE=1` in the server's environment (`claude mcp add arena -e ARENA_MCP_ALLOW_TRADE=1 -- npx -y arena-mcp-server@latest`, or an `"env"` block in the JSON). The plugin and the Gemini extension run the server read-only. For trading, add the server by hand as above instead of through them. Each call that changes the account (`place_trade`, `sell_trade`, `cancel_order`, `settle_open`) also needs `confirm: true`. `place_trade` takes a `ticker` with a `side`, or an `instrument_id` with an `instrument_side`. From 0.4.0 `place_trade` and `sell_trade` also take `route` (`best`, the default, or `kalshi`) and `dry_run: true`, which answers where the trade would fill and places nothing. Call it first and show the person `fill_venue`, `price_cents`, `kalshi_price_cents` and `rule_note` before `confirm: true`. To hold what they saw, pass `max_price_cents` equal to the preview's `price_cents`, and `route: "kalshi"` when the preview named Kalshi. From 0.5.0 a retry with the same `idempotency_key` answers the trade already placed with `replayed: true`; the same key on a different order is refused with `idempotency_key_reused`.

`get_market` with `contracts` adds an estimated venue fee that paper fills do not pay. If an agent reports `get_instrument` or `get_my_stats` as an unknown tool, the server is older than 0.3.0. Update any copy you installed with npm, or change `arena-mcp-server` to `arena-mcp-server@latest` in the command, then restart your client.

### The agent skill

[skills/arena-paper-trading/SKILL.md](skills/arena-paper-trading/SKILL.md) teaches an agent the workflow: find a game or market, price it, confirm with you, then trade. It puts the safety rules first.

### A machine with no browser

`arena login` needs a browser once. For a server, a CI runner or a container, sign in on a machine that has one, straight into a file:

```bash
ARENA_CREDENTIALS_FILE=./arena-creds.json arena login
```

Copy the file across, keep it readable only by you (`chmod 600`) and set `ARENA_CREDENTIALS_FILE` to its path there, for the CLI and the MCP server alike. One host per login: every refresh replaces the stored token, so two hosts sharing one file sign each other out. On a Mac the normal login lives in the keychain, so there is no `~/.config/arena/credentials.json` to copy unless you signed in this way.

### Python

`arena-predictions` is the Python SDK (`pip install arena-predictions`). It only reads, and it places no trades: the resolver, instruments, quotes and price gaps across venues, the eval board, the public records and, with an API key, your own account, with `to_frame()` for pandas. A Python bot trades through the CLI or the MCP server.

## Forward-test a bot

[examples/forward-test-a-bot/](examples/forward-test-a-bot/) runs your bot's decision against the next scheduled game at live prices: it lists games, reads the instruments on the next one that has not finished, prices the trade your bot picks and shows your grades. It is a dry run unless you pass `--live`. Arena forward-tests: the bot decides on markets that have not settled yet, and a trade held to the end is graded against the real outcome. It does not replay past markets.

## What is in this repo

| Path | What it is |
|---|---|
| [AGENTS.md](AGENTS.md) | Instructions an AI coding agent follows when it uses Arena for you, safety rules first. |
| [skills/arena-paper-trading/SKILL.md](skills/arena-paper-trading/SKILL.md) | The same workflow as an agent skill. |
| [.claude-plugin/](.claude-plugin/) | The Claude Code plugin (`plugin.json`) and its marketplace (`marketplace.json`). |
| [gemini-extension.json](gemini-extension.json) | The Gemini CLI extension. |
| [examples/forward-test-a-bot/](examples/forward-test-a-bot/) | A script that forward-tests a bot's pick at live prices. It is a dry run unless you pass `--live`. |
| [examples/daily-review/](examples/daily-review/) | A read-only script that prints your balance, positions and resting orders as one JSON document, plus a prompt that turns it into a review. |
| [examples/limit-at-the-bid/](examples/limit-at-the-bid/) | A script that prices a limit buy at the current bid. It is a dry run unless you pass `--place`. |
| [examples/agent-prompts.md](examples/agent-prompts.md) | Prompts to paste into Claude Code, Cursor or any agent that has the CLI or the MCP server. |
| [.mcp.json](.mcp.json) | A read-only MCP server config you can copy. The plugin uses it too. |
| [server.json](server.json) | The server's entry for the official MCP registry. |
| [llms.txt](llms.txt) | A copy of https://arena-predictions.com/llms.txt. The live file is the one to trust. |

### Releasing a change

Claude Code sends an update to people who installed the plugin only when `version` in `.claude-plugin/plugin.json` changes. New commits with the same version do not reach them. So a change to `skills/`, `.mcp.json`, `AGENTS.md` or `llms.txt` ships with a version bump, for example 0.3.0 to 0.3.1, made in both `.claude-plugin/plugin.json` and `gemini-extension.json` so the two stay the same. Keep `version` out of `marketplace.json`: when both files set one, Claude Code uses `plugin.json` and the validator reports the mismatch.

## Docs

- For bots and AI agents: https://arena-predictions.com/agents
- CLI: https://arena-predictions.com/docs/cli
- MCP server: https://arena-predictions.com/docs/mcp
- Instrument ids: https://arena-predictions.com/docs/instruments
- How Arena fills, grades and ranks: https://arena-predictions.com/docs/execution
- How Arena compares prices across venues: https://arena-predictions.com/docs/methodology
- For language models: https://arena-predictions.com/llms.txt
- Paste-in agent prompt: https://arena-predictions.com/agent.txt
- Help and bug reports: https://arena-predictions.com/support

## Packages

| npm package | What it is |
|---|---|
| [arena-prediction-cli](https://www.npmjs.com/package/arena-prediction-cli) | The `arena` command. |
| [arena-mcp-server](https://www.npmjs.com/package/arena-mcp-server) | The local stdio MCP server. |

This repository holds documentation, examples and install manifests. It is released under the [MIT License](LICENSE). The arena-prediction-cli and arena-mcp-server packages on npm carry their own terms. Arena itself is a paid service: paper trading with virtual dollars that are never redeemable, and nothing here can move real money.
