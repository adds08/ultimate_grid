# ultimate_grid — minimal example

The smallest runnable shape of `ultimate_grid`: a schema, an in-memory
`MapGridDataSource`, a `GridController`, and an `UltimateTable`. Drop
into a Flutter app and it renders a 60-row × 4-column inventory grid
with the SKU column frozen on the left.

```bash
cd example
flutter run
```

For more elaborate usage (timesheets, budgets, async data, 5M-row
stress test) see the example app in the host repo at
[`flutter_grid_package`](https://github.com/adds08/flutter_grid_package).
