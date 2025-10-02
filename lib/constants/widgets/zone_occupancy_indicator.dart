import 'package:airport_test/constants/theme.dart';
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
    final double percent = occupied / capacity;
    return Column(
      children: [
        Text(
          zoneName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 5),
        CircularPercentIndicator(
          radius: 45,
          lineWidth: 18,
          percent: percent > 1.0 ? 1.0 : percent,
          progressColor: AppColors.primary,
          backgroundColor: Colors.blue.shade400,
          circularStrokeCap: CircularStrokeCap.round,
          center: Text(
            "$occupied / $capacity",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
