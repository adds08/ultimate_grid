// Snapshots the example screen sources and the repo docs into assets/ so the
// showcase site can load them at runtime via rootBundle.
//
//   dart run tool/sync_assets.dart
//
// Run this before `flutter build web`. It guarantees the code shown in a
// CodePanel is byte-identical to the code that compiled into the app, and that
// the Docs section renders the real repo markdown (one authored copy in docs/).
import 'dart:io';

void main() {
  final here = Directory.current.path;
  final srcDir = Directory('$here/lib/screens');
  final docsDir = Directory('$here/../docs');

  final outSource = Directory('$here/assets/source/screens')
    ..createSync(recursive: true);
  final outDocs = Directory('$here/assets/docs')..createSync(recursive: true);

  // Copy every example screen .dart file verbatim.
  var copiedSrc = 0;
  for (final f in srcDir.listSync()) {
    if (f is File && f.path.endsWith('.dart')) {
      final name = f.uri.pathSegments.last;
      f.copySync('${outSource.path}/$name');
      copiedSrc++;
    }
  }

  // Copy every markdown file from the repo docs/ folder (if present).
  final docNames = <String>[];
  if (docsDir.existsSync()) {
    for (final f in docsDir.listSync()) {
      if (f is File && f.path.endsWith('.md')) {
        final name = f.uri.pathSegments.last;
        f.copySync('${outDocs.path}/$name');
        docNames.add(name);
      }
    }
  }
  docNames.sort();

  // Write a manifest the app reads to discover whatever docs exist.
  File(
    '${outDocs.path}/_manifest.json',
  ).writeAsStringSync('[${docNames.map((n) => '"$n"').join(',')}]');

  stdout.writeln('Synced $copiedSrc source files and ${docNames.length} docs.');
}
