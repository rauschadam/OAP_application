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
