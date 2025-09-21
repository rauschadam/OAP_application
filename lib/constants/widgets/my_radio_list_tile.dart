import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';

class MyRadioListTile<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final bool? dense;
  final Widget? leading;

  const MyRadioListTile(
      {super.key,
      required this.title,
      this.subtitle,
      required this.value,
      required this.groupValue,
      required this.onChanged,
      this.dense,
      this.leading});

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(
      title: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 8),
          ],
          Text(title),
        ],
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return BasePage.defaultColors.secondary
                .withValues(alpha: 0.3); // splash szín
          }
          return null;
        },
      ),
      activeColor: BasePage.defaultColors.primary,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.large)),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      dense: dense,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
