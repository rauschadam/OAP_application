import 'package:flutter/material.dart';

class BasePage extends StatelessWidget {
  final String title;
  final Widget child;

  const BasePage({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class NextPageButton extends StatelessWidget {
  final String text;
  final String title;
  final Widget? nextPage;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;

  const NextPageButton(
      {super.key,
      this.text = "Tovább",
      required this.title,
      this.nextPage,
      this.onPressed,
      this.focusNode});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            focusNode: focusNode,
            onPressed: () {
              if (onPressed != null) {
                onPressed!();
              }
              if (nextPage != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BasePage(title: title, child: nextPage!)),
                );
              }
            },
            child: Text(text),
          ),
        ),
      ),
    );
  }
}
