import 'package:airport_test/constants/constant_widgets/base_page.dart';
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
        color: BasePage.defaultColors.secondary,
        child: Padding(
          padding: const EdgeInsets.only(top: AppPadding.xlarge),
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
                        ? BasePage.defaultColors.primary.withAlpha(40)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        Icon(item.icon, color: BasePage.defaultColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          item.title,
                          style: TextStyle(
                            color: BasePage.defaultColors.primary,
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
