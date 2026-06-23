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

final _router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => SiteShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/examples',
          builder: (context, state) => const ExamplesPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) =>
                  ExamplesPage(id: state.pathParameters['id']),
            ),
          ],
        ),
        GoRoute(
          path: '/docs',
          builder: (context, state) => const DocsPage(),
          routes: [
            GoRoute(
              path: ':page',
              builder: (context, state) =>
                  DocsPage(page: state.pathParameters['page']),
            ),
          ],
        ),
        GoRoute(
          path: '/roadmap',
          builder: (context, state) => const RoadmapPage(),
        ),
      ],
    ),
  ],
);
