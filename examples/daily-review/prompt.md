# Daily review prompt

`daily-review.sh` prints a read-only snapshot of your Arena paper account as JSON: your balance, your open positions marked to live prices, and your resting limit orders. It never places, sells or cancels anything.

Run it yourself:

```bash
./examples/daily-review/daily-review.sh
```

Or paste this prompt into Claude Code, Cursor or another coding agent opened in this repo:

```text
Run ./examples/daily-review/daily-review.sh and read the JSON it prints. It is read-only.

Then give me a short review of my Arena paper account:
1. Spendable balance, net worth, and how much is held by resting orders.
2. Each open position: market, side, contracts, entry price, current mark and unrealized P&L.
3. Each resting limit order: market, side, limit price, contracts left, and when it expires.
4. At most three ideas, each written as an exact arena command. Write a buy or sell with
   --dry-run. Write a cancel as `arena cancel <order-id>` with no --dry-run and no --yes,
   because cancel has no --dry-run option.

Do not place, sell or cancel anything, and do not run any command with --yes.
If the script exits 4, tell me to run `arena login` and stop.
```

## What the JSON contains

| Key | Source | Notes |
|---|---|---|
| `generatedAt` | the script | UTC time of the snapshot |
| `balance` | `arena balance --json` | `dollars` (spendable), `openStakeDollars`, `heldOrderDollars`, `netWorthDollars`, `monthKey` |
| `positions` | `arena positions --live --json` | `positions[]` (each with `id`, `market_ticker`, `market_title`, `side`, `contracts`, `entry_price_cents`, `markPriceCents`, `unrealizedPnlDollars`), `openPositions`, `totalCount` |
| `restingOrders` | `arena orders --status resting --json` | one entry per resting limit order: `id`, `market_ticker`, `action`, `side`, `limit_price_cents`, `remaining_count`, `hold_dollars`, `expires_at` |

Money is paper dollars. Prices are whole cents from 1 to 99.
