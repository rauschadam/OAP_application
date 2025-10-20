import 'package:airport_test/api_services/api_classes/login_data.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/api_services/api_classes/registration.dart';
import 'package:airport_test/Pages/reservationForm/parkOrderPage.dart';
import 'package:airport_test/Pages/reservationForm/washOrderPage.dart';
import 'package:airport_test/constants/navigation.dart';
import 'package:airport_test/constants/theme.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_text_form_field.dart';
import 'package:airport_test/constants/widgets/next_page_button.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget {
  final BookingOption bookingOption;
  final bool alreadyRegistered;
  final bool withoutRegistration;
  const RegistrationPage({
    super.key,
    required this.bookingOption,
    required this.alreadyRegistered,
    required this.withoutRegistration,
  });

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final formKey = GlobalKey<FormState>();

  /// CONTROLLEREK
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final favoriteLicensePlateNumberController = TextEditingController();
  final taxNumberController = TextEditingController();
  final postalCodeController = TextEditingController();
  final cityController = TextEditingController();
  final streetController = TextEditingController();
  final houseNumberController = TextEditingController();

  /// FOCUSNODEOK
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();
  final nameFocus = FocusNode();
  final licensePlateFocus = FocusNode();
  final phoneFocus = FocusNode();
  final taxNumberFocus = FocusNode();
  final postalCodeFocus = FocusNode();
  final cityFocus = FocusNode();
  final streetFocus = FocusNode();
  final houseNumberFocus = FocusNode();
  final nextPageButtonFocus = FocusNode();

  bool obscurePassword = true;

  /// Regisztráció
  Future<LoginData?> RegisterUser() async {
    final registration = Registration(
      name: nameController.text,
      password: passwordController.text,
      email: emailController.text,
      phone: phoneController.text,
      favoriteLicensePlateNumber: favoriteLicensePlateNumberController.text,
      taxNumber:
          taxNumberController.text == "" ? null : taxNumberController.text,
      postalCode: int.parse(postalCodeController.text),
      cityName: cityController.text,
      streetName: streetController.text,
      houseNumber: houseNumberController.text,
    );

    final registerData = await ApiService().registerUser(context, registration);
    if (registerData != null) {
      final api = ApiService();
      final loginData = await api.loginUser(
        context,
        emailController.text,
        passwordController.text,
      );
      return loginData;
    }
    return null;
  }

  Widget validationErrorText(dynamic formFieldState, Color errorColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: AppPadding.medium),
      child: Text(
        formFieldState.errorText!,
        style: TextStyle(color: errorColor, fontSize: 12),
      ),
    );
  }

  void OnNextPageButtonPressed() async {
    if (formKey.currentState!.validate()) {
      final loginData = await RegisterUser();
      if (loginData != null) {
        Widget nextPage;
        switch (widget.bookingOption) {
          case BookingOption.parking:
          case BookingOption.both:
            nextPage = ParkOrderPage(
              authToken: loginData.authorizationToken,
              personId: loginData.personId,
              partnerId: loginData.partnerId,
              bookingOption: widget.bookingOption,
              emailController: emailController,
              licensePlateController: favoriteLicensePlateNumberController,
              nameController: nameController,
              phoneController: phoneController,
              alreadyRegistered: widget.alreadyRegistered,
              withoutRegistration: widget.withoutRegistration,
            );
            break;
          case BookingOption.washing:
            nextPage = WashOrderPage(
              authToken: loginData.authorizationToken,
              personId: loginData.personId,
              partnerId: loginData.partnerId,
              bookingOption: widget.bookingOption,
              emailController: emailController,
              licensePlateController: favoriteLicensePlateNumberController,
              nameController: nameController,
              phoneController: phoneController,
              alreadyRegistered: widget.alreadyRegistered,
              withoutRegistration: widget.withoutRegistration,
            );
            break;
        }
        Navigation(context: context, page: nextPage).push();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(emailFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      pageTitle: "Regisztráció",
      haveMargins: true,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTextFormFields(),
              NextPageButton(
                focusNode: nextPageButtonFocus,
                onPressed: OnNextPageButtonPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextFormFields() {
    final errorColor = Theme.of(context).colorScheme.error;
    const double sizedBoxHeight = 10;
    return Column(
      children: [
        SizedBox(height: sizedBoxHeight),
        MyTextFormField(
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Adja meg email-címét';
            } else if (!EmailValidator.validate(value.trim())) {
              return 'Érvénytelen email-cím';
            }
            return null;
          },
          controller: emailController,
          focusNode: emailFocus,
          textInputAction: TextInputAction.next,
          nextFocus: passwordFocus,
          hintText: 'Email cím',
        ),
        SizedBox(height: sizedBoxHeight),
        FormField(
          validator: (value) {
            if (passwordController.text.isEmpty ||
                confirmPasswordController.text.isEmpty) {
              return 'Adja meg a jelszót';
            } else if (confirmPasswordController.text.isEmpty) {
              return 'Erősítse meg jelszavát';
            } else if (passwordController.text !=
                confirmPasswordController.text) {
              return 'A két jelszó nem egyezik meg';
            }
            return null;
          },
          builder: (formFieldState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: MyTextFormField(
                      controller: passwordController,
                      focusNode: passwordFocus,
                      textInputAction: TextInputAction.next,
                      nextFocus: confirmPasswordFocus,
                      hintText: 'Jelszó',
                      obscureText: obscurePassword,
                      onObscureToggle: () {
                        setState(() => obscurePassword = !obscurePassword);
                      },
                      onEditingComplete: () => formFieldState.didChange(null),
                    ),
                  ),
                  SizedBox(width: sizedBoxHeight),
                  Expanded(
                    child: MyTextFormField(
                      controller: confirmPasswordController,
                      focusNode: confirmPasswordFocus,
                      textInputAction: TextInputAction.next,
                      nextFocus: nameFocus,
                      hintText: 'Jelszó megerősítése',
                      obscureText: obscurePassword,
                      onObscureToggle: () {
                        setState(() => obscurePassword = !obscurePassword);
                      },
                      onEditingComplete: () => formFieldState.didChange(null),
                    ),
                  ),
                ],
              ),
              if (formFieldState.hasError)
                validationErrorText(formFieldState, errorColor)
            ],
          ),
        ),
        SizedBox(height: sizedBoxHeight),
        FormField(
          validator: (value) {
            if (nameController.text.isEmpty &&
                favoriteLicensePlateNumberController.text.isEmpty) {
              return 'Adja meg a felhasználónevet és a kedvenc rendszámot';
            } else if (nameController.text.isEmpty) {
              return 'Adja meg a felhasználónevet';
            } else if (favoriteLicensePlateNumberController.text.isEmpty) {
              return 'Adja meg a kedvenc rendszámot';
            }
            return null;
          },
          builder: (formFieldState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: MyTextFormField(
                      controller: nameController,
                      focusNode: nameFocus,
                      textInputAction: TextInputAction.next,
                      nextFocus: licensePlateFocus,
                      hintText: 'Felhasználónév',
                      onEditingComplete: () => formFieldState.didChange(null),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: MyTextFormField(
                      controller: favoriteLicensePlateNumberController,
                      focusNode: licensePlateFocus,
                      textInputAction: TextInputAction.next,
                      nextFocus: phoneFocus,
                      hintText: 'Kedvenc rendszám',
                      selectedTextFormFieldType:
                          MyTextFormFieldType.licensePlate,
                      onEditingComplete: () => formFieldState.didChange(null),
                    ),
                  ),
                ],
              ),
              if (formFieldState.hasError)
                validationErrorText(formFieldState, errorColor)
            ],
          ),
        ),
        SizedBox(height: sizedBoxHeight),
        MyTextFormField(
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Adja meg telefonszámát';
            } else if (value.length < 10) {
              return 'Hibás telefonszám';
            }
            return null;
          },
          controller: phoneController,
          focusNode: phoneFocus,
          textInputAction: TextInputAction.next,
          nextFocus: taxNumberFocus,
          hintText: 'Telefonszám',
          selectedTextFormFieldType: MyTextFormFieldType.phone,
        ),
        SizedBox(height: sizedBoxHeight),
        MyTextFormField(
          controller: taxNumberController,
          focusNode: taxNumberFocus,
          textInputAction: TextInputAction.next,
          nextFocus: postalCodeFocus,
          hintText: 'Adóazonosító szám',
        ),
        SizedBox(height: sizedBoxHeight),
        FormField(
          validator: (value) {
            if (postalCodeController.text.isEmpty ||
                cityController.text.isEmpty ||
                streetController.text.isEmpty ||
                houseNumberController.text.isEmpty) {
              return 'Adja meg a teljes címet (irányítószám, város, utca, házszám)';
            }
            return null;
          },
          builder: (formFieldState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: MyTextFormField(
                      controller: postalCodeController,
                      focusNode: postalCodeFocus,
                      textInputAction: TextInputAction.next,
                      nextFocus: cityFocus,
                      hintText: 'Irányítószám',
                      onEditingComplete: () => formFieldState.didChange(null),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: MyTextFormField(
                      controller: cityController,
                      focusNode: cityFocus,
                      textInputAction: TextInputAction.next,
                      nextFocus: streetFocus,
                      hintText: 'Város',
                      onEditingComplete: () => formFieldState.didChange(null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: MyTextFormField(
                      controller: streetController,
                      focusNode: streetFocus,
                      textInputAction: TextInputAction.next,
                      nextFocus: houseNumberFocus,
                      hintText: 'Utca',
                      onEditingComplete: () => formFieldState.didChange(null),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: MyTextFormField(
                      controller: houseNumberController,
                      focusNode: houseNumberFocus,
                      textInputAction: TextInputAction.done,
                      nextFocus: nextPageButtonFocus,
                      hintText: 'Házszám',
                      onEditingComplete: () {
                        formFieldState.didChange(null);
                        OnNextPageButtonPressed();
                      },
                    ),
                  ),
                ],
              ),
              if (formFieldState.hasError)
                validationErrorText(formFieldState, errorColor)
            ],
          ),
        ),
        SizedBox(height: sizedBoxHeight),
      ],
    );
  }
}
