import 'package:airport_test/constants/constant_widgets/base_page.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final List<MenuItem> menuItems;

  const SideMenu({super.key, required this.menuItems});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Container(
        color: BasePage.defaultColors.secondary,
        child: Padding(
          padding: const EdgeInsets.only(top: AppPadding.xlarge),
          child: ListView(
            children: [
              ...menuItems.map((item) => ListTile(
                    leading:
                        Icon(item.icon, color: BasePage.defaultColors.primary),
                    title: Text(
                      item.title,
                      style: TextStyle(
                          color: BasePage.defaultColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                    onTap: item.onPressed,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onPressed;

  MenuItem({
    required this.icon,
    required this.title,
    required this.onPressed,
  });
}
