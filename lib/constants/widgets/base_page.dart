import 'package:airport_test/constants/globals.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/widgets/side_drawer.dart';
import 'package:airport_test/responsive.dart';
import 'package:flutter/material.dart';

class BasePage extends StatelessWidget {
  final Widget child;
  final String pageTitle;
  final bool haveMargins;
  final SideDrawer? drawer;

  const BasePage({
    super.key,
    required this.child,
    required this.pageTitle,
    this.haveMargins = false,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    IsMobile = Responsive.isMobile(context);

    return TooltipVisibility(
      visible: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(pageTitle),
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
        drawer: drawer,
        body: Center(
          child: !IsMobile!
              ? Row(
                  children: [
                    haveMargins
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
                    haveMargins
                        ? const Expanded(flex: 2, child: SizedBox())
                        : const SizedBox(),
                  ],
                )
              : Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: haveMargins ? 16.0 : 0.0,
                  ),
                  child: Column(
                    children: [
                      Expanded(child: child),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
