import 'package:flutter/material.dart';

import '../screens/_themes.dart';
import 'grid_theme_controller.dart';

/// The Raw/Elegant/Professional dropdown + accent swatches + mobile-preview
/// toggle, driving the shared [gridThemeController]. Shown above live grids on
/// example pages so visitors can restyle the demo.
class ThemeToolbar extends StatelessWidget {
  const ThemeToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: gridThemeController,
      builder: (context, _) {
        final c = gridThemeController;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFCE7D5)),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Theme',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
              DropdownButton<DemoTheme>(
                value: c.themeName,
                isDense: true,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.expand_more, size: 16),
                items: const [
                  DropdownMenuItem(value: DemoTheme.raw, child: Text('Raw')),
                  DropdownMenuItem(
                    value: DemoTheme.elegant,
                    child: Text('Elegant'),
                  ),
                  DropdownMenuItem(
                    value: DemoTheme.professional,
                    child: Text('Professional'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) c.setTheme(v);
                },
              ),
              for (final s in accentSwatches)
                _AccentDot(
                  color: s.color,
                  label: s.label,
                  selected: c.accent?.toARGB32() == s.color.toARGB32(),
                  onTap: () => c.setAccent(
                    c.accent?.toARGB32() == s.color.toARGB32() ? null : s.color,
                  ),
                ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: c.toggleMobile,
                icon: Icon(
                  c.mobilePreview
                      ? Icons.desktop_windows_outlined
                      : Icons.smartphone_outlined,
                  size: 18,
                ),
                tooltip: c.mobilePreview
                    ? 'Exit mobile preview'
                    : 'Preview as mobile',
                visualDensity: VisualDensity.compact,
                color: c.mobilePreview ? const Color(0xFFEA580C) : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AccentDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _AccentDot({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: selected ? '$label (clear)' : label,
      child: InkResponse(
        onTap: onTap,
        radius: 14,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFE2E8F0),
                width: selected ? 2 : 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
