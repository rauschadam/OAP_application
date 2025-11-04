// import 'package:airport_test/constants/globals.dart';
// import 'package:airport_test/constants/theme.dart';
// import 'package:flutter/material.dart';
// import 'package:airport_test/api_services/api_classes/valid_reservation.dart';

// /// Rendszám módosító dialógus
// Future<void> showChangeLicensePlateDialog(
//   BuildContext context,
//   ValidReservation reservation,
//   Future<void> Function(int webParkingId, String newLicensePlate) onSave,
// ) async {
//   final TextEditingController licensePlateController =
//       TextEditingController(text: reservation.licensePlate);

//   await showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: const Text('Rendszám módosítása'),
//         content: TextField(
//           controller: licensePlateController,
//           decoration: const InputDecoration(
//             labelText: 'Új rendszám',
//             border: OutlineInputBorder(),
//             fillColor: AppColors.secondary,
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Mégsem'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               final newPlate = licensePlateController.text.trim();
//               if (newPlate.isNotEmpty) {
//                 Navigator.of(context).pop();
//                 onSave(reservation.webParkingId, newPlate);
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.orange,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Mentés'),
//           ),
//         ],
//       );
//     },
//   );
// }

// /// Foglalás opciók dialógus
// Future<void> showReservationOptionsDialog(
//   BuildContext context,
//   ValidReservation reservation, {
//   required Future<void> Function(String licensePlate) onArrival,
//   required Future<void> Function(String licensePlate) onLeave,
//   required Future<void> Function(int webParkingId, String newLicensePlate)
//       onChangeLicense,
// }) async {
//   // Az actions lista elemeit itt tároljuk
//   final List<Widget> actionButtons = [
//     // Rendszám módosítása gomb
//     ElevatedButton(
//       onPressed: () {
//         Navigator.of(context).pop();
//         showChangeLicensePlateDialog(
//           context,
//           reservation,
//           onChangeLicense,
//         );
//       },
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.orange,
//         foregroundColor: Colors.white,
//       ),
//       child: const Text('Rendszám módosítása'),
//     ),
//     if (!IsMobile) const SizedBox(width: 8),

//     // Kiléptetés gomb
//     if (reservation.state == 1 || reservation.state == 2)
//       ElevatedButton(
//         onPressed: () {
//           Navigator.of(context).pop();
//           onLeave(reservation.licensePlate);
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.red,
//           foregroundColor: Colors.white,
//         ),
//         child: const Text('Kiléptetés'),
//       ),
//     if (!IsMobile && (reservation.state == 1 || reservation.state == 2))
//       const SizedBox(width: 8),

//     // Érkeztetés gomb
//     if (reservation.state == 0)
//       ElevatedButton(
//         onPressed: () {
//           Navigator.of(context).pop();
//           onArrival(reservation.licensePlate);
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.green,
//           foregroundColor: Colors.white,
//         ),
//         child: const Text('Érkeztetés'),
//       ),

//     if (!IsMobile) const SizedBox(width: 8),

//     // Mégsem gomb (mindkét esetben)
//     TextButton(
//       onPressed: () => Navigator.of(context).pop(),
//       child: const Text('Mégsem'),
//     ),
//   ];

//   await showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: const Text('Művelet kiválasztása'),
//         content: Text(
//           reservation.licensePlate,
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           textAlign: TextAlign.center,
//         ),
//         actions: [
//           if (IsMobile)
//             // Telefonon a gombok egymás alatt, középen, teljes szélességen
//             Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment:
//                   CrossAxisAlignment.stretch, // Kitölti a szélességet
//               children: actionButtons.map((widget) {
//                 // Gombok
//                 if (widget is ElevatedButton) {
//                   return Padding(
//                     padding: const EdgeInsets.only(bottom: 8.0),
//                     child: widget,
//                   );
//                 }
//                 // Mégsem
//                 if (widget is TextButton) {
//                   return Align(
//                     alignment: Alignment.bottomRight,
//                     child: widget,
//                   );
//                 }
//                 return widget; // SizedBox
//               }).toList(),
//             )
//           else
//             ...actionButtons,
//         ],
//       );
//     },
//   );
// }

// lib/constants/dialogs/reservation_options_dialog.dart

import 'package:airport_test/api_services/api_classes/platform_setting.dart'; //
import 'package:airport_test/constants/globals.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:airport_test/api_services/api_classes/valid_reservation.dart';

/// Rendszám módosító dialógus
Future<void> showChangeLicensePlateDialog(
  BuildContext context,
  ValidReservation reservation,
  Future<void> Function(int webParkingId, String newLicensePlate) onSave,
) async {
  final TextEditingController licensePlateController =
      TextEditingController(text: reservation.licensePlate);

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Rendszám módosítása'),
        content: TextField(
          controller: licensePlateController,
          decoration: const InputDecoration(
            labelText: 'Új rendszám',
            border: OutlineInputBorder(),
            fillColor: AppColors.secondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mégsem'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPlate = licensePlateController.text.trim();
              if (newPlate.isNotEmpty) {
                Navigator.of(context).pop();
                onSave(reservation.webParkingId, newPlate);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mentés'),
          ),
        ],
      );
    },
  );
}

