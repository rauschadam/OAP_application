import 'package:airport_test/Pages/homePage/homePage.dart';
import 'package:airport_test/api_services/api_classes/login_data.dart';
import 'package:airport_test/api_services/api_service.dart';
import 'package:airport_test/api_services/auth_manager.dart';
import 'package:airport_test/constants/navigation.dart';
import 'package:airport_test/constants/widgets/base_page.dart';
import 'package:airport_test/constants/widgets/my_text_form_field.dart';
import 'package:airport_test/constants/widgets/next_page_button.dart';
import 'package:airport_test/constants/globals.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

class ReceptionLoginPage extends StatefulWidget {
  const ReceptionLoginPage({super.key});

  @override
  State<ReceptionLoginPage> createState() => _ReceptionLoginPageState();
}

class _ReceptionLoginPageState extends State<ReceptionLoginPage> {
  final formKey = GlobalKey<FormState>();

  // --- KONTROLLEREK ---
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // --- FOCUSNODE ---
  FocusNode emailFocus = FocusNode();
  FocusNode passwordFocus = FocusNode();
  FocusNode nextPageButtonFocus = FocusNode();

  /// Jelszó elrejtése
  bool obscurePassword = true;

  /// Recepciós bejelentkeztetése
  Future<LoginData?> loginReceptionist() async {
    final api = ApiService();
    final LoginData? loginData =
        await api.loginUser(context, 'recepcio@oap.hu', 'asd'); // teszt login

    if (loginData != null) {
      AuthManager.setLoginData(loginData);
      ReceptionistEmail = 'recepcio@oap.hu';
      ReceptionistPassword = 'asd';

      try {
        ServiceTemplates = await api.getServiceTemplates(context) ?? [];

        PayTypes = await api.getPayTypes(context) ?? [];

        CarWashServices = await api.getCarWashServices(context) ?? [];

        ReservationFieldSettings = await api.fetchPlatformSettings(
              context: context,
              listPanelId: 107, // Érvényes foglalású autók
              platformId: 3, // Desktop settings
              errorDialogTitle:
                  "Foglalás részletező mezők lekérdezése sikertelen!",
            ) ??
            [];

        Navigation(context: context, page: HomePage()).pushAndRemoveAll();
      } catch (e) {
        debugPrint("Hiba az adatok lekérése közben: $e");
        if (!mounted) return loginData;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nem sikerült lekérni a szükséges adatokat.')),
        );
      }
    }

    return loginData;
  }

  @override
  void initState() {
    super.initState();

    loginReceptionist(); // Automatikus login a teszteléshez.

    // Kis késleltetéssel adunk fókuszt, hogy a build lefusson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(emailFocus);
    });
  }

  void OnNextPageButtonPressed() async {
    if (formKey.currentState!.validate()) {
      final LoginData? loginData = await loginReceptionist();
      if (loginData != null) {
        Navigation(context: context, page: HomePage()).pushAndRemoveAll();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      pageTitle: "Recepciós bejelentkezés",
      haveMargins: true,
      child: Form(
        key: formKey,
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
              return 'Adja meg jelszavát';
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
