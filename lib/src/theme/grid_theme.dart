import 'package:flutter/widgets.dart';

/// Static visual defaults for the grid. Per-column/row/cell overrides flow
/// through an `InteractionPolicy` of `ColumnStyle` / `RowStyle` / `CellStyle`
/// on the table widget — the theme is just the floor.
@immutable
class GridTheme {
  final Color background;
  final Color headerBackground;
  final Color frozenStripBackground;
  final Color footerBackground;
  final Color rowBanding; // alternating row tint; transparent disables
  final Color hoverHighlight;
  final Color selectionFill;
  final Color selectionStroke;
  final Color focusStroke;
  final Color gridLine;
  final Color thickLine;
  final TextStyle headerTextStyle;
  final TextStyle bodyTextStyle;
  final TextStyle bodyNumericStyle;
  final TextStyle mutedTextStyle;
  final EdgeInsets cellPadding;
  final double gridLineWidth;
  final double thickLineWidth;

  /// Whether to draw horizontal grid lines between rows. Defaults to true.
  final bool showHorizontalGridLines;

  /// Whether to draw vertical grid lines between columns. Defaults to true.
  final bool showVerticalGridLines;

  const GridTheme({
    required this.background,
    required this.headerBackground,
    required this.frozenStripBackground,
    required this.footerBackground,
    required this.rowBanding,
    required this.hoverHighlight,
    required this.selectionFill,
    required this.selectionStroke,
    required this.focusStroke,
    required this.gridLine,
    required this.thickLine,
    required this.headerTextStyle,
    required this.bodyTextStyle,
    required this.bodyNumericStyle,
    required this.mutedTextStyle,
    required this.cellPadding,
    required this.gridLineWidth,
    required this.thickLineWidth,
    this.showHorizontalGridLines = true,
    this.showVerticalGridLines = true,
  });

  /// Mark 85 — the default template the user is keeping for now.
  static const GridTheme mark85 = GridTheme(
    background: Color(0xFFFFFFFF),
    headerBackground: Color(0xFFF1F5F9),
    frozenStripBackground: Color(0xFFFFF7ED),
    footerBackground: Color(0xFFF1F5F9),
    rowBanding: Color(0x00000000),
    hoverHighlight: Color(0x0F0F172A),
    selectionFill: Color(0x14EA580C),
    selectionStroke: Color(0xFFEA580C),
    focusStroke: Color(0xFFEA580C),
    gridLine: Color(0xFFE2E8F0),
    thickLine: Color(0xFFCBD5E1),
    headerTextStyle: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Color(0xFF64748B),
      letterSpacing: 1,
      height: 1.2,
    ),
    bodyTextStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xFF0F172A),
      height: 1.3,
    ),
    bodyNumericStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xFF0F172A),
      fontFeatures: [FontFeature.tabularFigures()],
      height: 1.3,
    ),
    mutedTextStyle: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: Color(0xFF64748B),
      height: 1.3,
    ),
    cellPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    gridLineWidth: 1,
    thickLineWidth: 2,
  );
}

/// Style overrides at the column granularity.
@immutable
class ColumnStyle {
  final Color? background;
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  const ColumnStyle({this.background, this.textStyle, this.textAlign});
}

/// Style overrides at the row granularity.
@immutable
class RowStyle {
  final Color? background;
  final TextStyle? textStyle;
  const RowStyle({this.background, this.textStyle});
}

/// Style overrides at the cell granularity. Wins over row, which wins over
/// column, which wins over theme.
@immutable
class CellStyle {
  final Color? background;
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  const CellStyle({this.background, this.textStyle, this.textAlign});
}
