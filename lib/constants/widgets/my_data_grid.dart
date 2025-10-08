import 'package:airport_test/api_services/api_classes/valid_reservation.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class MyDataGrid extends StatefulWidget {
  final List<ValidReservation> reservations;
  final ValueChanged<ValidReservation?>? onReservationSelected;
  final ValidReservation? selectedReservation;
  final void Function()? onRightClick;

  const MyDataGrid({
    super.key,
    required this.reservations,
    this.onReservationSelected,
    this.selectedReservation,
    this.onRightClick,
  });

  @override
  State<MyDataGrid> createState() => _MyDataGridState();
}

class _MyDataGridState extends State<MyDataGrid> {
  /// A gridhez kellő adatok
  late ReservationDataSource dataSource;

  /// A grid oszlopai
  late List<GridColumn> gridColumns;

  /// Oszlop szélességek
  late Map<String, double> columnWidths = {
    'Partner_Sortname': double.nan,
    'LicensePlate': double.nan,
    'ArticleNameHUN': double.nan,
    'ArriveDate': double.nan,
    'LeaveDate': double.nan,
    'Phone': double.nan,
    'Email': double.nan,
    'State': double.nan,
    'WebParkingId': double.nan,
    'Description': double.nan,
  };

  @override
  void initState() {
    super.initState();
    gridColumns = buildInitialColumns();
    dataSource = createDataSource();
  }

