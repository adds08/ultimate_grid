import 'package:flutter/material.dart';
import 'package:ultimate_grid/ultimate_grid.dart';

class HelpBanner extends StatelessWidget {
  final String text;
  const HelpBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFFED7AA)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates,
              size: 14, color: Color(0xFFEA580C)),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class HeaderLabel extends StatelessWidget {
  final GridController controller;
  final ColId colId;
  const HeaderLabel({
    super.key,
    required this.controller,
    required this.colId,
  });

  @override
  Widget build(BuildContext context) {
    final spec = controller.schema.column(colId);
    final sortKey =
        controller.sortKeys.where((k) => k.col == colId).firstOrNull;
    final hasFilter = controller.filters.containsKey(colId);
    final isNumber = spec?.kind == CellKind.number;
    final label = Text(
      spec?.header ?? colId,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF64748B),
        letterSpacing: 1,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: isNumber ? TextAlign.right : TextAlign.left,
    );
    return Row(
      mainAxisAlignment:
          isNumber ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Expanded(child: label),
        if (hasFilter)
          const Icon(Icons.filter_alt, size: 13, color: Color(0xFFEA580C)),
        if (sortKey != null)
          Icon(
            sortKey.direction == SortDirection.ascending
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            size: 12,
            color: const Color(0xFFEA580C),
          ),
        const Icon(Icons.more_vert, size: 13, color: Color(0xFF94A3B8)),
      ],
    );
  }
}
