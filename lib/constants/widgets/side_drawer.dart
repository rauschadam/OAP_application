import 'package:airport_test/Pages/genericListPanelPage.dart';
import 'package:airport_test/Pages/homePage.dart';
import 'package:airport_test/Pages/reservationListPage.dart';
import 'package:airport_test/api_services/api_classes/available_list_panel.dart';
import 'package:airport_test/constants/globals.dart';
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
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: AppColors.secondary,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 55,
          ),
          SideMenuTile(
            title: "Menü",
            destination: HomePage(),
            currentTitle: currentTitle,
          ),
          SideMenuTile(
            title: "Foglalások",
            destination: ReservationListPage(),
            currentTitle: currentTitle,
          ),
          for (final panel in AvailableListPanels)
            SideMenuTile(
              listPanel: panel,
              currentTitle: currentTitle,
            ),
        ],
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
            ? Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => destination,
                ),
              )
            : Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => GenericListPanelPage(listPanel: listPanel!),
                ),
              );
      },
      hoverColor: AppColors.primary.withOpacity(0.1),
      splashColor: AppColors.primary.withOpacity(0.2),
    );
  }
}
