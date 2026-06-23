import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ultimate_grid_example/main.dart';
import 'package:ultimate_grid_example/site/site_shell.dart';

/// Runtime smoke test for the showcase site. A passing `flutter build web`
/// only proves the app compiles; this boots the real GoRouter app and drives
/// every route, asserting no exception is thrown while each page builds and
/// renders (route wiring, live-grid construction, markdown + CodePanel asset
/// loads). Catches runtime regressions a build can't.
void main() {
  // Let async asset loads (CodePanel source, docs markdown) settle.
  Future<void> tick(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('Home boots and renders without exceptions', (tester) async {
    await tester.pumpWidget(const ShowcaseApp());
    await tick(tester);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Ultimate Grid'), findsWidgets);
  });

  testWidgets('every route builds without throwing', (tester) async {
    await tester.pumpWidget(const ShowcaseApp());
    await tick(tester);
    expect(tester.takeException(), isNull, reason: '/ threw on boot');

    // The shell persists across routes, so its element always carries the
    // GoRouter ancestor we navigate with.
    final ctx = tester.element(find.byType(SiteShell));

    const routes = <String>[
      '/examples',
      '/examples/inventory', // a light live grid
      '/examples/datagrid',
      '/examples/planned-csv-export', // a "planned" (no live grid) page
      '/docs',
      '/docs/getting-started',
      '/docs/theming',
      '/roadmap',
      '/',
    ];

    for (final path in routes) {
      GoRouter.of(ctx).go(path);
      await tick(tester);
      expect(
        tester.takeException(),
        isNull,
        reason: 'route "$path" threw while building/rendering',
      );
    }
  });
}
