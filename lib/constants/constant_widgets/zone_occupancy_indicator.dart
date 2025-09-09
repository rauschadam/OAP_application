import 'package:airport_test/constants/constant_widgets/base_page.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class ZoneOccupancyIndicator extends StatelessWidget {
  final String zoneName;
  final int occupied;
  final int capacity;

  const ZoneOccupancyIndicator({
    super.key,
    required this.zoneName,
    required this.occupied,
    required this.capacity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          zoneName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 5),
        CircularPercentIndicator(
          radius: 50,
          lineWidth: 18,
          percent: occupied / capacity,
          progressColor: BasePage.defaultColors.primary, //Colors.blue,
          backgroundColor: Colors.blue.shade400, //Colors.blue.shade100,
          circularStrokeCap: CircularStrokeCap.round,
          center: Text(
            "$occupied / $capacity",
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
