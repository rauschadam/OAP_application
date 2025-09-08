import 'package:airport_test/constants/constant_widgets/base_page.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:flutter/material.dart';

class NextPageButton extends StatelessWidget {
  final String text;
  final Widget? nextPage;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool showBackButton;

  const NextPageButton({
    super.key,
    this.text = "Tovább",
    this.nextPage,
    this.onPressed,
    this.focusNode,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppPadding.small),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          style: ButtonStyle(
            backgroundColor:
                WidgetStateProperty.all(BasePage.defaultColors.primary),
            foregroundColor:
                WidgetStateProperty.all(BasePage.defaultColors.background),
          ),
          focusNode: focusNode,
          onPressed: () {
            if (onPressed != null) {
              onPressed!();
            }
            if (nextPage != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => BasePage(
                          colors: BasePage.defaultColors,
                          child: nextPage!,
                        )),
              );
            }
          },
          child: Text(
            text,
          ),
        ),
      ),
    );
  }
}
