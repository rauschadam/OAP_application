String formatPhone(String? phoneText) {
  if (phoneText == null) return '';
  if (phoneText.startsWith('+')) {
    return phoneText.substring(1);
  } else {
    return phoneText;
  }
}
