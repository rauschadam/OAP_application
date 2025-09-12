import 'package:flutter/material.dart';

/// Hiba megjelenítő pop-up dialog
void showErrorDialog(BuildContext context, String msg) {
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text("Hiba"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}
