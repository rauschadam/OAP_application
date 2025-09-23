import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/responsive.dart';
import 'package:flutter/material.dart';

class BasePage extends StatelessWidget {
  static AppColors defaultColors = AppColors.blue;

  final Widget child;
  final AppColors? colors;

  const BasePage({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    if (colors != null) {
      defaultColors = colors!;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text((child as PageWithTitle).pageTitle),
        automaticallyImplyLeading: (child as PageWithTitle).showBackButton,
        backgroundColor: defaultColors.background,
        foregroundColor: defaultColors.text,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[300],
            height: 1,
          ),
        ),
      ),
      backgroundColor: defaultColors.background,
      body: Center(
        child: Responsive.isDesktop(context)
            ? Row(
                children: [
                  (child as PageWithTitle).haveMargins
                      ? const Expanded(flex: 2, child: SizedBox())
                      : const SizedBox(),
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Expanded(child: child),
                      ],
                    ),
                  ),
                  (child as PageWithTitle).haveMargins
                      ? const Expanded(flex: 2, child: SizedBox())
                      : const SizedBox(),
                ],
              )
            : Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: (child as PageWithTitle).haveMargins ? 16.0 : 0.0,
                ),
                child: Column(
                  children: [
                    Expanded(child: child),
                  ],
                ),
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
