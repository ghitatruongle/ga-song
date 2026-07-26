import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/utils/lazy_list.dart';

void main() {
  group('LazyList', () {
    late List<int> sourceData;
    late LazyList<int> lazyList;

    setUp(() {
      sourceData = List.generate(100, (i) => i);
      lazyList = LazyList<int>(
        loader: (offset, limit) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          final end = (offset + limit).clamp(0, sourceData.length);
          return sourceData.sublist(offset, end);
        },
        pageSize: 10,
      );
    });

    test('initial state is empty', () {
      expect(lazyList.isEmpty, isTrue);
      expect(lazyList.isNotEmpty, isFalse);
      expect(lazyList.length, equals(0));
      expect(lazyList.hasMore, isTrue);
      expect(lazyList.isLoading, isFalse);
    });

    test('loadMore loads first page', () async {
      await lazyList.loadMore();

      expect(lazyList.length, equals(10));
      expect(lazyList[0], equals(0));
      expect(lazyList[9], equals(9));
      expect(lazyList.hasMore, isTrue);
    });

    test('loadMore loads multiple pages', () async {
      await lazyList.loadMore();
      await lazyList.loadMore();

      expect(lazyList.length, equals(20));
      expect(lazyList[19], equals(19));
    });

    test('loadMore stops when no more items', () async {
      // Load all 100 items (10 pages of 10)
      for (int i = 0; i < 10; i++) {
        await lazyList.loadMore();
      }

      expect(lazyList.length, equals(100));
      // hasMore is still true because last page was full
      expect(lazyList.hasMore, isTrue);

      // Try to load one more page - should get empty and set hasMore to false
      await lazyList.loadMore();
      expect(lazyList.hasMore, isFalse);
      expect(lazyList.length, equals(100));
    });

    test('loadMore does nothing when already loading', () async {
      final future1 = lazyList.loadMore();
      final future2 = lazyList.loadMore();

      await Future.wait([future1, future2]);

      // Should only load one page
      expect(lazyList.length, equals(10));
    });

    test('loadMore does nothing when no more items', () async {
      // Load all items and trigger hasMore = false
      for (int i = 0; i < 11; i++) {
        await lazyList.loadMore();
      }

      expect(lazyList.hasMore, isFalse);

      // Try to load more
      await lazyList.loadMore();

      // Should still be 100
      expect(lazyList.length, equals(100));
    });

    test('refresh reloads from beginning', () async {
      await lazyList.loadMore();
      await lazyList.loadMore();

      expect(lazyList.length, equals(20));

      await lazyList.refresh();

      expect(lazyList.length, equals(10));
      expect(lazyList[0], equals(0));
    });

    test('clear resets the list', () async {
      await lazyList.loadMore();

      expect(lazyList.length, equals(10));

      lazyList.clear();

      expect(lazyList.length, equals(0));
      expect(lazyList.hasMore, isTrue);
    });

    test('indexOf returns correct index', () async {
      await lazyList.loadMore();

      expect(lazyList.indexOf(5), equals(5));
      expect(lazyList.indexOf(99), equals(-1));
    });

    test('contains returns correct value', () async {
      await lazyList.loadMore();

      expect(lazyList.contains(5), isTrue);
      expect(lazyList.contains(99), isFalse);
    });

    test('operator [] returns correct item', () async {
      await lazyList.loadMore();

      expect(lazyList[0], equals(0));
      expect(lazyList[9], equals(9));
    });

    test('items returns unmodifiable list', () async {
      await lazyList.loadMore();

      expect(() => lazyList.items.add(999), throwsUnsupportedError);
    });

    test('toString returns descriptive string', () async {
      final str = lazyList.toString();

      expect(str, contains('LazyList'));
      expect(str, contains('length'));
      expect(str, contains('hasMore'));
      expect(str, contains('isLoading'));
    });
  });
}
