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

enum ParkingZoneOption {
  premium, // Fedett
  normal, // Nyitott térköves
  eco // Nyitott murvás
}

enum WashOption {
  basic, // Alapmosás
  wash2, // Mosás 2
  wash3, // Mosás 3
  wash4, // Mosás 4
  superWash // Szupermosás porszívóval
}

enum PaymentOption {
  card, // Bankkártyával fizetek
  transfer, // Átutalássaé fizetek még a parkolás megkezdése előtt 1 nappal
  qvik // Qvik
}

enum InvoiceOption {
  no, // Nem kérek számlát
  yes, // Kérek számlát
}
