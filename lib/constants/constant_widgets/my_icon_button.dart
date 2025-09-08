import 'package:airport_test/constants/constant_widgets/base_page.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';

class MyIconButton extends StatelessWidget {
  final IconData icon;
  final String labelText;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

  const MyIconButton({
    super.key,
    required this.icon,
    required this.labelText,
    required this.onPressed,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: BasePage.defaultColors.primary,
        padding: const EdgeInsets.all(AppPadding.medium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.small),
        ),
      ),
      icon: Icon(
        icon,
        color: BasePage.defaultColors.background,
      ),
      label: Text(
        labelText,
        style: TextStyle(
          color: BasePage.defaultColors.background,
        ),
      ),
      focusNode: focusNode,
      onPressed: () {
        onPressed();
      },
    );
  }
}
