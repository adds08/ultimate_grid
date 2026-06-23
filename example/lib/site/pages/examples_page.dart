import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../catalog.dart';
import '../code_panel.dart';
import '../grid_theme_controller.dart';
import '../site_shell.dart';
import '../theme_toolbar.dart';

const _kMobileWidth = 380.0;

/// Examples section: a categorized left nav + a right pane that is either the
/// gallery overview (`/examples`) or a single example page (`/examples/:id`).
class ExamplesPage extends StatelessWidget {
  /// Selected example id, or null for the gallery overview.
  final String? id;
  const ExamplesPage({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 860;
    final entry = id == null ? null : exampleById(id!);

    final content = entry == null
        ? (id == null ? const _GalleryOverview() : _NotFound(id: id!))
        : _ExampleDetail(entry: entry);

    if (compact) {
      return Column(
        children: [
          _CategoryDropdown(selectedId: id),
          const Divider(height: 1, color: kBorder),
          Expanded(child: content),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 260, child: _CategoryNav(selectedId: id)),
        const VerticalDivider(width: 1, color: kBorder),
        Expanded(child: content),
      ],
    );
  }
}

class _CategoryNav extends StatelessWidget {
  final String? selectedId;
  const _CategoryNav({required this.selectedId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFBF5),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          for (final cat in exampleCategories) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  Icon(cat.icon, size: 14, color: kMuted),
                  const SizedBox(width: 8),
                  Text(
                    cat.title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            for (final e in cat.entries)
              _NavRow(
                entry: e,
                active: e.id == selectedId,
                onTap: () => context.go('/examples/${e.id}'),
              ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final ExampleEntry entry;
  final bool active;
  final VoidCallback onTap;
  const _NavRow({
    required this.entry,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final planned = entry.isPlanned;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: active ? const Color(0xFFFFF7ED) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  planned ? Icons.event_outlined : entry.icon,
                  size: 17,
                  color: active
                      ? kBrandOrange
                      : (planned ? const Color(0xFFB0B7C3) : kMuted),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? kBrandOrange
                          : (planned ? const Color(0xFF94A3B8) : kInk),
                    ),
                  ),
                ),
                if (planned) const Text('🗓️', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String? selectedId;
  const _CategoryDropdown({required this.selectedId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFBF5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.menu_open, size: 18, color: kMuted),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              value: selectedId,
              hint: const Text('Browse examples'),
              underline: const SizedBox.shrink(),
              items: [
                for (final cat in exampleCategories) ...[
                  DropdownMenuItem<String>(
                    enabled: false,
                    child: Text(
                      cat.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                  for (final e in cat.entries)
                    DropdownMenuItem<String>(
                      value: e.id,
                      child: Text('   ${e.title}${e.isPlanned ? '  🗓️' : ''}'),
                    ),
                ],
              ],
              onChanged: (v) {
                if (v != null) context.go('/examples/$v');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryOverview extends StatelessWidget {
  const _GalleryOverview();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width < 720
        ? 1
        : width < 1100
        ? 2
        : 3;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Examples',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Live, interactive grids — each with its exact, '
                  'copy-pasteable source. Pick one from the left, or start '
                  'with a card below.',
                  style: TextStyle(fontSize: 15, color: kMuted, height: 1.5),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.85,
                  children: [
                    for (final e in liveExamples)
                      _OverviewCard(
                        entry: e,
                        onTap: () => context.go('/examples/${e.id}'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final ExampleEntry entry;
  final VoidCallback onTap;
  const _OverviewCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(entry.icon, size: 22, color: kBrandOrange),
              const SizedBox(height: 10),
              Text(
                entry.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kInk,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  entry.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: kMuted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExampleDetail extends StatelessWidget {
  final ExampleEntry entry;
  const _ExampleDetail({required this.entry});

  @override
  Widget build(BuildContext context) {
    final category = categoryOf(entry);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _crumb(context, 'Examples', '/examples'),
                    const _CrumbSep(),
                    Text(
                      category.title,
                      style: const TextStyle(fontSize: 13, color: kMuted),
                    ),
                    const _CrumbSep(),
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kInk,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(entry.icon, size: 26, color: kBrandOrange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: kInk,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  entry.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: kMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                _Highlights(items: entry.highlights),
                const SizedBox(height: 24),
                if (entry.isPlanned)
                  _PlannedNotice()
                else ...[
                  const _SectionLabel('Live demo'),
                  const SizedBox(height: 8),
                  const ThemeToolbar(),
                  const SizedBox(height: 12),
                  _LiveGrid(entry: entry),
                  const SizedBox(height: 28),
                  const _SectionLabel('Source'),
                  const SizedBox(height: 8),
                  CodePanel(
                    assetPath: entry.sourceAsset!,
                    label: entry.sourceLabel,
                    region: entry.region,
                  ),
                ],
                if (entry.seeAlso.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  const _SectionLabel('See also'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final id in entry.seeAlso)
                        if (exampleById(id) case final e?)
                          ActionChip(
                            avatar: Icon(e.icon, size: 16),
                            label: Text(e.title),
                            onPressed: () => context.go('/examples/${e.id}'),
                          ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _crumb(BuildContext context, String label, String route) {
    return InkWell(
      onTap: () => context.go(route),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: kBrandOrange,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CrumbSep extends StatelessWidget {
  const _CrumbSep();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Icon(Icons.chevron_right, size: 16, color: kMuted),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: kInk,
    ),
  );
}

class _Highlights extends StatelessWidget {
  final List<String> items;
  const _Highlights({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCE7D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What this shows',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 8),
          for (final h in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: kBrandOrange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      h,
                      style: const TextStyle(
                        fontSize: 14,
                        color: kInk,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlannedNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🗓️', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Planned — not yet built',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'This is a roadmap item. There is no live demo yet. Track its '
            'status on the Roadmap.',
            style: TextStyle(fontSize: 14, color: kMuted, height: 1.4),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => context.go('/roadmap'),
            icon: const Icon(Icons.map_outlined, size: 16),
            label: const Text('View Roadmap'),
          ),
        ],
      ),
    );
  }
}

/// Hosts the live grid, re-keyed on theme change, optionally framed as a
/// phone-width preview.
class _LiveGrid extends StatelessWidget {
  final ExampleEntry entry;
  const _LiveGrid({required this.entry});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: gridThemeController,
      builder: (context, _) {
        final c = gridThemeController;
        final grid = KeyedSubtree(
          key: ValueKey('${entry.id}:${c.token}'),
          child: entry.build!(c.theme),
        );

        final framed = c.mobilePreview
            ? Center(
                child: Container(
                  width: _kMobileWidth,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(height: 560, child: grid),
                ),
              )
            : SizedBox(height: 560, child: grid);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: framed,
        );
      },
    );
  }
}

class _NotFound extends StatelessWidget {
  final String id;
  const _NotFound({required this.id});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 40, color: kMuted),
          const SizedBox(height: 12),
          Text('No example "$id".', style: const TextStyle(color: kMuted)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/examples'),
            child: const Text('Back to examples'),
          ),
        ],
      ),
    );
  }
}
