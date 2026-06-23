import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../catalog.dart';
import '../code_panel.dart';
import '../links.dart';
import '../site_shell.dart';

/// Marketing landing page: hero, badges, benefit chips, CTAs, a feature-card
/// grid linking into examples, and an Install section.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                _Hero(),
                SizedBox(height: 48),
                _FeatureGridSection(),
                SizedBox(height: 48),
                _InstallSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Ultimate Grid',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w900,
            color: kInk,
            letterSpacing: -1.5,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: const Text(
            'A scalable, themable 2D data-grid for Flutter — millions of cells '
            'without jitter, a 9-region freeze layout, cell merges, async data, '
            'Excel-style selection, sort / filter / search, and full theming.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: kMuted, height: 1.5),
          ),
        ),
        const SizedBox(height: 24),
        // Badges (shields.io — load over network).
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _Badge(url: Links.badgePubVersion, onTap: Links.pubDev),
            _Badge(url: Links.badgePubPoints, onTap: Links.pubDev),
            _Badge(url: Links.badgePubLikes, onTap: Links.pubDev),
            _Badge(url: Links.badgeGithubStars, onTap: Links.githubStars),
            _Badge(url: Links.badgeLicense, onTap: Links.github),
          ],
        ),
        const SizedBox(height: 24),
        // Benefit chips.
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            _Chip(icon: Icons.dataset_outlined, label: '5M rows'),
            _Chip(icon: Icons.view_quilt_outlined, label: '9-region freeze'),
            _Chip(
              icon: Icons.brush_outlined,
              label: 'Zero widget-per-cell paint',
            ),
            _Chip(icon: Icons.widgets_outlined, label: 'Framework-agnostic'),
          ],
        ),
        const SizedBox(height: 32),
        // CTAs.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => context.go('/examples'),
              icon: const Icon(Icons.grid_view_rounded, size: 18),
              label: const Text('View Examples'),
              style: FilledButton.styleFrom(
                backgroundColor: kBrandOrange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/docs'),
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('Get Started'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kInk,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => openExternal(Links.pubDev),
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              label: const Text('pub.dev'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kInk,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => openExternal(Links.github),
              icon: const Icon(Icons.code, size: 18),
              label: const Text('GitHub'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kInk,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String url;
  final String onTap;
  const _Badge({required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openExternal(onTap),
      child: Image.network(
        url,
        height: 20,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kBrandOrange),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureGridSection extends StatelessWidget {
  const _FeatureGridSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width < 640
        ? 1
        : width < 980
        ? 2
        : 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore the grid',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: kInk,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Every card is a live, interactive example with copy-pasteable '
          'source.',
          style: TextStyle(fontSize: 15, color: kMuted),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.9,
          children: [
            for (final e in liveExamples)
              _FeatureCard(
                icon: e.icon,
                title: e.title,
                body: e.description,
                onTap: () => context.go('/examples/${e.id}'),
              ),
          ],
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 19, color: kBrandOrange),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kInk,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
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

class _InstallSection extends StatelessWidget {
  const _InstallSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Install',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: kInk,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Add the dependency, import the barrel, and wire a controller.',
          style: TextStyle(fontSize: 15, color: kMuted),
        ),
        const SizedBox(height: 16),
        const CodePanel(
          assetPath: 'assets/snippets/install.yaml',
          label: 'pubspec.yaml',
          language: 'yaml',
        ),
        const SizedBox(height: 16),
        const CodePanel(
          assetPath: 'assets/snippets/quickstart.dart',
          label: 'Quick start',
          language: 'dart',
          region: 'core-setup',
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => context.go('/examples'),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Browse all examples'),
            style: FilledButton.styleFrom(
              backgroundColor: kBrandOrange,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
