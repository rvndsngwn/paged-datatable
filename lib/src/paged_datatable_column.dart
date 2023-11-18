part of 'paged_datatable.dart';

abstract class BaseTableColumn<T extends Object> {
  final String? id;
  final String? title;
  final Widget Function(BuildContext context)? titleBuilder;
  final bool sortable;
  final bool isNumeric;
  final double? sizeFactor;

  const BaseTableColumn(
      {required this.id,
      required this.title,
      required this.titleBuilder,
      required this.sortable,
      required this.isNumeric,
      required this.sizeFactor})
      : assert(title != null || titleBuilder != null,
            "Either title or titleBuilder should be provided.");

  Widget buildCell(T item, int rowIndex);
}

/// Defines a [BaseTableColumn] that allows the content of a cell to be modified, updating the underlying
/// item too.
abstract class EditableTableColumn<T extends Object, TValue extends Object>
    extends BaseTableColumn<T> {
  /// Function called when the value of the cell changes, and must update the underlying [T], returning
  /// true if it could be updated, otherwise, false.
  final Setter<T, TValue> setter;

  /// A function that returns the value that is going to be edited.
  final Getter<T, TValue> getter;

  const EditableTableColumn(
      {required this.setter,
      required this.getter,
      required super.id,
      required super.title,
      required super.titleBuilder,
      required super.sortable,
      required super.isNumeric,
      required super.sizeFactor});
}

/// Defines a simple [BaseTableColumn] that renders a cell based on [cellBuilder]
class TableColumn<T extends Object> extends BaseTableColumn<T> {
  final Widget Function(T) cellBuilder;

  const TableColumn(
      {required super.title,
      required this.cellBuilder,
      super.sizeFactor = .1,
      super.isNumeric = false,
      super.sortable = false,
      super.id})
      : assert(!sortable || id != null, "sortable columns must define an id"),
        super(titleBuilder: null);

  @override
  Widget buildCell(T item, int rowIndex) => cellBuilder(item);
}

/// Defines an [EditableTableColumn] that renders a [DropdownFormField] with a list of items.
class DropdownTableColumn<T extends Object, TValue extends Object>
    extends EditableTableColumn<T, TValue> {
  final List<DropdownMenuItem<TValue>> items;
  final InputDecoration? decoration;

  const DropdownTableColumn(
      {this.decoration,
      required this.items,
      required super.getter,
      required super.setter,
      required super.title,
      super.id,
      super.sortable = false,
      super.isNumeric = false,
      super.sizeFactor = .1})
      : super(titleBuilder: null);

  @override
  Widget buildCell(T item, int rowIndex) {
    return _DropdownButtonCell<T, TValue>(
      item: item,
      items: items,
      decoration: decoration,
      initialValue: getter(item),
      setter: (newValue) => setter(item, newValue, rowIndex),
    );
  }
}

/// Defines an [EditableTableColumn] that renders a text field when double-clicked
class TextTableColumn<T extends Object> extends EditableTableColumn<T, String> {
  final InputDecoration? decoration;
  final List<TextInputFormatter>? inputFormatters;

  const TextTableColumn(
      {this.decoration,
      this.inputFormatters,
      required super.getter,
      required super.setter,
      required super.title,
      super.id,
      super.sortable = false,
      super.isNumeric = false,
      super.sizeFactor = .1})
      : super(titleBuilder: null);

  @override
  Widget buildCell(T item, int rowIndex) {
    return _TextFieldCell<T>(
      isNumeric: isNumeric,
      item: item,
      inputFormatters: inputFormatters,
      decoration: decoration,
      initialValue: getter(item),
      setter: (newValue) => setter(item, newValue, rowIndex),
    );
  }
}

/// Defines an [EditableTableColumn] that renders the text of a field and when double-clicked, an overlay with a multiline, bigger text field
/// is shown.
class LargeTextTableColumn<T extends Object> extends EditableTableColumn<T, String> {
  final InputDecoration? decoration;
  final String? label;
  final bool tooltipText;
  final EdgeInsets? tooltipPadding, tooltipMargin;
  final List<TextInputFormatter>? inputFormatters;

  const LargeTextTableColumn(
      {this.decoration,
      this.inputFormatters,
      this.label,
      this.tooltipText = false,
      this.tooltipPadding,
      this.tooltipMargin,
      required super.getter,
      required super.setter,
      required super.title,
      super.id,
      super.sortable = false,
      super.isNumeric = false,
      super.sizeFactor = .1})
      : super(titleBuilder: null);

  @override
  Widget buildCell(T item, int rowIndex) {
    return _EditableTextField(
        tooltipText: tooltipText,
        tooltipMargin: tooltipMargin,
        tooltipPadding: tooltipPadding,
        initialValue: getter(item) ?? "",
        setter: (newValue) => setter(item, newValue, rowIndex),
        validator: null,
        decoration: decoration,
        label: label ?? title!,
        formatters: inputFormatters);
  }
}
