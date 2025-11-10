import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Egyenleg feltöltő dialógus
Future<void> uploadToBalanceDialog(
  BuildContext
      context, // <-- Ez a 'PageContext', ezt használjuk az awesomeDialog-hoz
  String partnerId,
) async {
  final TextEditingController balanceController = TextEditingController();

  await showDialog(
    context: context, // A PageContext-et használjuk a showDialog-hoz
    builder: (BuildContext dialogContext) {
      // Ez a dialógus saját kontextusa ('DialogContext')

      // StatefulBuilder-t használunk, hogy a dialóguson belül legyen állapot (isLoading)
      return StatefulBuilder(
        builder: (BuildContext statefulContext, StateSetter setState) {
          bool isLoading = false;

          return AlertDialog(
            title: const Text('Egyenleg feltöltése'),
            content: TextField(
              controller: balanceController,
              autofocus: true,
              keyboardType: TextInputType.number, // Szám billentyűzet
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter
                    .digitsOnly // Csak számokat engedélyez
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                fillColor: AppColors.secondary,
              ),
              enabled: !isLoading, // Letiltjuk a mezőt töltés közben
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext)
                    .pop(), // A 'DialogContext'-et pop-oljuk
                child: const Text('Mégsem'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (balanceController.text.isEmpty) return;
                  final int uploadVolume =
                      int.parse(balanceController.text.trim());
                  if (uploadVolume == 0) return;

                  // Töltési állapot beállítása
                  setState(() {
                    isLoading = true;
                  });

                  final api = ApiService();

                  // 1. API hívás
                  final String? errorMessage =
                      await api.UploadBalance(partnerId, uploadVolume);

                  // 2. Ellenőrizzük, hogy a dialógus még "mounted"
                  if (!dialogContext.mounted) return;

                  // 3. Bezárjuk a feltöltő dialógust (DialogContext)
                  Navigator.of(dialogContext).pop();

                  // 4. Az EREDETI 'context'-en (PageContext)
                  // jelenítjük meg az eredményt.
                  if (errorMessage == null) {
                    // Siker
                    AwesomeDialog(
                      context:
                          context, // <-- Az eredeti 'PageContext' használata
                      width: 300,
                      dialogType: DialogType.success,
                      title: 'Sikeres egyenleg feltöltés',
                    ).show();
                  } else {
                    // Hiba
                    AwesomeDialog(
                      context:
                          context, // <-- Az eredeti 'PageContext' használata
                      width: 300,
                      dialogType: DialogType.error,
                      title: 'Egyenleg feltöltése sikertelen',
                      desc: errorMessage,
                    ).show();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                // Töltésjelző mutatása a gombon
                child: const Text('Feltöltés'),
              ),
            ],
          );
        },
      );
    },
  );
}
