# ultimate_grid — example gallery

A home menu launches each demo. Shipped so far:

1. **Inventory (minimal)** — schema + `MapGridDataSource` + `GridController`
   + `UltimateTable`. The smallest runnable shape, with SKU frozen left
   and Margin % frozen right.
2. **Financial sheet (merges + freeze)** — quarter header strip merged
   across months via `MergeRange`; top + bottom-frozen header / totals
   rows; left-frozen region column; right-frozen `TOTAL` column.
3. **Async paging (100k rows)** — `AsyncGridDataSource` fetching pages of
   50 on demand with a simulated network latency. Scroll fast to see
   "Loading…" placeholders flash before pages resolve. Drop-down adjusts
   the simulated latency.

```bash
cd example
flutter run
```

For the broader gallery (timesheets, budgets, 5M-row stress test) see
the host repo at
[`flutter_grid_package`](https://github.com/adds08/flutter_grid_package).
