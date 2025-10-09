// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:airport_test/api_services/api_classes/valid_reservation.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class MyDataGrid extends StatefulWidget {
  final List<ValidReservation> reservations;
  final ValueChanged<ValidReservation?>? onReservationSelected;
  final ValidReservation? selectedReservation;
  final void Function(ValidReservation selectedReservation)? onRightClick;

  final bool showName;
  final bool showLicense;
  final bool showZone;
  final bool showArriveDate;
  final bool showLeaveDate;
  final bool showPhone;
  final bool showEmail;
  final bool showState;
  final bool showId;
  final bool showDescription;

  const MyDataGrid({
    super.key,
    required this.reservations,
    this.onReservationSelected,
    this.selectedReservation,
    this.onRightClick,
    this.showName = false,
    this.showLicense = false,
    this.showZone = false,
    this.showArriveDate = false,
    this.showLeaveDate = false,
    this.showPhone = false,
    this.showEmail = false,
    this.showState = false,
    this.showId = false,
    this.showDescription = false,
  });

  @override
  State<MyDataGrid> createState() => _MyDataGridState();
}

class _MyDataGridState extends State<MyDataGrid> {
  /// A gridhez kellő adatok
  late ReservationDataSource dataSource;

  /// A grid oszlopai
  late List<GridColumn> gridColumns;

  final DataGridController dataGridController = DataGridController();

  DataGridRow? selectedRow;

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
  void didUpdateWidget(covariant MyDataGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reservations != widget.reservations) {
      dataSource.updateData(reservations: widget.reservations);
      dataSource.notifyListeners();
    }
  }

  @override
  void initState() {
    super.initState();
    gridColumns = buildInitialColumns();
    dataSource = createDataSource();
  }

  ReservationDataSource createDataSource() {
    return ReservationDataSource(
      reservations: widget.reservations,
      columnOrder: gridColumns.map((c) => c.columnName).toList(),
    );
  }

  List<GridColumn> buildInitialColumns() {
    return [
      buildColumn('Partner_Sortname', 'Név', widget.showName),
      buildColumn('LicensePlate', 'Rendszám', widget.showLicense),
      buildColumn('ArticleNameHUN', 'Zóna', widget.showZone),
      buildColumn('ArriveDate', 'Érkezés dátuma', widget.showArriveDate),
      buildColumn('LeaveDate', 'Távozás dátuma', widget.showLeaveDate),
      buildColumn('Phone', 'Telefonszám', widget.showPhone),
      buildColumn('Email', 'Email', widget.showEmail),
      buildColumn('State', 'Státusz', widget.showState),
      buildColumn('WebParkingId', 'Id', widget.showId),
      buildColumn('Description', 'Megjegyzés', widget.showDescription),
    ];
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
      onSelectionChanged:
          (List<DataGridRow> addedRows, List<DataGridRow> removedRows) {
        handleSelectionChanged(addedRows);
      },
      onCellSecondaryTap: (details) => handleRightClick(details),
      columns: gridColumns,
    );
  }

  /// Kiválasztás kezelése (bal-klikk)
  void handleSelectionChanged(List<DataGridRow> selectedRows) {
    if (selectedRows.isNotEmpty) {
      final selectedRow = selectedRows.first;
      final reservation = dataSource.getReservationForRow(selectedRow);
      widget.onReservationSelected?.call(reservation);
    } else {
      widget.onReservationSelected?.call(null);
    }
  }

  /// Jobb klikk
  void handleRightClick(DataGridCellTapDetails details) {
    final rowIndex = details.rowColumnIndex.rowIndex;

    // Fejléc sor kihagyása
    if (rowIndex <= 0) return;

    // Az effectiveRows a sortolás utáni aktuális sorrendet tartalmazza
    final clickedRow = dataSource.effectiveRows[rowIndex - 1];

    // Kijelölés beállítása (ugyanazt váltja ki, mint a bal klikk)
    dataGridController.selectedRows = [clickedRow];

    // Lefuttatjuk ugyanazt az eseményt, mint bal klikk esetén
    // Ehhez annyi hozzáfűzni való, hogy ha előtte bal klikkel kiválasztottunk egy sort,
    // akkor a színezés azon a soron marad, de az már nincs kiválasztva
    final ValidReservation reservation =
        dataSource.getReservationForRow(clickedRow)!;

    // Végül megcsináljuk a jobb klikk plussz eseményét is
    widget.onRightClick!(reservation);
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

  /// Oszlop újraméretezése
  bool handleColumnResize(ColumnResizeUpdateDetails details) {
    setState(() {
      columnWidths[details.column.columnName] = details.width;

      // Újraépítjük az oszlopokat az aktuális láthatósági értékekkel
      gridColumns = [
        buildColumn('Partner_Sortname', 'Név', widget.showName),
        buildColumn('LicensePlate', 'Rendszám', widget.showLicense),
        buildColumn('ArticleNameHUN', 'Zóna', widget.showZone),
        buildColumn('ArriveDate', 'Érkezés dátuma', widget.showArriveDate),
        buildColumn('LeaveDate', 'Távozás dátuma', widget.showLeaveDate),
        buildColumn('Phone', 'Telefonszám', widget.showPhone),
        buildColumn('Email', 'Email', widget.showEmail),
        buildColumn('State', 'Státusz', widget.showState),
        buildColumn('WebParkingId', 'Id', widget.showId),
        buildColumn('Description', 'Megjegyzés', widget.showDescription),
      ];
    });
    return true;
  }

  GridColumn buildColumn(String name, String labelText, bool isVisible) {
    return GridColumn(
      visible: isVisible,
      minimumWidth: 75,
      maximumWidth: 300,
      width: isVisible ? columnWidths[name]! : 0,
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
    required List<ValidReservation> reservations,
    required this.columnOrder,
  }) : _reservations = reservations {
    buildRows();
  }

  List<ValidReservation> _reservations;
  final List<String> columnOrder;

  late List<DataGridRow> _rows;
  final Map<DataGridRow, ValidReservation> _rowToReservationMap = {};

  @override
  List<DataGridRow> get rows => _rows;

  /// Adatok frissítése új adatokkal
  void updateData({
    required List<ValidReservation> reservations,
  }) {
    _reservations = reservations;
    buildRows();
  }

  /// Adatsorok építése
  void buildRows() {
    _rowToReservationMap.clear();
    _rows = _reservations.map<DataGridRow>((r) {
      final dataGridRow = DataGridRow(
        cells: columnOrder.map((columnName) {
          return DataGridCell<String>(
            columnName: columnName,
            value: getValue(r, columnName),
          );
        }).toList(),
      );

      // Eltároljuk a leképezést
      _rowToReservationMap[dataGridRow] = r;
      return dataGridRow;
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
    final index = effectiveRows.indexOf(row);

    final rowColor = index.isEven ? Colors.grey.shade100 : Colors.white;

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

  /// Segédfüggvény: DataGridRow alapján visszaadja a hozzá tartozó foglalást
  ValidReservation? getReservationForRow(DataGridRow row) {
    return _rowToReservationMap[row];
  }
}
