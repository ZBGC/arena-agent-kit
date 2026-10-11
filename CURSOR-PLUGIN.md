# Cursor plugin (Arena)

This repo includes a Cursor plugin scaffold:

- `.cursor-plugin/plugin.json`: plugin name `arena` (Arena Predictions brand only)
- `mcp.json`: hosted MCP at `https://arena-predictions.com/mcp`
- `skills/arena/SKILL.md`: the short skill, when to use Arena (quotes, paper trading, eval boards)
- `skills/arena-paper-trading/SKILL.md`: the long skill, the paper trading workflow with the safety rules first
- `assets/logo.png`: logo placeholder (site icon)

Cursor reads root `mcp.json`. Other tools may use `.mcp.json`, the local npx server in this repo.

The plugin is not submitted to a marketplace.

The plugin's `version` is the kit's number, the same in `.claude-plugin/plugin.json` and `gemini-extension.json`. A change to anything the plugin ships bumps all three together: see Releasing a change in the [README](README.md).
