import 'package:airport_test/constants/navigation.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';

class NextPageButton extends StatelessWidget {
  final String text;
  final Widget? nextPage;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool pushAndRemoveAll;
  final bool isLoading;

  const NextPageButton({
    super.key,
    this.text = "Tovább",
    this.nextPage,
    this.onPressed,
    this.focusNode,
    this.pushAndRemoveAll = true,
    this.isLoading = false,
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
            onPressed: isLoading
                ? null
                : () {
                    if (onPressed != null) {
                      onPressed!();
                    }
                    if (nextPage != null) {
                      if (pushAndRemoveAll) {
                        Navigation(context: context, page: nextPage!)
                            .pushAndRemoveAll();
                        return;
                      } else {
                        Navigation(context: context, page: nextPage!).push();
                      }
                    }
                  },
            child: isLoading // Betöltésjelző
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.background,
                      strokeWidth: 3,
                    ),
                  )
                : Text(
                    text,
                  ),
          ),
        ),
      ),
    );
  }
}
