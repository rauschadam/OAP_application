// import 'package:airport_test/constants/theme.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class ReservationList extends StatelessWidget {
//   final List<dynamic> reservations;
//   final String listTitle;
//   final Map<String, String> columns;
//   final Map<String, String Function(dynamic)>? formatters;
//   final double? maxHeight;

//   const ReservationList(
//       {super.key,
//       required this.reservations,
//       required this.listTitle,
//       required this.columns,
//       this.formatters,
//       this.maxHeight});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(AppPadding.medium),
//       decoration: BoxDecoration(
//         borderRadius:
//             const BorderRadius.all(Radius.circular(AppBorderRadius.small)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           buildListTitle(listTitle, context),
//           SizedBox(height: 16),
//           reservations.isEmpty
//               ? Container(
//                   padding: EdgeInsets.all(AppBorderRadius.small),
//                   width: double.infinity,
//                   child: Text('Nincsenek foglalások'))
//               : Column(
//                   children: [
//                     // Táblázat fejléc (rögzített)
//                     buildColumnTitles(columns),
//                     // Görgethető tartalom
//                     buildRows(reservations)
//                   ],
//                 )
//         ],
//       ),
//     );
//   }

//   Widget buildListTitle(String listTitle, context) {
//     return Padding(
//       padding: const EdgeInsets.only(left: AppPadding.small),
//       child: Text(
//         listTitle,
//         style: Theme.of(context).textTheme.titleMedium,
//       ),
//     );
//   }

//   Widget buildColumnTitles(Map<String, String> columns) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//           vertical: AppPadding.small, horizontal: AppPadding.medium),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade300,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(AppBorderRadius.small),
//           topRight: Radius.circular(AppBorderRadius.small),
//         ),
//       ),
//       child: Row(
//         children: [
//           for (var columnTitles in columns.keys)
//             Expanded(
//               child: Text(
//                 columnTitles,
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget buildRows(List<dynamic> reservations) {
//     return ConstrainedBox(
//       constraints: BoxConstraints(maxHeight: maxHeight ?? double.infinity),
//       child: Container(
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.grey.shade300),
//         ),
//         child: ListView.separated(
//           shrinkWrap: true,
//           itemCount: reservations.length,
//           separatorBuilder: (context, index) => Divider(height: 1),
//           itemBuilder: (context, index) {
//             return Container(
//               padding: EdgeInsets.symmetric(
//                   vertical: AppPadding.small, horizontal: AppPadding.medium),
//               color: index.isEven ? Colors.grey.shade50 : Colors.white,
//               child: Row(
//                 children: [
//                   for (var dataSource in columns.values)
//                     Expanded(
//                       child: buildCells(reservations[index], dataSource),
//                     ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget buildCells(dynamic reservation, String dataSource) {
//     // Ha van formázó függvény ehhez a mezőhöz, akkor azt használjuk
//     if (formatters != null && formatters!.containsKey(dataSource)) {
//       return Text(formatters![dataSource]!(reservation));
//     }

//     // Alapértelmezett megjelenítés
//     final value = reservation[dataSource];
//     if (value == null) return Text('-');

//     // Dátum mezők automatikus formázása
//     if (dataSource.toLowerCase().contains('date')) {
//       try {
//         final date = DateTime.parse(value.toString());
//         return Text(DateFormat('yyyy.MM.dd HH:mm').format(date));
//       } catch (e) {
//         return Text(value.toString());
//       }
//     }

//     return Text(value.toString());
//   }
// }

import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservationList extends StatefulWidget {
  final List<dynamic> reservations;
  final String listTitle;
  final Map<String, String> columns;
  final Map<String, String Function(dynamic)>? formatters;
  final double? maxHeight;
  final Function(dynamic)? onRowTap;

  const ReservationList(
      {super.key,
      required this.reservations,
      required this.listTitle,
      required this.columns,
      this.formatters,
      this.maxHeight,
      this.onRowTap});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildListTitle(widget.listTitle, context),
          SizedBox(height: 16),
          widget.reservations.isEmpty
              ? Container(
                  padding: EdgeInsets.all(AppBorderRadius.small),
                  width: double.infinity,
                  child: Text('Nincsenek foglalások'))
              : Column(
                  children: [
                    // Táblázat fejléc (rögzített)
                    buildColumnTitles(widget.columns),
                    // Görgethető tartalom
                    buildRows(widget.reservations)
                  ],
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
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: widget.maxHeight ?? double.infinity),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              for (int index = 0; index < reservations.length; index++)
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          selectedReservation = reservations[index];
                        });
                        if (widget.onRowTap != null) {
                          widget.onRowTap!(reservations[index]);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: AppPadding.small,
                            horizontal: AppPadding.medium),
                        color: getRowColor(reservations[index], index),
                        child: Row(
                          children: [
                            for (var dataSource in widget.columns.values)
                              Expanded(
                                child:
                                    buildCells(reservations[index], dataSource),
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
        ),
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
