import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';

class MyIconButton extends StatelessWidget {
  final IconData icon;
  final String labelText;
  final VoidCallback onPressed;
  final FocusNode? focusNode;
  final Color? textColor;
  final Color? backgroundColor;

  const MyIconButton(
      {super.key,
      required this.icon,
      required this.labelText,
      required this.onPressed,
      this.focusNode,
      this.textColor,
      this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primary,
        padding: const EdgeInsets.all(AppPadding.medium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.small),
        ),
      ),
      icon: Icon(
        icon,
        color: textColor ?? AppColors.background,
      ),
      label: Text(
        labelText,
        style: TextStyle(
          color: textColor ?? AppColors.background,
        ),
      ),
      focusNode: focusNode,
      onPressed: () {
        onPressed();
      },
    );
  }
}
