import 'package:intl/intl.dart';

String formatPhone(String? phoneText) {
  if (phoneText == null) return '';
  if (phoneText.startsWith('+')) {
    return phoneText.substring(1);
  } else {
    return phoneText;
  }
}

String listPanelBoolFormatter(bool? value) {
  if (value == null) return '-';
  return value ? 'Igen' : 'Nem';
}

String listPanelDateFormatter(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('yyyy.MM.dd HH:mm').format(date);
}
