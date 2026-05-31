/// Material-dependent utilities for ultimate_grid.
///
/// Provides the built-in column menu (`showUltimateColumnMenu`), filter dialog
/// (`showUltimateFilterDialog`), and search field (`UltimateSearchField`) —
/// all of which depend on `flutter/material.dart`.
///
/// Apps using non-Material design systems (e.g., shadcn_flutter) can skip this
/// import and build their own column menu / filter UI using the core
/// `package:ultimate_grid/ultimate_grid.dart` API.
library;

export 'src/view/column_menu.dart'
    show showUltimateColumnMenu, showUltimateFilterDialog;
export 'src/view/search_field.dart';
