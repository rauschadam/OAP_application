import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';

class SideMenu extends StatefulWidget {
  final List<MenuItem> menuItems;

  const SideMenu({super.key, required this.menuItems});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  int? hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Container(
        color: AppColors.secondary,
        child: Padding(
          padding: const EdgeInsets.only(top: AppPadding.large),
          child: ListView.builder(
            itemCount: widget.menuItems.length,
            itemBuilder: (context, index) {
              final item = widget.menuItems[index];
              final isHovered = hoveredIndex == index;

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => hoveredIndex = index),
                onExit: (_) => setState(() => hoveredIndex = null),
                child: GestureDetector(
                  onTap: item.onPressed,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppPadding.medium,
                        vertical: AppPadding.small),
                    color: isHovered
                        ? AppColors.primary.withAlpha(40)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        Icon(item.icon, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          item.title,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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

/// Ha esetleg szeretnénk, hogy mindig lássuk a bal oldali menüt, ez jó megoldás lehet ->

// class SideNavigationRail extends StatefulWidget {
//   final List<MenuItem> menuItems;
//   final int initialIndex;

//   const SideNavigationRail({
//     super.key,
//     required this.menuItems,
//     this.initialIndex = 0,
//   });

//   @override
//   State<SideNavigationRail> createState() => _SideNavigationRailState();
// }

// class _SideNavigationRailState extends State<SideNavigationRail> {
//   late int selectedIndex;

//   @override
//   void initState() {
//     super.initState();
//     selectedIndex = widget.initialIndex;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return NavigationRail(
//       backgroundColor: BasePage.defaultColors.secondary,
//       selectedIndex: selectedIndex,
//       onDestinationSelected: (index) {
//         setState(() {
//           selectedIndex = index;
//         });
//         widget.menuItems[index].onPressed();
//       },
//       labelType: NavigationRailLabelType.all, // mindig mutatja a szöveget
//       selectedIconTheme: IconThemeData(
//         color: BasePage.defaultColors.primary,
//       ),
//       unselectedIconTheme: IconThemeData(
//         color: BasePage.defaultColors.primary.withAlpha(150),
//       ),
//       selectedLabelTextStyle: TextStyle(
//         color: BasePage.defaultColors.primary,
//         fontWeight: FontWeight.bold,
//       ),
//       unselectedLabelTextStyle: TextStyle(
//         color: BasePage.defaultColors.primary.withAlpha(150),
//       ),
//       destinations: widget.menuItems.map((item) {
//         return NavigationRailDestination(
//           icon: Icon(item.icon),
//           selectedIcon: Icon(item.icon),
//           label: Text(item.title),
//         );
//       }).toList(),
//     );
//   }
// }
