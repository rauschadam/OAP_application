import 'package:airport_test/api_services/api_classes/list_panel_field.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class GenericDataGrid<T> extends StatefulWidget {
  final List<T> rows;
  final List<ListPanelField> listPanelFields;
  final ValueChanged<T?>? onRowSelected;
  final void Function(T selectedItem)? onRightClick;

  const GenericDataGrid({
    super.key,
    required this.rows,
    required this.listPanelFields,
    this.onRowSelected,
    this.onRightClick,
  });

  @override
  State<GenericDataGrid<T>> createState() => _GenericDataGridState<T>();
}

class _GenericDataGridState<T> extends State<GenericDataGrid<T>> {
  late GenericDataSource<T> dataSource;
  late List<GridColumn> gridColumns;
  final DataGridController dataGridController = DataGridController();
  late Map<String, double> columnWidths = {};

  @override
  void initState() {
    super.initState();
    gridColumns = buildColumnsFromServerFields();
    dataSource = createDataSource();
  }

  @override
  void didUpdateWidget(covariant GenericDataGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) {
      dataSource.updateData(items: widget.rows);
      dataSource.notifyListeners();
    }
  }

  GenericDataSource<T> createDataSource() {
    return GenericDataSource<T>(
      items: widget.rows,
      columnOrder: gridColumns.map((c) => c.columnName).toList(),
    );
  }

  List<GridColumn> buildColumnsFromServerFields() {
    final visibleFields =
        widget.listPanelFields.where((f) => f.fieldVisible).toList();

    // korábban beállított szélesség megtartása
    for (var f in visibleFields) {
      columnWidths.putIfAbsent(f.listFieldName, () => double.nan);
    }

    return visibleFields.map((field) {
      return GridColumn(
        columnName: field.listFieldName,
        width: columnWidths[field.listFieldName] ?? double.nan,
        minimumWidth: 75,
        maximumWidth: 300,
        label: Container(
          alignment: Alignment.center,
          child: Text(
            field.fieldCaption ?? field.listFieldName,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SfDataGrid(
      source: dataSource,
      controller: dataGridController,
      selectionMode: SelectionMode.single,
      allowSorting: true,
      allowColumnsDragging: true,
      allowColumnsResizing: true,
      columnWidthMode: ColumnWidthMode.auto,
      onColumnResizeUpdate: (details) => handleColumnResize(details),
      onColumnDragging: (details) => handleColumnDragging(details),
      onSelectionChanged: (addedRows, removedRows) {
        handleSelectionChanged(addedRows);
      },
      onCellSecondaryTap: (details) => handleRightClick(details),
      columns: gridColumns,
    );
  }

  // --- KIVÁLASZTÁS ---
  void handleSelectionChanged(List<DataGridRow> selectedRows) {
    if (selectedRows.isNotEmpty) {
      final selectedRow = selectedRows.first;
      final item = dataSource.getItemForRow(selectedRow);
      widget.onRowSelected?.call(item);
    } else {
      widget.onRowSelected?.call(null);
    }
  }

  // --- JOBB KATTINTÁS ---
  void handleRightClick(DataGridCellTapDetails details) {
    final rowIndex = details.rowColumnIndex.rowIndex;
    if (rowIndex <= 0) return;

    final clickedRow = dataSource.effectiveRows[rowIndex - 1];
    dataGridController.selectedRows = [clickedRow];

    final item = dataSource.getItemForRow(clickedRow)!;
    widget.onRightClick?.call(item);
  }

  // --- OSZLOP HÚZÁS ---
  bool handleColumnDragging(DataGridColumnDragDetails details) {
    if (details.action == DataGridColumnDragAction.dropped &&
        details.to != null) {
      setState(() {
        final dragged = gridColumns.removeAt(details.from);
        int insertIndex = details.to!;
        if (details.from < insertIndex) insertIndex++;
        if (insertIndex > gridColumns.length) insertIndex = gridColumns.length;
        gridColumns.insert(insertIndex, dragged);

        // új oszlopsorrenddel
        dataSource = createDataSource();
      });
    }
    return true;
  }

  // --- OSZLOP MÉRET MÓDOSÍTÁS ---
  bool handleColumnResize(ColumnResizeUpdateDetails details) {
    setState(() {
      columnWidths[details.column.columnName] = details.width;

      gridColumns = gridColumns.map((col) {
        if (col.columnName == details.column.columnName) {
          return GridColumn(
            columnName: col.columnName,
            width: details.width,
            minimumWidth: 75,
            maximumWidth: 300,
            label: col.label,
          );
        }
        return col;
      }).toList();
    });
    return true;
  }
}

class GenericDataSource<T> extends DataGridSource {
  GenericDataSource({
    required List<T> items,
    required this.columnOrder,
  }) : _items = items {
    buildRows();
  }

  List<T> _items;
  final List<String> columnOrder;
  late List<DataGridRow> _rows;
  final Map<DataGridRow, T> _rowToItemMap = {};

  @override
  List<DataGridRow> get rows => _rows;

  void updateData({required List<T> items}) {
    _items = items;
    buildRows();
    notifyListeners();
  }

  void buildRows() {
    _rowToItemMap.clear();
    _rows = _items.map((item) {
      final row = DataGridRow(
        cells: columnOrder.map((col) {
          final value = _extractValue(item, col);
          return DataGridCell<String>(
            columnName: col,
            value: value?.toString() ?? '-',
          );
        }).toList(),
      );
      _rowToItemMap[row] = item;
      return row;
    }).toList();
  }

  /// Lekéri a cella értékét (akár Map, akár objektum)
  dynamic _extractValue(T item, String field) {
    if (item is Map<String, dynamic>) {
      return item[field];
    }
    try {
      final dynamic obj = item;
      if (obj.toJson is Function) {
        return obj.toJson()[field];
      }
      return obj[field];
    } catch (_) {
      return null;
    }
  }

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      color: Colors.white,
      cells: row.getCells().map((cell) {
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            cell.value ?? '-',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.text),
          ),
        );
      }).toList(),
    );
  }

  T? getItemForRow(DataGridRow row) => _rowToItemMap[row];
}
