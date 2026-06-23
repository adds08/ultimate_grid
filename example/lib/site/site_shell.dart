import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'links.dart';

const kBrandOrange = Color(0xFFEA580C);
const kInk = Color(0xFF0F172A);
const kMuted = Color(0xFF64748B);
const kBg = Color(0xFFF8FAFC);
const kBorder = Color(0xFFE2E8F0);

/// Top-level chrome shared by every page: a sticky brand bar with primary
/// nav links and external links. Responsive — collapses to a menu button on
/// narrow widths.
class SiteShell extends StatelessWidget {
  final Widget child;
  const SiteShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: kBg,
      drawer: compact ? _NavDrawer(location: location) : null,
      body: SafeArea(
        child: Column(
          children: [
            _BrandBar(compact: compact, location: location),
            const Divider(height: 1, color: kBorder),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

const _navItems = <(String, String)>[
  ('Home', '/'),
  ('Examples', '/examples'),
  ('Docs', '/docs'),
  ('Roadmap', '/roadmap'),
];

bool _isActive(String location, String route) {
  if (route == '/') return location == '/';
  return location == route || location.startsWith('$route/');
}

class _BrandBar extends StatelessWidget {
  final bool compact;
  final String location;
  const _BrandBar({required this.compact, required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (compact)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, size: 22),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          InkWell(
            onTap: () => context.go('/'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: kBrandOrange,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.grid_view_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Ultimate Grid',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kInk,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (!compact) ...[
            for (final (label, route) in _navItems)
              _NavLink(
                label: label,
                active: _isActive(location, route),
                onTap: () => context.go(route),
              ),
            const SizedBox(width: 12),
            _IconLink(
              tooltip: 'pub.dev',
              icon: Icons.inventory_2_outlined,
              onTap: () => openExternal(Links.pubDev),
            ),
            _IconLink(
              tooltip: 'GitHub',
              icon: Icons.code,
              onTap: () => openExternal(Links.github),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavLink({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: active ? kBrandOrange : kInk,
          backgroundColor: active ? const Color(0xFFFFF7ED) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _IconLink extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  const _IconLink({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 20, color: kMuted),
      onPressed: onTap,
    );
  }
}

class _NavDrawer extends StatelessWidget {
  final String location;
  const _NavDrawer({required this.location});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final (label, route) in _navItems)
              ListTile(
                title: Text(label),
                selected: _isActive(location, route),
                selectedColor: kBrandOrange,
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(route);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('pub.dev'),
              onTap: () => openExternal(Links.pubDev),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('GitHub'),
              onTap: () => openExternal(Links.github),
            ),
          ],
        ),
      ),
    );
  }
}
