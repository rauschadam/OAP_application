import 'package:airport_test/api_services/api_classes/list_panel_field.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class ListPanelGrid<T> extends StatefulWidget {
  final List<T> rows;
  final List<ListPanelField> listPanelFields;
  final ValueChanged<T?>? onRowSelected;
  final void Function(T selectedItem)? onRightClick;

  const ListPanelGrid({
    super.key,
    required this.rows,
    required this.listPanelFields,
    this.onRowSelected,
    this.onRightClick,
  });

  @override
  State<ListPanelGrid<T>> createState() => ListPanelGridState<T>();
}

class ListPanelGridState<T> extends State<ListPanelGrid<T>> {
  late ListPanelDataSource<T> dataSource;
  late List<GridColumn> gridColumns;
  final DataGridController dataGridController = DataGridController();
  late Map<String, double> columnWidths = {};
  // GlobalKey az SfDataGrid állapotához az exportáláshoz
  final GlobalKey<SfDataGridState> sfGridKey = GlobalKey<SfDataGridState>();

  // --- MÁSOLÁS VÁGÓLAPRA ---
  Future<void> copyDataToClipboard() async {
    if (gridColumns.isEmpty || dataSource.rows.isEmpty) return;

    // 1. Fejlécek (oszlopnevek) kinyerése tabulátorral elválasztva
    final headers = gridColumns.map((col) {
      // A labelből kinyerjük a Text tartalmát, ha elérhető
      if (col.label is Container && (col.label as Container).child is Text) {
        return ((col.label as Container).child as Text).data ?? col.columnName;
      }
      return col.columnName;
    }).join('\t'); // Tabulátorral elválasztva

    // 2. Adatsorok kinyerése tabulátorral és újsorral elválasztva
    final dataRows = dataSource.rows.map((row) {
      return row.getCells().map((cell) => cell.value.toString()).join('\t');
    }).join('\n'); // Sorok újsorral elválasztva

    final fullData = '$headers\n$dataRows';

    // 3. Másolás a vágólapra
    await Clipboard.setData(ClipboardData(text: fullData));

    // Visszajelzés a felhasználónak
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('A lista tartalma sikeresen a vágólapra másolva.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    gridColumns = buildColumnsFromServerFields();
    dataSource = createDataSource();
  }

  @override
  void didUpdateWidget(covariant ListPanelGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) {
      dataSource.updateData(items: widget.rows);
      dataSource.notifyListeners();
    }
  }

  ListPanelDataSource<T> createDataSource() {
    return ListPanelDataSource<T>(
      items: widget.rows,
      columnOrder: gridColumns.map((c) => c.columnName).toList(),
    );
  }

  List<GridColumn> buildColumnsFromServerFields() {
    final visibleFields =
        widget.listPanelFields.where((f) => f.fieldVisible).toList();

    // korábban beállított szélesség megtartása
    for (var field in visibleFields) {
      columnWidths.putIfAbsent(field.listFieldName, () => double.nan);
    }

    return visibleFields.map((field) {
      return GridColumn(
        columnName: field.listFieldName,
        width: field.fieldWidth
                ?.toDouble() ?? // Ha van EuroStone-ban megadva szélesség
            columnWidths[field.listFieldName] ?? // Ha van eltárolt szélessége
            double.nan,
        minimumWidth: field.fieldMinWidth?.toDouble() ?? 75,
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
      key: sfGridKey,
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

    final item = dataSource.getItemForRow(clickedRow);
    if (item == null) return;
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

class ListPanelDataSource<T> extends DataGridSource {
  ListPanelDataSource({
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
          final value = extractValue(item, col);
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
  dynamic extractValue(T item, String field) {
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
