/// Ultimate Table by CodeBigya — a scalable, themable 2D data-grid for Flutter.
///
/// Core library — depends only on `flutter/widgets.dart`, no Material/Cupertino.
///
/// For the built-in Material column menu and search field, import
/// `package:ultimate_grid/ultimate_grid_material.dart` separately.
library;

export 'src/model/cell_address.dart';
export 'src/model/cell_value.dart';
export 'src/model/column_spec.dart' show ColumnSpec, CellKind;
export 'src/model/row_spec.dart';
export 'src/model/schema.dart';
export 'src/model/freeze.dart';
export 'src/model/merge.dart';

export 'src/source/grid_data_source.dart';
export 'src/source/async_grid_data_source.dart';

export 'src/interaction/policy.dart';

export 'src/controller/clipboard.dart' show GridClipboard;
export 'src/controller/selection.dart';
export 'src/controller/column_layout.dart';
export 'src/controller/row_layout.dart';
export 'src/controller/merge_index.dart' show MergeIndex;
export 'src/controller/grid_controller.dart';

export 'src/filter_sort/filters.dart';
export 'src/filter_sort/view_pipeline.dart';

export 'src/theme/grid_theme.dart';
export 'src/cells/cell_renderer.dart';
export 'src/cells/default_renderers.dart';
export 'src/view/paragraph_cache.dart' show ParagraphCache;
export 'src/view/render_body.dart' show BodyCellHit, UltimateBody;
export 'src/view/resizable_header.dart';
export 'src/view/ultimate_table.dart';
