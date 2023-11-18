part of 'paged_datatable.dart';

class _PagedDataTableRowState<TId extends Comparable, T extends Object> extends ChangeNotifier {
  final T item;
  final TId itemId;
  final int index;

  bool _isSelected = false;
  set selected(bool newValue) {
    _isSelected = newValue;
    notifyListeners();
  }

  _PagedDataTableRowState(this.index, this.item, this.itemId);

  void refresh() {
    notifyListeners();
  }
}
