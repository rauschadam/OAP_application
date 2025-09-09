enum BookingOption {
  parking, // Parkolni szeretnék
  washing, // Csak mosatni szeretnék
  both, // Parkolni és mosatni is szeretnék
}

enum RegistrationOption {
  registered, // Regisztrált partner vagyok
  registerNow, // Most szeretnék regisztrálni
  withoutRegistration, // Regisztráció nélkül vásárolok
}

enum PaymentOption {
  card, // Bankkártyával fizetek
  transfer, // Átutalással fizetek még a parkolás megkezdése előtt 1 nappal
  qvik // Qvik
}

enum InvoiceOption {
  no, // Nem kérek számlát
  yes, // Kérek számlát
}

enum TimeOfDayPeriod { morning, daytime, night, nighttime }

enum MyTextFormFieldType {
  licensePlate,
  phone,
}
