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
  late ReservationDataSource dataSource;

  late Map<String, double> columnWidths = {
    'partner_Sortname': double.nan,
    'licensePlate': double.nan,
    'articleNameHUN': double.nan,
    'arriveDate': double.nan,
    'leaveDate': double.nan,
    'WebParkingId': double.nan,
  };

  @override
  void initState() {
    super.initState();
    dataSource = ReservationDataSource(
      reservations: widget.reservations,
      selectedReservation: widget.selectedReservation,
    );
  }

  @override
  void didUpdateWidget(covariant MyDataGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reservations != widget.reservations) {
      dataSource = ReservationDataSource(
        reservations: widget.reservations,
        selectedReservation: widget.selectedReservation,
      );
      setState(() {}); // újrarenderelés
    }
  }

  @override
  Widget build(BuildContext context) {
    return SfDataGrid(
      source: dataSource,
      allowSorting: true,
      allowColumnsDragging: true,
      columnWidthMode: ColumnWidthMode.fill,
      // gridLinesVisibility: GridLinesVisibility.both,
      // headerGridLinesVisibility: GridLinesVisibility.both,
      // allowColumnsResizing: true,
      // onColumnResizeUpdate: (ColumnResizeUpdateDetails details) {
      //   setState(() {
      //     columnWidths[details.column.columnName] = details.width;
      //   });
      //   return true;
      // },
      onCellTap: (details) => handleLeftClick(details),
      onCellSecondaryTap: (details) => handleRightClick(details, context),
      columns: [
        buildColumn('Partner_Sortname', 'Név'),
        buildColumn('LicensePlate', 'Rendszám'),
        buildColumn('ArticleNameHUN', 'Zóna'),
        buildColumn('ArriveDate', 'Érkezés dátuma'),
        buildColumn('LeaveDate', 'Távozás dátuma'),
        buildColumn('Email', 'Email'),
        buildColumn('Phone', 'Telefonszám'),
        buildColumn('State', 'Státusz'),
        buildColumn('WebParkingId', 'Id'),
        buildColumn('Description', 'Megjegyzés'),
      ],
    );
  }

  void handleLeftClick(DataGridCellTapDetails details) {
    if (details.rowColumnIndex.rowIndex > 0) {
      try {
        final row =
            dataSource.effectiveRows[details.rowColumnIndex.rowIndex - 1];
        final webIdCell =
            row.getCells().firstWhere((c) => c.columnName == 'WebParkingId');

        // Keressük a reservation-t a webParkingId alapján
        final ValidReservation? reservation =
            widget.reservations.cast<ValidReservation?>().firstWhere(
                  (r) => r?.webParkingId.toString() == webIdCell.value,
                  orElse: () => null,
                );

        dataSource.updateSelectedReservation(reservation);
        if (widget.onReservationSelected != null) {
          widget.onReservationSelected!(reservation);
        }
      } catch (e) {
        // Ha bármi hiba történik, állítsuk null-ra a kiválasztást
        dataSource.updateSelectedReservation(null);
        if (widget.onReservationSelected != null) {
          widget.onReservationSelected!(null);
        }
      }
    }
  }

  void handleRightClick(DataGridCellTapDetails details, BuildContext context) {
    if (details.rowColumnIndex.rowIndex > 0) {
      try {
        final row =
            dataSource.effectiveRows[details.rowColumnIndex.rowIndex - 1];
        final webIdCell =
            row.getCells().firstWhere((c) => c.columnName == 'WebParkingId');

        // Keressük a reservation-t a webParkingId alapján
        final ValidReservation? reservation =
            widget.reservations.cast<ValidReservation?>().firstWhere(
                  (r) => r?.webParkingId.toString() == webIdCell.value,
                  orElse: () => null,
                );

        dataSource.updateSelectedReservation(reservation);
        if (widget.onReservationSelected != null) {
          widget.onReservationSelected!(reservation);
        }
      } catch (e) {
        // Ha bármi hiba történik, állítsuk null-ra a kiválasztást
        dataSource.updateSelectedReservation(null);
        if (widget.onReservationSelected != null) {
          widget.onReservationSelected!(null);
        }
      }
    }
    if (widget.onRightClick != null) {
      widget.onRightClick!();
    }
  }

  /// Fejléc cellák stílusa
  GridColumn buildColumn(String name, String labelText) {
    return GridColumn(
      // width: columnWidths[name]!,
      // minimumWidth: 100,
      // maximumWidth: 300,

      columnName: name,
      label: Container(
        //color: AppColors.accent,
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

/// Adatforrás az SfDataGrid számára
class ReservationDataSource extends DataGridSource {
  ReservationDataSource({
    required this.reservations,
    this.selectedReservation,
  }) {
    _rows = reservations.map<DataGridRow>((r) {
      return DataGridRow(cells: [
        DataGridCell<String>(
            columnName: 'Partner_Sortname', value: r.partner_Sortname),
        DataGridCell<String>(columnName: 'LicensePlate', value: r.licensePlate),
        DataGridCell<String>(
            columnName: 'ArticleNameHUN', value: r.articleNameHUN),
        DataGridCell<String>(
            columnName: 'ArriveDate',
            value: DateFormat('yyyy.MM.dd HH:mm').format(r.arriveDate)),
        DataGridCell<String>(
            columnName: 'LeaveDate',
            value: DateFormat('yyyy.MM.dd HH:mm').format(r.leaveDate)),
        DataGridCell<String>(columnName: 'Email', value: r.email.toString()),
        DataGridCell<String>(columnName: 'Phone', value: r.phone.toString()),
        DataGridCell<String>(columnName: 'State', value: r.state.toString()),
        DataGridCell<String>(
            columnName: 'WebParkingId', value: r.webParkingId.toString()),
        DataGridCell<String>(
            columnName: 'Description', value: r.description.toString()),
      ]);
    }).toList();
  }

  final List<ValidReservation> reservations;
  ValidReservation? selectedReservation;

  late List<DataGridRow> _rows;

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final int index = _rows.indexOf(row);
    final reservation = reservations[index];

    // selectedReservation összehasonlítás ID alapján
    bool isSelected = selectedReservation != null &&
        selectedReservation!.webParkingId == reservation.webParkingId;

    Color rowColor = isSelected
        ? Colors.grey.shade400
        : index.isEven
            ? Colors.grey.shade100
            : Colors.white;

    return DataGridRowAdapter(
      color: rowColor,
      cells: row.getCells().map((cell) {
        return Container(
          alignment: Alignment.center,
          child: Text(
            cell.value.toString(),
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              color: AppColors.text,
            ),
          ),
        );
      }).toList(),
    );
  }

  void updateSelectedReservation(ValidReservation? reservation) {
    selectedReservation = reservation;
    notifyListeners(); // újrarajzolja a gridet
  }
}