/// Foglalás opciók dialógus
Future<void> showReservationOptionsDialog(
  BuildContext context,
  ValidReservation reservation, {
  required Future<void> Function(String licensePlate) onArrival,
  required Future<void> Function(String licensePlate) onLeave,
  required Future<void> Function(int webParkingId, String newLicensePlate)
      onChangeLicense,
}) async {
  // Az actions lista elemeit itt tároljuk
  final List<Widget> actionButtons = [
    // Rendszám módosítása gomb
    ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop();
        showChangeLicensePlateDialog(
          context,
          reservation,
          onChangeLicense,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      child: const Text('Rendszám módosítása'),
    ),
    if (!IsMobile) const SizedBox(width: 8),

    // Kiléptetés gomb
    if (reservation.state == 1 || reservation.state == 2)
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          onLeave(reservation.licensePlate);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        child: const Text('Kiléptetés'),
      ),
    if (!IsMobile && (reservation.state == 1 || reservation.state == 2))
      const SizedBox(width: 8),

    // Érkeztetés gomb
    if (reservation.state == 0)
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          onArrival(reservation.licensePlate);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        child: const Text('Érkeztetés'),
      ),

    if (!IsMobile) const SizedBox(width: 8),

    // Mégsem gomb (mindkét esetben)
    TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Mégsem'),
    ),
  ];

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Művelet kiválasztása'),
        content: Text(
          reservation.licensePlate,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        actions: [
          if (IsMobile)
            // Telefonon a gombok egymás alatt, középen, teljes szélességen
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Kitölti a szélességet
              children: actionButtons.map((widget) {
                // Gombok
                if (widget is ElevatedButton) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: widget,
                  );
                }
                // Mégsem
                if (widget is TextButton) {
                  return Align(
                    alignment: Alignment.bottomRight,
                    child: widget,
                  );
                }
                return widget; // SizedBox
              }).toList(),
            )
          else
            ...actionButtons,
        ],
      );
    },
  );
}

/// Foglalás részletek megjelenítése (mobil sheet vagy desktop dialógus, akció gombokkal)
Future<void> showReservationDetails(
  BuildContext context,
  ValidReservation reservation, {
  required Future<void> Function(String licensePlate) onArrival,
  required Future<void> Function(String licensePlate) onLeave,
  required Future<void> Function(int webParkingId, String newLicensePlate)
      onChangeLicense,
  List<PlatformSetting>? detailFields,
}) async {
  if (detailFields == null || detailFields.isEmpty) {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Foglalás Részletei'),
        content: const Text(
            'Nem sikerült betölteni a megjelenítendő mezőket. Kérem, frissítse az oldalt.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK')),
        ],
      ),
    );
    return;
  }

  // DINAMIKUS MEZŐK ÉPÍTÉSE
  final List<Widget> detailWidgets =
      detailFields.where((field) => field.fieldVisible).map((field) {
    // Lekérjük a ValidReservation osztályból a fieldName-hez tartozó formázott értéket
    final String value = reservation.getValue(reservation, field.listFieldName);
    // A megjelenítendő címke: fieldCaption, ha van, különben listFieldName
    final String caption = field.fieldCaption ?? field.listFieldName;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Címke (caption)
          Expanded(
            flex: 2,
            child: Text(
              "$caption:",
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Érték (value)
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }).toList();

  // Akció gombok
  final List<Widget> actionButtons = [
    ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop();
        showChangeLicensePlateDialog(
          context,
          reservation,
          onChangeLicense,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 40),
      ),
      child: const Text('Rendszám módosítása'),
    ),
    const SizedBox(height: 8),
    if (reservation.state == 1 || reservation.state == 2) ...[
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          onLeave(reservation.licensePlate);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 40),
        ),
        child: const Text('Kiléptetés'),
      ),
      const SizedBox(height: 8),
    ],
    if (reservation.state == 0) ...[
      ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          onArrival(reservation.licensePlate);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 40),
        ),
        child: const Text('Érkeztetés'),
      ),
      const SizedBox(height: 8),
    ],
  ];

  Widget content = SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...detailWidgets,
        const SizedBox(height: AppPadding.medium),
        ...actionButtons,
        if (IsMobile)
          SafeArea(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
              ),
              child: const Text("Bezárás"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
      ],
    ),
  );

  // Mobilon
  if (IsMobile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppBorderRadius.large)),
      ),
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppPadding.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 100,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  "Foglalás Részletei",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                Divider(height: AppPadding.large),
                Expanded(child: content),
              ],
            ),
          ),
        );
      },
    );
  } else {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Foglalás Részletei'),
          content: Container(
            width: 450,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: content,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bezárás'),
            ),
          ],
        );
      },
    );
  }
}
