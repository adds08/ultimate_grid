import 'package:flutter/widgets.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

/// Named [GridTheme] preset surfaced in the example app's theme picker.
enum DemoTheme { raw, elegant, professional }

/// A swatch the example's color picker shows alongside each theme. The
/// chosen swatch overrides the accent (selection + focus stroke + soft
/// frozen-strip background) of the active preset, so a user can spin up
/// "Professional + green" or "Elegant + purple" without writing code.
class AccentSwatch {
  final String label;
  final Color color;
  const AccentSwatch(this.label, this.color);
}

const accentSwatches = <AccentSwatch>[
  AccentSwatch('Orange', Color(0xFFEA580C)),
  AccentSwatch('Blue', Color(0xFF2563EB)),
  AccentSwatch('Green', Color(0xFF10B981)),
  AccentSwatch('Purple', Color(0xFF7C3AED)),
  AccentSwatch('Pink', Color(0xFFDB2777)),
  AccentSwatch('Slate', Color(0xFF475569)),
];

/// Returns the named preset, then folds the accent color into the
/// selection / focus strokes + soft frozen-strip background so the swap
/// reads as "same layout, different brand color".
GridTheme themeFor(DemoTheme name, {Color? accent}) {
  final base = switch (name) {
    DemoTheme.raw => _raw,
    DemoTheme.elegant => _elegant,
    DemoTheme.professional => _professional,
  };
  if (accent == null) return base;
  return _withAccent(base, accent);
}

/// Bare grayscale theme — the package surface with all decoration removed.
/// Useful for "what does the package give me out of the box if I supply
/// nothing extra" comparisons.
const _raw = GridTheme(
  background: Color(0xFFFFFFFF),
  headerBackground: Color(0xFFFAFAFA),
  frozenStripBackground: Color(0xFFFAFAFA),
  footerBackground: Color(0xFFFAFAFA),
  rowBanding: Color(0x00000000),
  hoverHighlight: Color(0x0A000000),
  selectionFill: Color(0x14000000),
  selectionStroke: Color(0xFF111111),
  focusStroke: Color(0xFF111111),
  gridLine: Color(0xFFE5E5E5),
  thickLine: Color(0xFFBFBFBF),
  headerTextStyle: TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xFF6B7280),
    letterSpacing: 1,
    height: 1.2,
  ),
  bodyTextStyle: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFF111111),
    height: 1.3,
  ),
  bodyNumericStyle: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFF111111),
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.3,
  ),
  mutedTextStyle: TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6B7280),
    height: 1.3,
  ),
  cellPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  gridLineWidth: 1,
  thickLineWidth: 2,
);

/// The orange-and-cream Mark 85 look. Mirrors the package's
/// [GridTheme.mark85] default — kept here so the picker can present it
/// as a named choice alongside the others.
const _elegant = GridTheme.mark85;

/// Blue / slate corporate palette. Tabular and quiet, with a brand-blue
/// selection accent.
const _professional = GridTheme(
  background: Color(0xFFFFFFFF),
  headerBackground: Color(0xFFF8FAFC),
  frozenStripBackground: Color(0xFFEFF6FF),
  footerBackground: Color(0xFFF8FAFC),
  rowBanding: Color(0x06000000),
  hoverHighlight: Color(0x0F2563EB),
  selectionFill: Color(0x142563EB),
  selectionStroke: Color(0xFF2563EB),
  focusStroke: Color(0xFF2563EB),
  gridLine: Color(0xFFE2E8F0),
  thickLine: Color(0xFFCBD5E1),
  headerTextStyle: TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: Color(0xFF334155),
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
    fontWeight: FontWeight.w500,
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
  cellPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
  gridLineWidth: 1,
  thickLineWidth: 2,
);

GridTheme _withAccent(GridTheme base, Color accent) {
  return GridTheme(
    background: base.background,
    headerBackground: base.headerBackground,
    // 8% tint of the accent over the existing frozen-strip background.
    frozenStripBackground: Color.alphaBlend(
      accent.withValues(alpha: 0.08),
      base.background,
    ),
    footerBackground: base.footerBackground,
    rowBanding: base.rowBanding,
    hoverHighlight: base.hoverHighlight,
    selectionFill: accent.withValues(alpha: 0.08),
    selectionStroke: accent,
    focusStroke: accent,
    gridLine: base.gridLine,
    thickLine: base.thickLine,
    headerTextStyle: base.headerTextStyle,
    bodyTextStyle: base.bodyTextStyle,
    bodyNumericStyle: base.bodyNumericStyle,
    mutedTextStyle: base.mutedTextStyle,
    cellPadding: base.cellPadding,
    gridLineWidth: base.gridLineWidth,
    thickLineWidth: base.thickLineWidth,
  );
}
