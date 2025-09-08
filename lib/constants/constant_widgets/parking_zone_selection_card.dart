import 'package:airport_test/constants/constant_widgets/base_page.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ParkingZoneSelectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int costPerDay;
  final int parkingDays;
  final bool selected;
  final VoidCallback onTap;
  final bool available;

  const ParkingZoneSelectionCard(
      {super.key,
      required this.title,
      this.subtitle,
      required this.costPerDay,
      required this.parkingDays,
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
                "A foglalni kívánt intervallum telített foglaltságúidőpontokat tartalmaz ebben a zónában. Válasszon másik parkoló zónát vagy változtasson az érkezési és távozási időpontokon."),
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
    final int parkingCost = costPerDay * parkingDays;
    final formattedParkingCost =
        NumberFormat('#,###', 'hu_HU').format(parkingCost);
    final formattedCostPerDay =
        NumberFormat('#,###', 'hu_HU').format(costPerDay);
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
                padding: const EdgeInsets.symmetric(
                    horizontal: AppPadding.small,
                    vertical: AppPadding.extraSmall),
                decoration: BoxDecoration(
                  color: selected
                      ? BasePage.defaultColors.secondary
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
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
              subtitle != null ? const SizedBox(height: 4) : Container(),
              subtitle != null
                  ? Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    )
                  : Container(),
              const SizedBox(height: 16),
              Text(
                "$formattedParkingCost Ft",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$formattedCostPerDay Ft / nap",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
