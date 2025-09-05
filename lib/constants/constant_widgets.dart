import 'package:airport_test/enums/parkingFormEnums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'package:intl/intl.dart';

class AppColors {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color text;

  const AppColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.text,
  });

  // előre definiált template-ek
  static const AppColors blue = AppColors(
    primary: Color.fromARGB(255, 47, 39, 206),
    secondary: Color.fromARGB(255, 222, 220, 255),
    accent: Color.fromARGB(255, 67, 59, 255),
    background: Color.fromARGB(255, 251, 251, 254),
    text: Color.fromARGB(255, 5, 3, 21),
  );
}

mixin PageWithTitle {
  String get pageTitle;
  bool get showBackButton => true;
}

class BasePage extends StatelessWidget {
  static AppColors defaultColors = AppColors.blue;

  final Widget child;
  final AppColors? colors;

  const BasePage({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    final effectiveColors = colors ?? defaultColors;

    return Scaffold(
      appBar: AppBar(
        title: Text((child as PageWithTitle).pageTitle),
        automaticallyImplyLeading: (child as PageWithTitle).showBackButton,
        backgroundColor: effectiveColors.background,
        foregroundColor: effectiveColors.text,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[300],
            height: 1,
          ),
        ),
      ),
      backgroundColor: effectiveColors.background,
      body: Center(
        child: Row(
          children: [
            Expanded(child: Container()),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(child: child),
                ],
              ),
            ),
            Expanded(child: Container()),
          ],
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.only(top: 8.0),
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
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return BasePage.defaultColors.secondary
                .withValues(alpha: 0.3); // splash szín
          }
          return null;
        },
      ),
      activeColor: BasePage.defaultColors.primary,
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
          padding: const EdgeInsets.only(left: 2.0, bottom: 2.0),
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
                    padding: const EdgeInsets.only(right: 8.0),
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

class MyIconButton extends StatelessWidget {
  final IconData icon;
  final String labelText;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

  const MyIconButton({
    super.key,
    required this.icon,
    required this.labelText,
    required this.onPressed,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: BasePage.defaultColors.secondary,
      ),
      icon: Icon(
        icon,
        color: BasePage.defaultColors.primary,
      ),
      label: Text(
        labelText,
        style: TextStyle(
          color: BasePage.defaultColors.primary,
        ),
      ),
      focusNode: focusNode,
      onPressed: () {
        onPressed();
      },
    );
  }
}

class ParkingZoneSelectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int costPerDay;
  final int parkingDays;
  final bool selected;
  final VoidCallback onTap;
  final bool available;

  const ParkingZoneSelectionCard(
      {super.key,
      required this.title,
      this.subtitle,
      required this.costPerDay,
      required this.parkingDays,
      required this.selected,
      required this.onTap,
      this.available = true});

  void ShowUnavailableZoneDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nem foglalható"),
          content: SizedBox(
            width: 300,
            height: 100,
            child: const Text(
                "A foglalni kívánt intervallum telített foglaltságúidőpontokat tartalmaz ebben a zónában. Válasszon másik parkoló zónát vagy változtasson az érkezési és távozási időpontokon."),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int parkingCost = costPerDay * parkingDays;
    final formattedParkingCost =
        NumberFormat('#,###', 'hu_HU').format(parkingCost);
    final formattedCostPerDay =
        NumberFormat('#,###', 'hu_HU').format(costPerDay);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (available) {
          onTap();
        } else {
          ShowUnavailableZoneDialog(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? Colors.white : Colors.white,
          border: Border.all(
            color:
                selected ? BasePage.defaultColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Opacity(
          opacity: available ? 1.0 : 0.3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? BasePage.defaultColors.secondary
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? BasePage.defaultColors.primary
                        : Colors.black54,
                  ),
                ),
              ),
              subtitle != null ? const SizedBox(height: 4) : Container(),
              subtitle != null
                  ? Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    )
                  : Container(),
              const SizedBox(height: 16),
              Text(
                "$formattedParkingCost Ft",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$formattedCostPerDay Ft / nap",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WashOptionSelectionCard extends StatelessWidget {
  final String title;
  final int washCost;
  final bool selected;
  final VoidCallback onTap;
  final bool available;

  const WashOptionSelectionCard(
      {super.key,
      required this.title,
      required this.washCost,
      required this.selected,
      required this.onTap,
      this.available = true});

  void ShowUnavailableZoneDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nem foglalható"),
          content: SizedBox(
            width: 300,
            height: 100,
            child: const Text(
                "A foglalni kívánt időpont foglalt ebben a zónában. Válasszon másik típusú mosást vagy változtasson az időponton."),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedWashCost = NumberFormat('#,###', 'hu_HU').format(washCost);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (available) {
          onTap();
        } else {
          ShowUnavailableZoneDialog(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? Colors.white : Colors.white,
          border: Border.all(
            color:
                selected ? BasePage.defaultColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Opacity(
          opacity: available ? 1.0 : 0.3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: selected
                      ? BasePage.defaultColors.secondary
                      : Colors.grey[200],
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? BasePage.defaultColors.primary
                        : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "$formattedWashCost Ft",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
