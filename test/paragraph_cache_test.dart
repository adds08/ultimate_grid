import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_grid/src/view/paragraph_cache.dart';

void main() {
  group('ParagraphCache', () {
    test(
      'returns identical painter on repeat lookup for same (text, style)',
      () {
        final cache = ParagraphCache(capacity: 4);
        const style = TextStyle(fontSize: 14, color: Color(0xFF000000));
        final a = cache.acquire(
          text: 'hello',
          style: style,
          align: TextAlign.left,
          maxWidth: 100,
        );
        final b = cache.acquire(
          text: 'hello',
          style: style,
          align: TextAlign.left,
          maxWidth: 100,
        );
        expect(identical(a, b), isTrue);
        expect(cache.length, 1);
      },
    );

    test('evicts oldest entry when capacity is exceeded', () {
      final cache = ParagraphCache(capacity: 2);
      const style = TextStyle(fontSize: 14, color: Color(0xFF000000));
      cache.acquire(
        text: 'a',
        style: style,
        align: TextAlign.left,
        maxWidth: 100,
      );
      cache.acquire(
        text: 'b',
        style: style,
        align: TextAlign.left,
        maxWidth: 100,
      );
      cache.acquire(
        text: 'c',
        style: style,
        align: TextAlign.left,
        maxWidth: 100,
      );
      expect(cache.length, 2);
    });

    test('clear() releases all entries', () {
      final cache = ParagraphCache(capacity: 4);
      const style = TextStyle(fontSize: 14, color: Color(0xFF000000));
      cache.acquire(
        text: 'x',
        style: style,
        align: TextAlign.left,
        maxWidth: 100,
      );
      cache.clear();
      expect(cache.length, 0);
    });
  });
}
