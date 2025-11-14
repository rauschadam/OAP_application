import 'package:airport_test/constants/globals.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/widgets/side_drawer.dart';
import 'package:airport_test/constants/responsive.dart';
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

  Widget _buildLeadingWidget(BuildContext context, SideDrawer? drawer) {
    if (drawer != null) {
      // 1. Eset: Van Drawer -> "Menü" gomb (ezt csináltuk korábban)
      return Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menü',
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      );
    } else if (Navigator.canPop(context)) {
      // 2. Eset: Nincs Drawer, de vissza tud lépni -> "Vissza" gomb
      return IconButton(
        icon:
            const BackButtonIcon(), // Ez az alapértelmezett "vissza" nyíl ikon
        tooltip: 'Vissza',
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
    } else {
      // 3. Eset: Nincs Drawer, nem tud visszalépni -> Nincs gomb
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    IsMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,

        automaticallyImplyLeading: false, // Saját leading
        leading: _buildLeadingWidget(context, drawer),
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
        child: !IsMobile
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
    );
  }
}
