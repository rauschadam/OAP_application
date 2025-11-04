import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';

/// Rendszám módosító dialógus
Future<void> uploadToBalanceDialog(
  BuildContext context,
  String partnerId,
) async {
  final TextEditingController balanceController =
      TextEditingController(text: "0");

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Egyenleg feltöltése'),
        content: TextField(
          controller: balanceController,
          decoration: const InputDecoration(
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
            onPressed: () async {
              final int uploadVolume = int.parse(balanceController.text.trim());
              if (uploadVolume != 0) {
                final api = ApiService();
                await api.UploadBalance(context, partnerId, uploadVolume);
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Feltöltés'),
          ),
        ],
      );
    },
  );
}
