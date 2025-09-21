import 'dart:ui';

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
    background: Color.fromARGB(255, 255, 255, 255),
    text: Color.fromARGB(255, 5, 3, 21),
  );
}

// Padding/margin értékek
class AppPadding {
  static const double extraSmall = 4.0;
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double xlarge = 32.0;
}

// Kerekítés értékek
class AppBorderRadius {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
}
