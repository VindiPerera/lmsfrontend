import 'package:flutter/material.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'package:lms/core/constants/app_config.dart';

class PaymentService {
  /// Initiates a one-time PayHere payment using Sandbox credentials
  static void startCoursePayment({
    required BuildContext context,
    required String orderId,
    required String courseName,
    required double amount,
    required String currency,
    required String customerFirstName,
    required String customerLastName,
    required String customerEmail,
    required String customerPhone,
    required String customerAddress,
    required String customerCity,
    required Function(String) onCompleted,
    required VoidCallback onError,
    required VoidCallback onCanceled,
  }) {
    Map paymentObject = {
      "sandbox": AppConfig.payHereIsSandbox,
      "merchant_id": AppConfig.payHereMerchantId,
      "notify_url": AppConfig.payHereNotifyUrl,
      "order_id": orderId,
      "items": courseName,
      "amount": amount.toStringAsFixed(2),
      "currency": currency,
      "first_name": customerFirstName,
      "last_name": customerLastName,
      "email": customerEmail,
      "phone": customerPhone,
      "address": customerAddress,
      "city": customerCity,
      "country": "Sri Lanka",
      "delivery_address": customerAddress,
      "delivery_city": customerCity,
      "delivery_country": "Sri Lanka",
      "custom_1": "",
      "custom_2": "",
    };

    PayHere.startPayment(
      paymentObject,
      (paymentId) {
        if (!context.mounted) return;
        onCompleted(paymentId ?? "");
      },
      (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment Error: $error"),
            backgroundColor: Colors.red,
          ),
        );
        onError();
      },
      () {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment Canceled by User"),
            backgroundColor: Colors.orange,
          ),
        );
        onCanceled();
      },
    );
  }
}
