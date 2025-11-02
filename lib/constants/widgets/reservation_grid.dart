// import 'package:airport_test/api_services/api_classes/valid_reservation.dart';
// import 'package:airport_test/api_services/api_classes/list_panel_field.dart';
// import 'package:airport_test/constants/theme.dart';
// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_datagrid/datagrid.dart';

// class ReservationGrid extends StatefulWidget {
//   final List<ValidReservation> reservations;
//   final List<ListPanelField> listPanelFields;
//   final ValueChanged<ValidReservation?>? onReservationSelected;
//   final ValidReservation? selectedReservation;
//   final void Function(ValidReservation selectedReservation)? onRightClick;

//   const ReservationGrid({
//     super.key,
//     required this.reservations,
//     required this.listPanelFields,
//     this.onReservationSelected,
//     this.selectedReservation,
//     this.onRightClick,
//   });

//   @override
//   State<ReservationGrid> createState() => _ReservationGridState();
// }

// class _ReservationGridState extends State<ReservationGrid> {
//   late ReservationDataSource dataSource;
//   late List<GridColumn> gridColumns;
//   final DataGridController dataGridController = DataGridController();
//   late Map<String, double> columnWidths = {};

//   @override
//   void initState() {
//     super.initState();
//     gridColumns = buildColumnsFromServerFields();
//     dataSource = createDataSource();
//   }

//   @override
//   void didUpdateWidget(covariant ReservationGrid oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.reservations != widget.reservations) {
//       dataSource.updateData(reservations: widget.reservations);
//       dataSource.notifyListeners();
//     }
//   }

//   ReservationDataSource createDataSource() {
//     return ReservationDataSource(
//       reservations: widget.reservations,
//       columnOrder: gridColumns.map((c) => c.columnName).toList(),
//     );
//   }

//   List<GridColumn> buildColumnsFromServerFields() {
//     final visibleFields =
//         widget.listPanelFields.where((f) => f.fieldVisible).toList();

//     // Ha korábban már van szélesség beállítva, azt megtartjuk
//     for (var f in visibleFields) {
//       columnWidths.putIfAbsent(f.listFieldName, () => double.nan);
//     }

//     return visibleFields.map((field) {
//       return GridColumn(
//         columnName: field.listFieldName,
//         width: columnWidths[field.listFieldName] ?? double.nan,
//         minimumWidth: 75,
//         maximumWidth: 300,
//         label: Container(
//           alignment: Alignment.center,
//           child: Text(
//             field.fieldCaption ?? field.listFieldName,
//             style: const TextStyle(
//               color: AppColors.text,
//               fontWeight: FontWeight.bold,
//             ),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       );
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SfDataGrid(
//       source: dataSource,
//       controller: dataGridController,
//       selectionMode: SelectionMode.single,
//       allowSorting: true,
//       allowColumnsDragging: true,
//       allowColumnsResizing: true,
//       columnWidthMode: ColumnWidthMode.auto,
//       onColumnResizeUpdate: (details) => handleColumnResize(details),
//       onColumnDragging: (details) => handleColumnDragging(details),
//       onSelectionChanged: (addedRows, removedRows) {
//         handleSelectionChanged(addedRows);
//       },
//       onCellSecondaryTap: (details) => handleRightClick(details),
//       columns: gridColumns,
//     );
//   }

//   void handleSelectionChanged(List<DataGridRow> selectedRows) {
//     if (selectedRows.isNotEmpty) {
//       final selectedRow = selectedRows.first;
//       final reservation = dataSource.getReservationForRow(selectedRow);
//       widget.onReservationSelected?.call(reservation);
//     } else {
//       widget.onReservationSelected?.call(null);
//     }
//   }

//   void handleRightClick(DataGridCellTapDetails details) {
//     final rowIndex = details.rowColumnIndex.rowIndex;
//     if (rowIndex <= 0) return;

//     final clickedRow = dataSource.effectiveRows[rowIndex - 1];
//     dataGridController.selectedRows = [clickedRow];

//     final reservation = dataSource.getReservationForRow(clickedRow)!;
//     widget.onRightClick?.call(reservation);
//   }

//   bool handleColumnDragging(DataGridColumnDragDetails details) {
//     if (details.action == DataGridColumnDragAction.dropped &&
//         details.to != null) {
//       setState(() {
//         final dragged = gridColumns.removeAt(details.from);
//         int insertIndex = details.to!;
//         if (details.from < insertIndex) insertIndex++;
//         if (insertIndex > gridColumns.length) insertIndex = gridColumns.length;
//         gridColumns.insert(insertIndex, dragged);

//         // DataSource új oszlopsorrenddel
//         dataSource = createDataSource();
//       });
//     }
//     return true;
//   }

//   bool handleColumnResize(ColumnResizeUpdateDetails details) {
//     setState(() {
//       columnWidths[details.column.columnName] = details.width;

//       // Új oszloplista a megtartott szélességekkel
//       gridColumns = gridColumns.map((col) {
//         if (col.columnName == details.column.columnName) {
//           return GridColumn(
//             columnName: col.columnName,
//             width: details.width,
//             minimumWidth: 75,
//             maximumWidth: 300,
//             label: col.label,
//           );
//         }
//         return col;
//       }).toList();
//     });
//     return true;
//   }
// }

// class ReservationDataSource extends DataGridSource {
//   ReservationDataSource({
//     required List<ValidReservation> reservations,
//     required this.columnOrder,
//   }) : _reservations = reservations {
//     buildRows();
//   }

//   List<ValidReservation> _reservations;
//   final List<String> columnOrder;
//   late List<DataGridRow> _rows;
//   final Map<DataGridRow, ValidReservation> _rowToReservationMap = {};

//   @override
//   List<DataGridRow> get rows => _rows;

//   void updateData({required List<ValidReservation> reservations}) {
//     _reservations = reservations;
//     buildRows();
//     notifyListeners();
//   }

//   void buildRows() {
//     _rowToReservationMap.clear();
//     _rows = _reservations.map((r) {
//       final row = DataGridRow(
//         cells: columnOrder.map((columnName) {
//           return DataGridCell<String>(
//             columnName: columnName,
//             value: r.getValue(r, columnName),
//           );
//         }).toList(),
//       );
//       _rowToReservationMap[row] = r;
//       return row;
//     }).toList();
//   }

//   @override
//   DataGridRowAdapter buildRow(DataGridRow row) {
//     final reservation = _rowToReservationMap[row];
//     final rowColor = getRowColor(reservation!);
//     return DataGridRowAdapter(
//       color: rowColor,
//       cells: row.getCells().map((cell) {
//         return Container(
//           alignment: Alignment.center,
//           padding: const EdgeInsets.symmetric(horizontal: 4.0),
//           child: Text(
//             cell.value ?? '-',
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(color: AppColors.text),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Color getRowColor(ValidReservation reservation) {
//     switch (reservation.state) {
//       case 1:
//         return Colors.green;
//       case 3:
//         return Colors.red;
//       default:
//         return Colors.white;
//     }
//   }

//   ValidReservation? getReservationForRow(DataGridRow row) {
//     return _rowToReservationMap[row];
//   }
// }
