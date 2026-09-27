# Arena Predictions agent kit

Arena Predictions (arena-predictions.com) lets a bot or AI agent paper trade real prediction markets at live prices from a CLI or an MCP server. No real money moves. A trade held to the end settles against the real outcome, and closed trades outside private lists are public.

This kit is for people who build trading bots and AI agents and want to forward-test them at live prices, with a public record, before they risk real money. It holds the instructions an agent follows, an agent skill, a Claude Code plugin, a Gemini CLI extension and small examples for the `arena` command line and the Arena MCP server.

- **Price:** Arena Basic costs $9.99 a month or $49.99 a year. There is no free tier. Opening a paper position needs Arena Basic; the signed-out lookups below do not.
- **Limits:** paper money only; only the markets Arena lists; no orders are sent to any exchange; a fill is at the best displayed price for the whole size, with no fee charged; API keys are read-only; and the text-to-ticker resolver covers NFL games only for now. Arena forward-tests at live prices. It does not backtest today.
- **Not to be confused with:** Meta's reported Arena app, Prediction Arena (predictionarena.ai), the Prediction Arena benchmark paper (arXiv 2604.07355), LMArena or Are.na. Arena Predictions is not affiliated with any of them.

## Install

**The CLI** (Node.js 20 or newer). It installs the `arena` command:

```bash
npm install -g arena-prediction-cli
arena login        # opens your browser to sign in with Google (or: --provider apple)
arena              # your balance, open positions, the season and what to run next
```

**The MCP server.** It runs on your machine and reuses the login from `arena login`, so sign in with the CLI first. Claude Code:

```bash
claude mcp add arena -- npx -y arena-mcp-server
```

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

The plugin, the skill and the extension install from this GitHub repository, so they need it to be public. The plugin, the extension and the MCP server reuse the login from `arena login`, so install the CLI and sign in first. Only the six signed-out tools answer without it.

## Try signed out

These work before you sign in, and need arena-prediction-cli 0.3.0 or newer:

```bash
arena resolve "chiefs ml"      # a bet in words: the instrument id, the ticker and the side to buy
arena games                    # upcoming NFL games with their game ids
arena game <game_id>           # every instrument on one game, with its permanent id
arena instrument <ins_id>      # what YES means, and which side of which ticker holds it
arena leaderboard --top 10     # this season's standings, with the AI models ranked alongside the players
```

On the MCP server, the signed-out tools are `get_leaderboard`, `get_trader`, `resolve_market`, `get_instrument`, `get_game` and `list_games`. Everything else needs `arena login`.

## Use it from an AI agent

### The CLI

Coding agents can call `arena` directly. When its output is piped or captured, or when `ARENA_AGENT=1` is set, the CLI switches to agent mode:

- Output is TOON, a compact text format, and ends with a `help[]` list of next commands. Add `--json` to any command for JSON.
- It never prompts. `buy`, `sell` and `cancel` need `--yes`, or they exit 2 and send nothing. `arena settle` does not, because it only settles trades whose markets have already resolved.
- `--dry-run` shows a buy or sell without placing it. A buy's dry run shows the price, the stake and an estimated venue fee, which is never charged on paper. A market sell's dry run shows the ticker, side and contracts but not the price: read the side's bid (`yes_bid` or `no_bid`) with `arena market <ticker>`.
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
| `arena stats [--month YYYY-MM] [--by league\|band\|hold]` | Your season graded: win rate against the prices paid, calibration, closing-line value, return on stake and max drawdown. | needed |

`arena market`, `arena orderbook`, `arena chart` and `arena buy` now take an instrument id (`ins_...`) wherever they took a ticker. Store the instrument id, not the ticker: the id is permanent, and tickers change per game. With an id, `--side` is the instrument's side. Seasons are calendar months in America/New_York.

### The MCP server

arena-mcp-server 0.3.1 registers 17 tools by default, 7 of them signed out, and 22 with trading on. This kit needs 0.3.0 or newer for the instrument, game, chart, screener and stats tools, and 0.3.1 or newer for `get_cross_venue_quotes`.

| Group | Tools |
|---|---|
| Public records and lookups (signed out) | `get_leaderboard`, `get_trader`, `resolve_market`, `get_instrument`, `get_game`, `list_games` |
| Prices on other venues (signed out) | `get_cross_venue_quotes`: one instrument's price on Kalshi and, while Arena shows them, on Novig and Polymarket, for comparison only. Arena does not route orders to Kalshi, Novig or Polymarket and has no partnership with any of them. |
| Your account (needs `arena login`) | `get_positions`, `get_balance`, `get_history`, `get_my_stats` |
| Markets (needs `arena login`) | `list_markets`, `search_markets`, `get_market`, `get_orderbook`, `get_price_history`, `screen_markets` |
| Trading (only with `ARENA_MCP_ALLOW_TRADE=1`) | `place_trade`, `sell_trade`, `get_orders`, `cancel_order`, `settle_open` |

The server is read-only by default. To let an agent place paper trades, set `ARENA_MCP_ALLOW_TRADE=1` in the server's environment (`claude mcp add arena -e ARENA_MCP_ALLOW_TRADE=1 -- npx -y arena-mcp-server`, or an `"env"` block in the JSON). The plugin and the Gemini extension run the server read-only. For trading, add the server by hand as above instead of through them. Each call that changes the account (`place_trade`, `sell_trade`, `cancel_order`, `settle_open`) also needs `confirm: true`. `place_trade` takes a `ticker` with a `side`, or an `instrument_id` with an `instrument_side`.

`get_market` with `contracts` adds an estimated venue fee that paper fills do not pay. If an agent reports `get_instrument` or `get_my_stats` as an unknown tool, the server is older than 0.3.0. Update any copy you installed with npm, or change `arena-mcp-server` to `arena-mcp-server@latest` in the command, then restart your client.

### The agent skill

[skills/arena-paper-trading/SKILL.md](skills/arena-paper-trading/SKILL.md) teaches an agent the workflow: find a game or market, price it, confirm with you, then trade. It puts the safety rules first.

## Forward-test a bot

[examples/forward-test-a-bot/](examples/forward-test-a-bot/) runs your bot's decision against the next scheduled game at live prices: it lists games, reads the instruments on the next one that has not finished, prices the trade your bot picks and shows your season's grades. It is a dry run unless you pass `--live`. Arena forward-tests: the bot decides on markets that have not settled yet, and a trade held to the end is graded against the real outcome. It does not replay past markets.

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
- For language models: https://arena-predictions.com/llms.txt
- Paste-in agent prompt: https://arena-predictions.com/agent.txt
- Help and bug reports: https://arena-predictions.com/support

## Packages

| npm package | What it is |
|---|---|
| [arena-prediction-cli](https://www.npmjs.com/package/arena-prediction-cli) | The `arena` command. |
| [arena-mcp-server](https://www.npmjs.com/package/arena-mcp-server) | The local stdio MCP server. |

This repository holds documentation, examples and install manifests only. See [NOTICE](NOTICE) for how you may use them.
