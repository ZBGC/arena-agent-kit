# Cursor plugin (Arena)

This repo includes a Cursor plugin scaffold:

- `.cursor-plugin/plugin.json` — plugin name `arena` (Arena Predictions brand only)
- `mcp.json` — hosted MCP at `https://arena-predictions.com/mcp`
- `skills/arena/SKILL.md` — when to use Arena (quotes, paper trading, eval boards)
- `assets/logo.png` — logo placeholder (site icon)

Cursor reads root `mcp.json`. Other tools may use `.mcp.json` (the local npx server in this repo); that file is unchanged.

Marketplace submission is a separate step and is not done from this commit.
