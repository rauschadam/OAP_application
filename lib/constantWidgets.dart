import 'package:flutter/material.dart';

enum BackGroundColor { white, blue }

class BasePage extends StatelessWidget {
  // Globális default enum
  static BackGroundColor defaultColorEnum = BackGroundColor.white;

  // Statikus getter a tényleges Color visszaadására
  static Color get defaultColor {
    switch (defaultColorEnum) {
      case BackGroundColor.blue:
        return Colors.blue;
      case BackGroundColor.white:
        return Colors.white;
    }
  }

  final String title;
  final Widget child;
  final BackGroundColor? backGroundColor;

  const BasePage({
    super.key,
    required this.title,
    required this.child,
    this.backGroundColor,
  });

  /// Megadja milyen színű legyen az appbar a BackGroundColor enum alapján
  Color? AppBarColorMap(BackGroundColor? color) {
    switch (color) {
      case BackGroundColor.blue:
        return Colors.blue[200];
      case BackGroundColor.white:
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  /// Megadja milyen színű legyen a body a BackGroundColor enum alapján
  Color? BodyColorMap(BackGroundColor? color) {
    switch (color) {
      case BackGroundColor.blue:
        return Colors.blue[50];
      case BackGroundColor.white:
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = backGroundColor ?? defaultColorEnum;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppBarColorMap(effectiveColor),
      ),
      backgroundColor: BodyColorMap(effectiveColor),
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
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          style: ButtonStyle(
            backgroundColor:
                WidgetStateProperty.all(Colors.lightBlueAccent[50]),
            foregroundColor: WidgetStateProperty.all(BasePage.defaultColor),
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
                        title: title,
                        backGroundColor: BasePage.defaultColorEnum,
                        child: nextPage!)),
              );
            }
          },
          child: Text(text),
        ),
      ),
    );
  }
}

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
      activeColor: BasePage.defaultColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      dense: dense,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

class MyTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final String labelText;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool forceUppercase;

  const MyTextFormField(
      {super.key,
      required this.controller,
      required this.focusNode,
      this.nextFocus,
      required this.labelText,
      this.textInputAction = TextInputAction.next,
      this.validator,
      this.obscureText = false,
      this.forceUppercase = false});

  /// Megadja milyen színű legyen a textFormField körvonala a BackGroundColor enum alapján
  Color? TextFieldColorMap(BackGroundColor? color) {
    switch (color) {
      case BackGroundColor.blue:
        return Colors.deepPurple;
      case BackGroundColor.white:
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction,
      validator: validator,
      onEditingComplete: () {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      onChanged: forceUppercase
          ? (text) {
              final upper = text.toUpperCase();
              if (text != upper) {
                controller.value = controller.value.copyWith(
                  text: upper,
                  selection: TextSelection.collapsed(offset: upper.length),
                );
              }
            }
          : null,
      decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: TextFieldColorMap(
                    BasePage.defaultColorEnum)!), // alap keret
          )),
      obscureText: obscureText,
    );
  }
}
