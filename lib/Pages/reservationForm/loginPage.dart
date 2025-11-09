import 'package:airport_test/Pages/reservationForm/parkOrderPage.dart';
import 'package:airport_test/Pages/reservationForm/washOrderPage.dart';
import 'package:airport_test/api_services/api_classes/login_data.dart';
import 'package:airport_test/api_services/api_classes/reservation.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/constants/navigation.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_text_form_field.dart';
import 'package:airport_test/constants/widgets/next_page_button.dart';
import 'package:airport_test/constants/enums/parkingFormEnums.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();
  FocusNode nextPageButtonFocus = FocusNode();

  /// Jelszó elrejtése
  bool obscurePassword = true;

  /// Ha épp folyamatban a bejelentkezés
  bool _isSubmitting = false;

  Future<LoginData?> loginUser() async {
    final api = ApiService();
    final LoginData? loginData = await api.loginUser(
        context, emailController.text, passwordController.text);
    return loginData;
  }

  void OnNextPageButtonPressed() async {
    if (_isSubmitting) return; // <-- VISSZALÉPÉS

    if (formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true; // <-- MŰVELET ELINDÍTÁSA
      });

      try {
        final loginData = await loginUser();
        if (!mounted) return;

        if (loginData != null) {
          // Állapot frissítése hitelesítési adatokkal és email címmel
          final currentState = ref.read(reservationProvider);

          ref.read(reservationProvider.notifier).updateAuth(
                authToken: loginData.authorizationToken,
                partnerId: loginData.partnerId,
                personId: loginData.personId,
              );

          ref.read(reservationProvider.notifier).updateContactAndLicense(
                name: currentState.name,
                email: emailController.text,
                phone: currentState.phone,
                licensePlate: currentState.licensePlate,
              );

          Widget nextPage;
          switch (currentState.bookingOption) {
            case BookingOption.parking:
            case BookingOption.both:
              nextPage = const ParkOrderPage();
              break;
            case BookingOption.washing:
              nextPage = const WashOrderPage();
              break;
          }
          Navigation(context: context, page: nextPage).push();
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false; // <-- MŰVELET BEFEJEZÉSE
          });
        }
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
    return BasePage(
      pageTitle: "Bejelentkezés",
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
                pushAndRemoveAll: false,
                isLoading: _isSubmitting,
              ),
            ],
          ),
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
          hintText: 'Jelszó',
          onEditingComplete: OnNextPageButtonPressed,
        ),
      ],
    );
  }
}
