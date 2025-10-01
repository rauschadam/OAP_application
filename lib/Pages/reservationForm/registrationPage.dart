import 'package:airport_test/api_services/api_classes/login_data.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/api_services/api_classes/registration.dart';
import 'package:airport_test/Pages/reservationForm/parkOrderPage.dart';
import 'package:airport_test/Pages/reservationForm/washOrderPage.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_text_form_field.dart';
import 'package:airport_test/constants/widgets/next_page_button.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget with PageWithTitle {
  @override
  String get pageTitle => 'Regisztráció';

  final BookingOption bookingOption;
  final bool alreadyRegistered;
  final bool withoutRegistration;
  const RegistrationPage(
      {super.key,
      required this.bookingOption,
      required this.alreadyRegistered,
      required this.withoutRegistration});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController favoriteLicensePlateNumberController =
      TextEditingController();

  FocusNode nameFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();
  FocusNode confirmPasswordFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();
  FocusNode favoriteLicensePlateNumberFocus = FocusNode();
  FocusNode nextPageButtonFocus = FocusNode();

  /// Login-nél kapott token, mellyel a lekérdezéseket intézhetjük
  String? authToken;

  String? partnerId;

  /// Jelszó elrejtése
  bool obscurePassword = true;

  /// Felhasznló regisztrálása
  Future<LoginData?> RegisterUser() async {
    final registration = Registration(
      name: nameController.text,
      password: passwordController.text,
      email: emailController.text,
      phone: phoneController.text,
      favoriteLicensePlateNumber: favoriteLicensePlateNumberController.text,
    );

    await ApiService().registerUser(context, registration);

    /// Egyben be is jelentkezteti a felhasználót
    final api = ApiService();
    final LoginData? loginData = await api.loginUser(
        context, emailController.text, passwordController.text);

    if (loginData != null) {
      setState(() {
        authToken = loginData.authorizationToken;
        partnerId = loginData.partnerId;
        print(authToken);
      });
    }
    return loginData;
  }

  void OnNextPageButtonPressed() async {
    if (formKey.currentState!.validate()) {
      final token = await RegisterUser();
      if (token != null) {
        Widget nextPage;
        switch (widget.bookingOption) {
          case BookingOption.parking:
          case BookingOption.both:
            nextPage = ParkOrderPage(
              authToken: authToken!,
              partnerId: partnerId!,
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
              authToken: authToken!,
              partnerId: partnerId!,
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sikeres regisztráció!')),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BasePage(
              child: nextPage,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sikertelen regisztráció!')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Kis késleltetéssel adunk fókuszt, hogy a build lefusson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(emailFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
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
    );
  }

  Widget buildTextFormFields() {
    final double sizedBoxHeight = 10;
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
        MyTextFormField(
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Adjon meg egy jelszót';
            }
            return null;
          },
          controller: passwordController,
          obscureText: obscurePassword,
          onObscureToggle: () {
            setState(() {
              obscurePassword = !obscurePassword;
            });
          },
          focusNode: passwordFocus,
          textInputAction: TextInputAction.next,
          nextFocus: confirmPasswordFocus,
          hintText: 'Jelszó',
        ),
        SizedBox(height: sizedBoxHeight),
        MyTextFormField(
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Adjon meg egy jelszót';
            } else if (value != passwordController.text) {
              return 'A jelszó nem egyezik';
            }
            return null;
          },
          controller: confirmPasswordController,
          obscureText: obscurePassword,
          onObscureToggle: () {
            setState(() {
              obscurePassword = !obscurePassword;
            });
          },
          focusNode: confirmPasswordFocus,
          textInputAction: TextInputAction.next,
          nextFocus: nameFocus,
          hintText: 'Jelszó megerősítése',
        ),
        SizedBox(height: sizedBoxHeight),
        MyTextFormField(
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Adjon meg egy felhasználó nevet';
            }
            return null;
          },
          controller: nameController,
          focusNode: nameFocus,
          textInputAction: TextInputAction.next,
          nextFocus: phoneFocus,
          hintText: 'Felhasználó név',
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
            nextFocus: favoriteLicensePlateNumberFocus,
            hintText: 'Telefonszám',
            selectedTextFormFieldType: MyTextFormFieldType.phone),
        SizedBox(height: sizedBoxHeight),
        MyTextFormField(
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Adja meg kedvenc rendszámát';
            }
            return null;
          },
          controller: favoriteLicensePlateNumberController,
          focusNode: favoriteLicensePlateNumberFocus,
          textInputAction: TextInputAction.done,
          nextFocus: nextPageButtonFocus,
          hintText: 'Kedvenc rendszám',
          selectedTextFormFieldType: MyTextFormFieldType.licensePlate,
          onEditingComplete: OnNextPageButtonPressed,
        ),
        SizedBox(height: sizedBoxHeight),
      ],
    );
  }
}
