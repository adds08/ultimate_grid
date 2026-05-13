import 'package:flutter/widgets.dart';

import '../widgets/timesheet_grid.dart';

/// Wraps the Mark 85 timesheet so it lives alongside the other examples
/// in the unified shell. All the real logic is in `widgets/timesheet_grid.dart`.
class TimesheetExample extends StatelessWidget {
  const TimesheetExample({super.key});

  @override
  Widget build(BuildContext context) => const TimesheetGrid();
}
