import 'package:flutter/widgets.dart';

import '../model/cell_value.dart';
import '../model/column_spec.dart';
import 'cell_renderer.dart';

class NumberCellRenderer extends CellRenderer {
  final int decimals;
  final String emptyPlaceholder;
  const NumberCellRenderer({this.decimals = 2, this.emptyPlaceholder = ''});

  @override
  Widget build(BuildContext context, CellValue value, CellRenderContext ctx) {
    final text = switch (value) {
      EmptyCell() => emptyPlaceholder,
      NumberCell(value: final v) when v == v.roundToDouble() =>
        v.toStringAsFixed(0),
      NumberCell(value: final v) => v.toStringAsFixed(decimals),
      _ => value.toString(),
    };
    return Padding(
      padding: ctx.padding,
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: ctx.textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class TextCellRenderer extends CellRenderer {
  const TextCellRenderer();
  @override
  Widget build(BuildContext context, CellValue value, CellRenderContext ctx) {
    return Padding(
      padding: ctx.padding,
      child: Align(
        alignment: ctx.textAlign == TextAlign.right
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Text(
          value is EmptyCell ? '' : value.toString(),
          style: ctx.textStyle,
          textAlign: ctx.textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class BoolCellRenderer extends CellRenderer {
  const BoolCellRenderer();
  @override
  Widget build(BuildContext context, CellValue value, CellRenderContext ctx) {
    final on = value is BoolCell && value.value;
    return Center(
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          border: Border.all(color: ctx.theme.thickLine, width: 1.2),
          color: on ? ctx.theme.selectionStroke : ctx.theme.background,
          borderRadius: BorderRadius.circular(2),
        ),
        alignment: Alignment.center,
        child: on
            ? const Text(
                '✓',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFFFFFFF),
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
    );
  }
}

class DateCellRenderer extends CellRenderer {
  const DateCellRenderer();
  @override
  Widget build(BuildContext context, CellValue value, CellRenderContext ctx) {
    final text = value is DateCell
        ? _isoDate(value.value)
        : (value is EmptyCell ? '' : value.toString());
    return Padding(
      padding: ctx.padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: ctx.textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  static String _isoDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}

/// Convenience: install the standard set of default renderers onto a registry.
void registerDefaultRenderers(CellRendererRegistry registry) {
  registry.registerKind(CellKind.number, const NumberCellRenderer());
  registry.registerKind(CellKind.text, const TextCellRenderer());
  registry.registerKind(CellKind.bool_, const BoolCellRenderer());
  registry.registerKind(CellKind.date, const DateCellRenderer());
}
