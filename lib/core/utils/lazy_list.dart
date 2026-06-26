import 'dart:async';

/// A lazy-loading list that loads items in pages as needed.
///
/// Use for large datasets like song lists to avoid loading everything at once.
class LazyList<T> {
  /// Function to load a page of items.
  final Future<List<T>> Function(int offset, int limit) _loader;

  /// Number of items per page.
  final int pageSize;

  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;

  /// Creates a lazy list with the given [loader] and [pageSize].
  LazyList({
    required Future<List<T>> Function(int offset, int limit) loader,
    this.pageSize = 50,
  }) : _loader = loader;

  /// Returns an unmodifiable view of the loaded items.
  List<T> get items => List.unmodifiable(_items);

  /// Returns true if currently loading a page.
  bool get isLoading => _isLoading;

  /// Returns true if there are more items to load.
  bool get hasMore => _hasMore;

  /// Returns the number of loaded items.
  int get length => _items.length;

  /// Returns true if the list is empty.
  bool get isEmpty => _items.isEmpty;

  /// Returns true if the list is not empty.
  bool get isNotEmpty => _items.isNotEmpty;

  /// Access an item by index.
  T operator [](int index) => _items[index];

  /// Loads the next page of items.
  ///
  /// Does nothing if already loading or no more items.
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;

    try {
      final newItems = await _loader(_currentPage * pageSize, pageSize);

      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(newItems);
        _currentPage++;

        if (newItems.length < pageSize) {
          _hasMore = false;
        }
      }
    } finally {
      _isLoading = false;
    }
  }

  /// Reloads all items from the beginning.
  Future<void> refresh() async {
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
    await loadMore();
  }

  /// Clears all loaded items and resets pagination.
  void clear() {
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
  }

  /// Returns the index of [item] in the list, or -1 if not found.
  int indexOf(T item) => _items.indexOf(item);

  /// Returns true if the list contains [item].
  bool contains(T item) => _items.contains(item);

  /// Loads items until [predicate] is satisfied or all items are loaded.
  Future<void> loadUntil(bool Function(T item) predicate) async {
    while (_hasMore && !_isLoading) {
      await loadMore();
      if (_items.any(predicate)) break;
    }
  }

  /// Loads all remaining items.
  Future<void> loadAll() async {
    while (_hasMore && !_isLoading) {
      await loadMore();
    }
  }

  @override
  String toString() =>
      'LazyList(length=$length, hasMore=$hasMore, isLoading=$isLoading)';
}