  @override
  void didUpdateWidget(covariant MyDataGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reservations != widget.reservations ||
        oldWidget.selectedReservation != widget.selectedReservation) {
      // A rendezés elmentése
      final oldSortedColumns = dataSource.sortedColumns.toList();

      dataSource = createDataSource();

      // Rendezés visszaállítása
      dataSource.sortedColumns.addAll(oldSortedColumns);
      dataSource.sort();

      setState(() {});
    }
  }

  ReservationDataSource createDataSource() {
    return ReservationDataSource(
      reservations: widget.reservations,
      columnOrder: gridColumns.map((c) => c.columnName).toList(),
      selectedReservation: widget.selectedReservation,
    );
  }

  List<GridColumn> buildInitialColumns() {
    final columns = [
      buildColumn('Partner_Sortname', 'Név'),
      buildColumn('LicensePlate', 'Rendszám'),
      buildColumn('ArticleNameHUN', 'Zóna'),
      buildColumn('ArriveDate', 'Érkezés dátuma'),
      buildColumn('LeaveDate', 'Távozás dátuma'),
      buildColumn('Phone', 'Telefonszám'),
      buildColumn('Email', 'Email'),
      buildColumn('State', 'Státusz'),
      buildColumn('WebParkingId', 'Id'),
      buildColumn('Description', 'Megjegyzés'),
    ];

    // Feltölti az oszlopméreteket is
    for (final col in columns) {
      columnWidths[col.columnName] ??= double.nan;
    }

    return columns;
  }

  @override
  Widget build(BuildContext context) {
    return SfDataGrid(
      source: dataSource,
      allowSorting: true,
      allowColumnsDragging: true,
      allowColumnsResizing: true,
      columnWidthMode: ColumnWidthMode.fill,
      onColumnResizeUpdate: (details) => handleColumnResize(details),
      onColumnDragging: (details) => handleColumnDragging(details),
      onCellTap: (details) => handleLeftClick(details),
      onCellSecondaryTap: (details) => handleRightClick(details, context),
      columns: gridColumns,
    );
  }

  void handleLeftClick(DataGridCellTapDetails details) {
    if (details.rowColumnIndex.rowIndex > 0) {
      try {
        final row = dataSource.rows[details.rowColumnIndex.rowIndex - 1];
        final webIdCell =
            row.getCells().firstWhere((c) => c.columnName == 'WebParkingId');

        final ValidReservation reservation = widget.reservations.firstWhere(
          (r) => r.webParkingId.toString() == webIdCell.value,
        );

        dataSource.updateSelectedReservation(reservation);
        widget.onReservationSelected?.call(reservation);
      } catch (_) {
        dataSource.updateSelectedReservation(null);
        widget.onReservationSelected?.call(null);
      }
    }
  }

  /// Adatra jobb klikkelés
  void handleRightClick(DataGridCellTapDetails details, BuildContext context) {
    handleLeftClick(details);
    widget.onRightClick?.call();
  }

  /// Oszlop áthelyezés
  bool handleColumnDragging(DataGridColumnDragDetails details) {
    if (details.action == DataGridColumnDragAction.dropped &&
        details.to != null) {
      setState(() {
        final dragged = gridColumns.removeAt(details.from);
        int insertIndex = details.to!;
        if (details.from < insertIndex) insertIndex++;
        if (insertIndex > gridColumns.length) insertIndex = gridColumns.length;
        gridColumns.insert(insertIndex, dragged);

        // Új DataSource a friss oszlopsorrenddel
        dataSource = createDataSource();
      });
    }
    return true;
  }

  bool handleColumnResize(ColumnResizeUpdateDetails details) {
    setState(() {
      columnWidths[details.column.columnName] = details.width;

      // Oszlopok újraépítése az új szélességekkel
      gridColumns = gridColumns.map((col) {
        return buildColumn(
            col.columnName,
            (col.label as Container).child is Text
                ? ((col.label as Container).child as Text).data ??
                    col.columnName
                : col.columnName);
      }).toList();
    });
    return true;
  }

  GridColumn buildColumn(String name, String labelText) {
    return GridColumn(
      minimumWidth: 75,
      maximumWidth: 300,
      width: columnWidths[name] ?? double.nan,
      columnName: name,
      label: Container(
        alignment: Alignment.center,
        child: Text(
          labelText,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class ReservationDataSource extends DataGridSource {
  ReservationDataSource({
    required this.reservations,
    required this.columnOrder,
    this.selectedReservation,
  }) {
    buildRows();
  }

  final List<ValidReservation> reservations;

  /// Oszlopok sorrendje
  final List<String> columnOrder;
  ValidReservation? selectedReservation;

  late List<DataGridRow> _rows;

  @override
  List<DataGridRow> get rows => _rows;

  /// Adatsorok építése
  void buildRows() {
    _rows = reservations.map<DataGridRow>((r) {
      return DataGridRow(
        cells: columnOrder.map((columnName) {
          return DataGridCell<String>(
            columnName: columnName,
            value: getValue(r, columnName),
          );
        }).toList(),
      );
    }).toList();
  }

  /// Az adatsorokon belül az adott oszlopokhoz az oda tartozó adatokat rendeli hozzá
  String getValue(ValidReservation r, String columnName) {
    switch (columnName) {
      case 'Partner_Sortname':
        return r.partner_Sortname;
      case 'LicensePlate':
        return r.licensePlate;
      case 'ParkingArticleId':
        return r.parkingArticleId;
      case 'ArticleNameHUN':
        return r.articleNameHUN;
      case 'ArriveDate':
        return DateFormat('yyyy.MM.dd HH:mm').format(r.arriveDate);
      case 'LeaveDate':
        return DateFormat('yyyy.MM.dd HH:mm').format(r.leaveDate);
      case 'Email':
        return r.email;
      case 'Phone':
        return r.phone;
      case 'State':
        return r.state.toString();
      case 'WebParkingId':
        return r.webParkingId.toString();
      case 'Description':
        return r.description ?? "-";
      default:
        return '-';
    }
  }

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final int index = _rows.indexOf(row);
    final reservation = reservations[index];

    final isSelected =
        selectedReservation?.webParkingId == reservation.webParkingId;

    final rowColor = isSelected
        ? Colors.grey.shade400
        : index.isEven
            ? Colors.grey.shade100
            : Colors.white;

    return DataGridRowAdapter(
      color: rowColor,
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

  void updateSelectedReservation(ValidReservation? reservation) {
    selectedReservation = reservation;
    notifyListeners();
  }
}
