import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:flutter/material.dart';

class MySearchBar extends StatelessWidget {
  final SearchController searchController;
  final FocusNode? searchFocus;
  final Widget? trailingWidgets;

  const MySearchBar(
      {super.key,
      required this.searchController,
      this.searchFocus,
      this.trailingWidgets});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 35,
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: BasePage.defaultColors.background,
          ),
        ),
        child: SearchBar(
          focusNode: searchFocus,
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          backgroundColor:
              WidgetStateProperty.all(BasePage.defaultColors.primary),
          hintStyle: WidgetStateProperty.all<TextStyle>(
            TextStyle(
              color: BasePage.defaultColors.background.withAlpha(200),
              fontWeight: FontWeight.w600,
            ),
          ),
          textStyle: WidgetStateProperty.all<TextStyle>(
            TextStyle(
              color: BasePage.defaultColors.background,
              fontWeight: FontWeight.w600,
            ),
          ),
          controller: searchController,
          hintText: 'Keresés...',
          leading: Icon(
            Icons.search,
            size: 20,
            color: BasePage.defaultColors.background,
          ),
          trailing: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: BasePage.defaultColors.background,
                    ),
                    constraints: BoxConstraints(),
                    onPressed: () {
                      searchController.clear();
                    },
                  ),
                if (trailingWidgets != null) trailingWidgets!
              ],
            )
          ],
        ),
      ),
    );
  }
}

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
