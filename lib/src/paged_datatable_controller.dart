// ignore_for_file: invalid_use_of_protected_member

part of 'paged_datatable.dart';

/// Represents a controller of a [PagedDataTable]
class PagedDataTableController<TKey extends Comparable, TId extends Comparable, T extends Object> {
  late final _PagedDataTableState<TKey, TId, T> _state;

  /// The current showing dataset elements as an unmodifiable list.
  List<T> get currentDataset => UnmodifiableListView(_state._items);

  /// The current pagination info
  PagedDataTablePaginationInfo get paginationInfo => PagedDataTablePaginationInfo._(
      currentPage: _state.currentPage,
      currentPageSize: _state._items.length,
      hasNextPage: _state.hasNextPage,
      rowsPerPage: _state._pageSize,
      hasPreviousPage: _state.hasPreviousPage);

  /// The current applied sort model, if any
  SortBy? get sortBy => _state._sortModel;

  /// Refreshes the table fetching from source again.
  /// If [currentDataset] is true, it will only refresh the current viewing resultset, otherwise,
  /// it will start from page 1.
  ///
  /// The future completes when the fetch is done.
  Future<void> refresh({bool currentDataset = true}) => _state._refresh(initial: !currentDataset);

  /// Advances to the next page.
  ///
  /// If there is no next page, this method will fail.
  /// The future completes when the fetch is done.
  Future<void> advancePage() => _state.nextPage();

  /// Backs off to the previous page.
  ///
  /// If there is no previous page, this method will fail.
  /// The future completes when the fetch is done.
  Future<void> backPage() => _state.previousPage();

  /// Sets a filter and fetches items from source.
  void setFilter(String id, dynamic value) {
    _state.applyFilter(id, value);
  }

  /// Removes a filter and fetches items from source.
  void removeFilter(String id) {
    _state.removeFilter(id);
  }

  /// Removes any applied filter.
  void removeFilters() {
    _state.removeFilters();
  }

  /// Returns a Map where each key is the field name and its value the current field's value
  Map<String, dynamic> getFilters() {
    return _state.filters.map((key, value) => MapEntry(key, value.value));
  }

  /// Gets the value of a filter
  dynamic getFilter(String filterName) {
    return _state.filters[filterName]?.value;
  }

  /// Returns a list of the selected items.
  List<T> getSelectedRows() {
    return _state.selectedRows.values.map((e) => _state._items[e]).toList(growable: false);
  }

  /// Unselects any selected row in the current resultset
  void unselectAllRows() => _state.unselectAllRows();

  /// Selects all the rows in the current resultset
  void selectAllRows() => _state.selectAllRows();

  /// Marks the row whose id is [itemId] as unselected
  void unselectRow(TId itemId) => _state.unselectRow(itemId);

  /// Marks the row whose id is [itemId] as selected
  void selectRow(TId itemId) => _state.selectRow(itemId);

  /// Builds every row that matches [predicate].
  void refreshRowWhere(bool Function(T element) predicate) {
    var elements = _state._rowsState.where((state) => predicate(state.item));
    for (var elem in elements) {
      elem.refresh();
    }
  }

  /// Updates every item from the current resultset that matches [predicate] and rebuilds it.
  ///
  /// Keep in mind this method will iterate over every item in the current dataset, so, if the dataset is large, it can be costly.
  void modifyRowsValue(bool Function(T element) predicate, void Function(T item) update) {
    int index = 0;
    for (final item in _state._items) {
      if (predicate(item)) {
        update(item);
        _state._rowsState[index].refresh();
      }

      index++;
    }
  }

  /// Updates an item from the current resultset with the id [itemId] and rebuilds the row.
  void modifyRowValue(TId itemId, void Function(T item) update) {
    final rowIndex = _state._rowsStateMapper[itemId];
    if (rowIndex == null) {
      throw TableError('Item with key "$itemId" is not in the current dataset.');
    }

    final row = _state._rowsState[rowIndex];
    final item = _state._items[row.index];
    update(item);

    // refresh state of that row.
    row.refresh();
  }

  /// Rebuilds the row which has the specified [itemId] to reflect changes to the item.
  void refreshRow(TId itemId) {
    final rowIndex = _state._rowsStateMapper[itemId];
    if (rowIndex == null) {
      throw TableError('Item with key "$itemId" is not in the current dataset.');
    }

    _state._rowsState[rowIndex].refresh();
  }

  /// Removes the row containing an element whose id is [itemId]
  void removeRow(TId itemId) {
    final rowIndex = _state._rowsStateMapper[itemId];
    if (rowIndex == null) {
      throw TableError('Item with key "$itemId" is not in the current dataset.');
    }

    _state._rowsState.removeAt(rowIndex);
    _state._items.removeAt(rowIndex);
    _state._rowsStateMapper.remove(itemId);
    _state._rowsChange = rowIndex;
    // ignore: invalid_use_of_visible_for_testing_member
    _state.notifyListeners();
  }

  /// Disposes the controller.
  ///
  /// After this method is called, the DataTable is disposed and cannot be used.
  void dispose() {
    _state.dispose();
  }
}

class PagedDataTablePaginationInfo {
  final bool hasNextPage, hasPreviousPage;
  final int currentPageSize, currentPage, rowsPerPage;

  PagedDataTablePaginationInfo._(
      {required this.hasNextPage,
      required this.hasPreviousPage,
      required this.currentPageSize,
      required this.currentPage,
      required this.rowsPerPage});
}
