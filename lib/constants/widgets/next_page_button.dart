import 'package:airport_test/constants/navigation.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';

class NextPageButton extends StatelessWidget {
  final String text;
  final Widget? nextPage;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool pushReplacement;

  const NextPageButton({
    super.key,
    this.text = "Tovább",
    this.nextPage,
    this.onPressed,
    this.focusNode,
    this.pushReplacement = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: AppPadding.small),
        child: Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(AppColors.primary),
              foregroundColor: WidgetStateProperty.all(AppColors.background),
            ),
            focusNode: focusNode,
            onPressed: () {
              if (onPressed != null) {
                onPressed!();
              }
              if (nextPage != null) {
                if (pushReplacement) {
                  Navigation(context: context, page: nextPage!)
                      .pushReplacement();
                  return;
                } else {
                  Navigation(context: context, page: nextPage!).push();
                }
              }
            },
            child: Text(
              text,
            ),
          ),
        ),
      ),
    );
  }
}
