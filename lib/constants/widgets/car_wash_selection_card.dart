import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CarWashSelectionCard extends StatelessWidget {
  final String title;
  final int washCost;
  final bool selected;
  final VoidCallback onTap;
  final bool available;

  const CarWashSelectionCard(
      {super.key,
      required this.title,
      required this.washCost,
      required this.selected,
      required this.onTap,
      this.available = true});

  void ShowUnavailableZoneDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nem foglalható"),
          content: SizedBox(
            width: 300,
            height: 100,
            child: const Text(
                "A foglalni kívánt időpont foglalt ebben a zónában. Válasszon másik típusú mosást vagy változtasson az időponton."),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedWashCost = NumberFormat('#,###', 'hu_HU').format(washCost);
    return InkWell(
      borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      onTap: () {
        if (available) {
          onTap();
        } else {
          ShowUnavailableZoneDialog(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppPadding.medium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          color: selected ? Colors.white : Colors.white,
          border: Border.all(
            color:
                selected ? BasePage.defaultColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Opacity(
          opacity: available ? 1.0 : 0.3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.small,
                    vertical: AppPadding.extraSmall),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  color: selected
                      ? BasePage.defaultColors.secondary
                      : Colors.grey[200],
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? BasePage.defaultColors.primary
                        : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "$formattedWashCost Ft",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
