import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class ShimmerPlaceholderTemplate extends StatelessWidget {
  final double width;
  final double height;
  final Widget? child;

  const ShimmerPlaceholderTemplate(
      {super.key, required this.width, required this.height, this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
        child: Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.large)),
      width: width,
      height: height,
      child: child,
    ));
  }
}
