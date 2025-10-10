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

/// Foglalás opciók dialógus (jobb klikk menü)
Future<void> showReservationOptionsDialog(
  BuildContext context,
  ValidReservation reservation, {
  required Future<void> Function(String licensePlate) onArrival,
  required Future<void> Function(String licensePlate) onLeave,
  required Future<void> Function(int webParkingId, String newLicensePlate)
      onChangeLicense,
}) async {
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mégsem'),
          ),
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
          if (reservation.state == 0 || reservation.state == 4)
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
        ],
      );
    },
  );
}
