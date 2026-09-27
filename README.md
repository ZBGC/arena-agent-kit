# Arena agent kit

Arena is paper trading for prediction markets: you trade live markets with virtual money, and every trade settles against the real outcome on a public record. No real money is ever deposited, wagered or paid out.

This kit shows how to use Arena from a terminal or from an AI agent: the `arena` command line, the Arena MCP server, an agent skill and a few small examples.

## Quick start

```bash
npm install -g arena-prediction-cli   # Node.js 20 or newer. Installs the `arena` command.
arena login                           # Opens your browser to sign in with Google (or: --provider apple)
arena                                 # Your balance, open positions, the season and what to run next
```

Bare `arena` is the first call for a person or an agent. It prints live state, not help text, and ends with the commands that usually come next. `arena --help` lists every command, and `arena <command> --help` lists its flags.

Signed out, `arena leaderboard`, `arena trader <name>` and `arena resolve "<bet in words>"` still work. `arena resolve` turns a bet such as `chiefs ml` or `kc -3.5` into a ticker and the side to buy. It covers the NFL for now and needs arena-prediction-cli 0.2.1 or newer. Everything else needs `arena login`, and opening a position needs an Arena Basic membership (https://arena-predictions.com/pro).

## Use it from an AI agent

### Option 1: the CLI

Coding agents can call `arena` directly. When its output is piped or captured, or when `ARENA_AGENT=1` is set, the CLI switches to agent mode:

- Output is TOON, a compact text format, and ends with a `help[]` list of next commands. Add `--json` to any command for JSON.
- It never prompts. `buy`, `sell` and `cancel` need `--yes`, or they exit 2 and send nothing. `arena settle` does not, because it only settles trades whose markets have already resolved.
- `--dry-run` shows a buy or sell without placing it. A buy's dry run includes the price and stake. A market sell's dry run shows the ticker, side and contracts but not the price: read the side's bid (`yes_bid` or `no_bid`) with `arena market <ticker>`.

Give your agent [AGENTS.md](AGENTS.md), or paste https://arena-predictions.com/agent.txt into the chat.

### Option 2: the MCP server

The MCP server runs on your machine and reuses the login from `arena login`, so sign in with the CLI first. This kit needs arena-mcp-server 0.2.0 or newer.

Claude Code:

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

The server is read-only by default. To let an agent place paper trades, set `ARENA_MCP_ALLOW_TRADE=1` in the server's environment (`claude mcp add arena -e ARENA_MCP_ALLOW_TRADE=1 -- npx -y arena-mcp-server`, or an `"env"` block in the JSON). Each call that changes the account (`place_trade`, `sell_trade`, `cancel_order`, `settle_open`) also needs `confirm: true`.

`get_orders`, `cancel_order` and limit prices on `place_trade` (`limit_price_cents`) arrived in 0.2.0. An older server has neither tool, and its `place_trade` ignores a limit price and buys at the live ask. If trading is on and an agent reports `get_orders` or `cancel_order` as an unknown tool, the server is older than 0.2.0. Update any copy you installed with npm, or change `arena-mcp-server` to `arena-mcp-server@latest` in the command, then restart your client.

### Option 3: the agent skill

[skills/arena-paper-trading/SKILL.md](skills/arena-paper-trading/SKILL.md) teaches an agent the CLI workflow: find a market, price it, confirm with you, then trade. For Claude Code, copy the folder into `~/.claude/skills/` (all your projects) or `.claude/skills/` (one project).

## What is in this repo

| Path | What it is |
|---|---|
| [AGENTS.md](AGENTS.md) | Instructions an AI coding agent follows when it uses the Arena CLI for you. |
| [skills/arena-paper-trading/SKILL.md](skills/arena-paper-trading/SKILL.md) | The same workflow as an agent skill. |
| [examples/daily-review/](examples/daily-review/) | A read-only script that prints your balance, positions and resting orders as one JSON document, plus a prompt that turns it into a review. |
| [examples/limit-at-the-bid/](examples/limit-at-the-bid/) | A script that prices a limit buy at the current bid. It is a dry run unless you pass `--place`. |
| [examples/agent-prompts.md](examples/agent-prompts.md) | Prompts to paste into Claude Code, Cursor or any agent that has the CLI or the MCP server. |
| [.mcp.json](.mcp.json) | A read-only MCP server config you can copy. |
| [server.json](server.json) | The server's entry for the official MCP registry. |
| [llms.txt](llms.txt) | A copy of https://arena-predictions.com/llms.txt. The live file is the one to trust. |

## Docs

- CLI: https://arena-predictions.com/docs/cli
- MCP server: https://arena-predictions.com/docs/mcp
- For language models: https://arena-predictions.com/llms.txt
- Paste-in agent prompt: https://arena-predictions.com/agent.txt
- Help and bug reports: https://arena-predictions.com/support

## Packages

| npm package | What it is |
|---|---|
| [arena-prediction-cli](https://www.npmjs.com/package/arena-prediction-cli) | The `arena` command. |
| [arena-mcp-server](https://www.npmjs.com/package/arena-mcp-server) | The local stdio MCP server. |

This repository holds documentation and examples only. See [NOTICE](NOTICE) for how you may use them.
