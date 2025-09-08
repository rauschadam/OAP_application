import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';

class BasePage extends StatelessWidget {
  static AppColors defaultColors = AppColors.blue;

  final Widget child;
  final AppColors? colors;

  const BasePage({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    final effectiveColors = colors ?? defaultColors;

    return Scaffold(
      appBar: AppBar(
        title: Text((child as PageWithTitle).pageTitle),
        automaticallyImplyLeading: (child as PageWithTitle).showBackButton,
        backgroundColor: effectiveColors.background,
        foregroundColor: effectiveColors.text,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[300],
            height: 1,
          ),
        ),
      ),
      backgroundColor: effectiveColors.background,
      body: Center(
        child: Row(
          children: [
            (child as PageWithTitle).haveMargins
                ? Expanded(child: Container())
                : Container(),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(child: child),
                ],
              ),
            ),
            (child as PageWithTitle).haveMargins
                ? Expanded(child: Container())
                : Container(),
          ],
        ),
      ),
    );
  }
}

mixin PageWithTitle {
  String get pageTitle;
  bool get showBackButton => true;
  bool get haveMargins => true;
}
