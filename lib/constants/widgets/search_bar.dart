import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:flutter/material.dart';

class SearchBarContainer extends StatelessWidget {
  final bool transparency;
  final Key? searchContainerKey;
  final List<Widget> children;

  const SearchBarContainer({
    super.key,
    this.transparency = true,
    this.searchContainerKey,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: searchContainerKey,
      decoration: BoxDecoration(
        border: Border.all(
          color: transparency
              ? BasePage.defaultColors.primary
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        color: transparency ? Colors.white : Colors.transparent,
      ),
      padding: EdgeInsets.all(AppPadding.small),
      child: Column(
        children: children,
      ),
    );
  }
}
