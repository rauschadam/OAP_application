// ignore_for_file: file_names

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
  final Widget nextPage;
  final VoidCallback? onPressedExtra;
  final FocusNode? focusNode;

  const NextPageButton(
      {super.key,
      this.text = "Tovább",
      required this.title,
      required this.nextPage,
      this.onPressedExtra,
      this.focusNode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          focusNode: focusNode,
          onPressed: () {
            if (onPressedExtra != null) {
              onPressedExtra!();
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => BasePage(title: title, child: nextPage)),
            );
          },
          child: Text(text),
        ),
      ),
    );
  }
}
