import 'package:airport_test/Pages/homePage/homePage.dart';
import 'package:airport_test/Pages/listPanelPage/listPanelPage.dart';
import 'package:airport_test/api_services/api_classes/available_list_panel.dart';
import 'package:airport_test/constants/globals.dart';
import 'package:airport_test/constants/navigation.dart';
import 'package:flutter/material.dart';
import 'package:airport_test/constants/theme.dart';

class SideDrawer extends StatelessWidget {
  final String currentTitle;

  const SideDrawer({
    super.key,
    required this.currentTitle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        backgroundColor: AppColors.background,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 80,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  "Orha Airport Parking",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ),
            SideMenuTile(
              title: "Fő oldal",
              destination: HomePage(),
              currentTitle: currentTitle,
            ),
            for (final panel in AvailableListPanels)
              SideMenuTile(
                listPanel: panel,
                currentTitle: currentTitle,
              ),
          ],
        ),
      ),
    );
  }
}

class SideMenuTile extends StatelessWidget {
  final String? title;
  final AvailableListPanel? listPanel;
  final dynamic destination;
  final String currentTitle;

  const SideMenuTile({
    super.key,
    this.title,
    this.listPanel,
    this.destination,
    required this.currentTitle,
  });

  @override
  Widget build(BuildContext context) {
    final tileTitle = title ?? listPanel!.listPanelName;
    final bool isActive = tileTitle == currentTitle;
    return ListTile(
      tileColor: isActive ? AppColors.primary : Colors.transparent,
      title: Text(
        title ?? listPanel!.listPanelName,
        style: TextStyle(
          color: isActive ? AppColors.background : AppColors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        destination != null
            ? Navigation(context: context, page: destination).pushAndRemoveAll()
            : Navigation(
                    context: context,
                    page: ListPanelPage(listPanel: listPanel!))
                .pushAndRemoveAll();
      },
      hoverColor: AppColors.primary.withAlpha(25),
      splashColor: AppColors.primary.withAlpha(50),
    );
  }
}
