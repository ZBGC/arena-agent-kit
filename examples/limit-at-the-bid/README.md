# Limit buy at the bid

`limit-at-the-bid.sh` reads a market, takes the current bid for the side you choose, and prices a limit buy at that price. **It is a dry run by default:** it prints the order and places nothing. Add `--place` to place the paper order.

The script never sends a live order. From CLI 0.6.0 an order is live with the CLI's `--live` or `--poly-intl`, or while `ARENA_KALSHI_LIVE` or `ARENA_POLY_INTL_LIVE` is set to 1, true or on, and it goes to your own Kalshi or Polymarket International account with your own venue credentials: real money at the venue, under the venue's rules and terms. Arena is not a broker and never holds your funds. The script passes neither flag, and it clears `ARENA_KALSHI_LIVE` and `ARENA_POLY_INTL_LIVE` for its own commands.

```bash
./limit-at-the-bid.sh <ticker> <yes|no> <contracts> [--tif gtc|ioc|fok] [--expires 30m|4h|2d|ISO-time] [--place]
```

Find a ticker first with `arena markets --league NFL` or `arena search "<city>"`.

## What it runs

1. `arena market <ticker> --json` to read the market's status and the bid for your side. This is read-only. It needs `arena login`: signed out, the script stops with exit 4.
2. `arena buy <ticker> --side <side> --contracts <n> --limit <bid> --dry-run --json`, which prices the order and places nothing.
3. With `--place`, the same command with `--yes` instead of `--dry-run`. This places a paper order on your account and needs an Arena Basic membership.

The script prints what it is doing on stderr and the CLI's JSON on stdout. It stops with exit 6 if the market is not open or the side has no bid.

## Why buy at the bid

A market buy pays the ask. A limit buy at the bid does not cross the spread, so if it fills, you save the spread. The trade-off is that it may never fill: it waits until a seller comes down to your price.

- With the default `--tif gtc`, the order usually rests. While it rests, it holds contracts x bid / 100 paper dollars out of your balance.
- `--expires 4h` makes a resting order stop after four hours and return its hold.
- `--tif ioc` or `--tif fok` fill now or cancel. At the bid that usually means cancelled, because nobody is selling at that price yet.

After placing, `arena orders` shows the resting order and `arena cancel <order-id> --yes` withdraws it and returns the hold in full.

## Example output (dry run)

```json
{
  "quote": {
    "ticker": "<ticker>",
    "side": "yes",
    "contracts": 10,
    "limitPriceCents": 41,
    "timeInForce": "gtc",
    "expiresAt": null,
    "holdDollars": 4.1,
    "dryRun": true,
    "placed": false
  }
}
```

The example is shortened. From CLI 0.6.0 the quote also says what the order pays if it wins and the most it can lose (`payoutDollars`, `maxLossDollars`), and `help` holds the command that places the order, then `arena orders`.

With `--place`, the JSON receipt is `{ receipt, order, trade? }` from CLI 0.5.0 (before 0.5.0 it was `{ status, order, ... }`). `receipt.status` says what happened: `executed` (filled now; `order.trade_id` is the new position), `resting` (waiting; `order.hold_dollars` is held until it fills, and `order.expires_at` is when it stops) or `canceled` (did not fill, nothing held; `order.cancel_reason` says why). `order.id` is what `arena cancel` takes.
