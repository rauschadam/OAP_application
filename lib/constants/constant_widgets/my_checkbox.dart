import 'package:airport_test/constants/constant_widgets/base_page.dart';
import 'package:flutter/material.dart';

class MyCheckBox extends StatelessWidget {
  final bool value;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final ValueChanged<bool?> onChanged;
  const MyCheckBox({
    super.key,
    required this.value,
    required this.focusNode,
    this.nextFocus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      focusNode: focusNode,
      onChanged: (value) {
        nextFocus != null
            ? FocusScope.of(context).requestFocus(nextFocus)
            : FocusScope.of(context).unfocus();
        onChanged(value ?? false);
      },
      activeColor: BasePage.defaultColors.primary,
    );
  }
}
