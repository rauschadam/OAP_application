import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservationList extends StatefulWidget {
  final List<dynamic> reservations;
  final String listTitle;
  final Map<String, String> columns;
  final Map<String, String Function(dynamic)>? formatters;
  final double? maxHeight;
  final double? maxWidth;
  final Function(dynamic)? onRowTap;

  const ReservationList(
      {super.key,
      required this.reservations,
      required this.listTitle,
      required this.columns,
      this.formatters,
      this.maxHeight,
      this.onRowTap,
      this.maxWidth});

  @override
  State<ReservationList> createState() => _ReservationListState();
}

class _ReservationListState extends State<ReservationList> {
  dynamic selectedReservation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        borderRadius:
            const BorderRadius.all(Radius.circular(AppBorderRadius.small)),
      ),
      constraints: BoxConstraints(
          maxHeight: widget.maxHeight ?? double.infinity,
          maxWidth: widget.maxWidth ?? double.infinity),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          buildListTitle(widget.listTitle, context),
          SizedBox(height: 16),
          widget.reservations.isEmpty
              ? Container(
                  padding: EdgeInsets.all(AppBorderRadius.small),
                  width: double.infinity,
                  child: Text('Nincsenek foglalások'))
              : Flexible(
                  child: Column(
                    children: [
                      // Táblázat fejléc (rögzített)
                      buildColumnTitles(widget.columns),
                      // Görgethető tartalom
                      buildRows(widget.reservations)
                    ],
                  ),
                )
        ],
      ),
    );
  }

  Widget buildListTitle(String listTitle, context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppPadding.small),
      child: Text(
        listTitle,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget buildColumnTitles(Map<String, String> columns) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: AppPadding.small, horizontal: AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.blue.shade300,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.small),
          topRight: Radius.circular(AppBorderRadius.small),
        ),
      ),
      child: Row(
        children: [
          for (var columnTitles in columns.keys)
            Expanded(
              child: Text(
                columnTitles,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildRows(List<dynamic> reservations) {
    return Flexible(
      child: ListView(
        children: [
          for (int index = 0; index < reservations.length; index++)
            Column(
              children: [
                InkWell(
                  onTap: widget.onRowTap != null
                      ? () {
                          setState(() {
                            selectedReservation = reservations[index];
                          });
                          widget.onRowTap!(reservations[index]);
                        }
                      : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        vertical: AppPadding.small,
                        horizontal: AppPadding.medium),
                    decoration: BoxDecoration(
                      color: getRowColor(reservations[index], index),
                      borderRadius: index == reservations.length - 1
                          ? BorderRadius.only(
                              bottomLeft:
                                  Radius.circular(AppBorderRadius.small),
                              bottomRight:
                                  Radius.circular(AppBorderRadius.small),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        for (var dataSource in widget.columns.values)
                          Expanded(
                            child: buildCells(reservations[index], dataSource),
                          ),
                      ],
                    ),
                  ),
                ),
                if (index < reservations.length - 1) Divider(height: 1),
              ],
            ),
        ],
      ),
    );
  }

  Widget buildCells(dynamic reservation, String dataSource) {
    // Ha van formázó függvény ehhez a mezőhöz, akkor azt használjuk
    if (widget.formatters != null &&
        widget.formatters!.containsKey(dataSource)) {
      return Text(widget.formatters![dataSource]!(reservation));
    }

    // Alapértelmezett megjelenítés
    final value = reservation[dataSource];
    if (value == null) return Text('-');

    // Dátum mezők automatikus formázása
    if (dataSource.toLowerCase().contains('date')) {
      try {
        final date = DateTime.parse(value.toString());
        return Text(DateFormat('yyyy.MM.dd HH:mm').format(date));
      } catch (e) {
        return Text(value.toString());
      }
    }

    return Text(value.toString());
  }

  // Segédfüggvény a sor színének meghatározásához
  Color getRowColor(dynamic reservation, int index) {
    // Ha ez a kiválasztott foglalás, akkor szürkébb színnel jelöljük
    if (selectedReservation != null && reservation == selectedReservation) {
      return Colors.grey.shade300;
    }

    // Egyébként váltakozó színek
    return index.isEven ? Colors.grey.shade50 : Colors.white;
  }
}
