import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'site/pages/docs_page.dart';
import 'site/pages/examples_page.dart';
import 'site/pages/home_page.dart';
import 'site/pages/roadmap_page.dart';
import 'site/site_shell.dart';

void main() => runApp(const ShowcaseApp());

/// The ultimate_grid showcase site — a bootstrap-table-style marketing Home,
/// a Docs section, an Examples gallery, and a Roadmap, all deep-linkable.
class ShowcaseApp extends StatelessWidget {
  const ShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ultimate Grid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: kBrandOrange,
        scaffoldBackgroundColor: kBg,
      ),
      routerConfig: _router,
    );
  }
}

/// A quick cross-fade between pages — the default push transition flashes/
/// slides oddly on web, so every route uses this instead.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 160),
    reverseTransitionDuration: const Duration(milliseconds: 120),
    child: child,
    transitionsBuilder: (context, animation, secondary, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

final _router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => SiteShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => _fade(state, const HomePage()),
        ),
        GoRoute(
          path: '/examples',
          pageBuilder: (context, state) => _fade(state, const ExamplesPage()),
          routes: [
            GoRoute(
              path: ':id',
              pageBuilder: (context, state) =>
                  _fade(state, ExamplesPage(id: state.pathParameters['id'])),
            ),
          ],
        ),
        GoRoute(
          path: '/docs',
          pageBuilder: (context, state) => _fade(state, const DocsPage()),
          routes: [
            GoRoute(
              path: ':page',
              pageBuilder: (context, state) =>
                  _fade(state, DocsPage(page: state.pathParameters['page'])),
            ),
          ],
        ),
        GoRoute(
          path: '/roadmap',
          pageBuilder: (context, state) => _fade(state, const RoadmapPage()),
        ),
      ],
    ),
  ],
);
