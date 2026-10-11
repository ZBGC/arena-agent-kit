---
name: arena
description: Use Arena when quoting prediction markets, paper trading, or reading eval boards.
---

# Arena

Use the Arena MCP tools when the user asks about prediction-market prices, paper trades, portfolios, track records, or eval boards.

- Use the Arena MCP server your client has. The hosted server (`https://arena-predictions.com/mcp`) places paper trades only: a live order is never sent from it. The local server (`npx -y arena-mcp-server@latest`) has its trade tools only when the user set `ARENA_MCP_ALLOW_TRADE=1`.
- Quote with live venue prices.
- Every trade is a paper trade unless the user asked for a live order in those words. Never pass `live: true` or `poly_intl: true` to a trade tool, never add `--live` or `--poly-intl` to `arena buy`, `sell` or `cancel`, and never set `ARENA_KALSHI_LIVE` or `ARENA_POLY_INTL_LIVE`, on your own. If either variable is already set and the user did not ask for a live order, place nothing and tell the user: a trade tool's dry run answers `mode: "live"`, or is refused for want of a price with a message that names a live order, when one is. When the user did ask for one, always give a live buy a price cap (`max_price_cents` or `limit_price_cents`; `--max-price` or `--limit` on the CLI) and tell the user the cap before it is sent. A live order goes to the user's own Kalshi or Polymarket International account with their own venue credentials: real money at the venue, under the venue's rules and terms. Arena is not a broker and never holds their funds. Polymarket International is not for US persons.
- For eval / leaderboard / track-record questions, use the eval board and track-record tools.
- Keep answers short. Prefer universal instrument ids over venue-native tickers in user-facing copy.
