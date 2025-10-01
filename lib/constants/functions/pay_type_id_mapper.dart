import 'package:airport_test/constants/enums/parkingFormEnums.dart';

const Map<PaymentOption, String> payTypeIdMap = {
  PaymentOption.card: '1-47',
  PaymentOption.cash: '1-6',
  PaymentOption.transfer: '1-81',
  PaymentOption.pass: '1-82',
};

String getPayTypeId(PaymentOption paymentOption) {
  return payTypeIdMap[paymentOption]!;
}
