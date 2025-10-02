import 'package:airport_test/constants/globals.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/responsive.dart';
import 'package:flutter/material.dart';

class BasePage extends StatelessWidget {
  final Widget child;

  const BasePage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    IsMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text((child as PageWithTitle).pageTitle),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[300],
            height: 1,
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: Center(
        child: !IsMobile!
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
  bool get haveMargins => true;
}
