import 'package:airport_test/constants/constant_widgets/base_page.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';

class MyTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final String hintText;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Function? onObscureToggle;
  final MyTextFormFieldType? selectedTextFormFieldType;
  final VoidCallback? onEditingComplete;

  const MyTextFormField(
      {super.key,
      required this.controller,
      required this.focusNode,
      this.nextFocus,
      required this.hintText,
      this.textInputAction = TextInputAction.next,
      this.validator,
      this.obscureText = false,
      this.onObscureToggle,
      this.selectedTextFormFieldType,
      this.onEditingComplete});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppPadding.extraSmall),
          child: Text(hintText,
              style: TextStyle(color: BasePage.defaultColors.primary)),
        ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: textInputAction,
          validator: validator,
          cursorColor: BasePage.defaultColors.primary,
          cursorErrorColor: BasePage.defaultColors.primary,
          onEditingComplete: () {
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            } else {
              FocusScope.of(context).unfocus();
            }
            if (onEditingComplete != null) {
              onEditingComplete!();
            }
          },
          onChanged: selectedTextFormFieldType ==
                  MyTextFormFieldType.licensePlate
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
            // hintText: hintText,
            // hintStyle: TextStyle(color: BasePage.defaultColors.primary),
            prefixText: selectedTextFormFieldType == MyTextFormFieldType.phone
                ? '+'
                : null,
            prefixStyle: selectedTextFormFieldType == MyTextFormFieldType.phone
                ? TextStyle(color: Colors.black)
                : null,
            filled: true,
            fillColor: BasePage.defaultColors.secondary,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            suffixIcon: onObscureToggle != null
                ? Padding(
                    padding: const EdgeInsets.only(right: AppPadding.small),
                    child: IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: obscureText
                            ? Colors.grey.shade800
                            : Colors.grey.shade900,
                      ),
                      onPressed: () {
                        onObscureToggle!();
                      },
                    ),
                  )
                : null,
          ),
          obscureText: obscureText,
          inputFormatters:
              selectedTextFormFieldType == MyTextFormFieldType.phone
                  ? [MaskedInputFormatter('00 00 000 0000')]
                  : null,
        ),
      ],
    );
  }
}
