import 'package:meta/meta.dart';

import 'cell_address.dart';
import 'freeze.dart';

@immutable
class RowSpec {
  final RowId id;
  final double defaultHeight;
  final FrozenSide? defaultFrozen;
  final int defaultFreezePriority;

  const RowSpec({
    required this.id,
    this.defaultHeight = 44,
    this.defaultFrozen,
    this.defaultFreezePriority = 0,
  });
}
