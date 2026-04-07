import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';

class EsewaPaymentService {
  // Read from --dart-define (preferred)
  static const String _envClientId = String.fromEnvironment('ESEWA_CLIENT_ID');
  static const String _envSecretId = String.fromEnvironment('ESEWA_SECRET_ID');

  // Sandbox/dev keys from eSewa docs (development only)
  static const String _devClientId =
      "JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R";
  static const String _devSecretId = "BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==";

  static const Environment environment = Environment.test;

  static String get clientId => kDebugMode
      ? (_envClientId.isNotEmpty ? _envClientId : _devClientId)
      : _envClientId;

  static String get secretId => kDebugMode
      ? (_envSecretId.isNotEmpty ? _envSecretId : _devSecretId)
      : _envSecretId;

  static Future<String?> pay({
    required int bookingId,
    required double totalAmount,
    required String productName,
  }) async {
    debugPrint(
      "eSewa keys: clientIdLen=${clientId.length}, secretLen=${secretId.length}",
    );

    if (clientId.isEmpty || secretId.isEmpty) {
      throw Exception(
        "eSewa keys missing.\n"
        "In DEBUG this should fallback automatically.\n"
        "In RELEASE you must pass --dart-define keys.",
      );
    }

    final completer = Completer<String?>();

    // Wrap SDK call in try-catch to handle BadTokenException and similar
    // activity-context errors that can occur in debug mode when the activity
    // stack is in a non-standard state (e.g. launched via Android Studio Run).
    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          environment: environment,
          clientId: clientId,
          secretId: secretId,
        ),
        esewaPayment: EsewaPayment(
          productId: bookingId.toString(),
          productName: productName,
          productPrice: totalAmount.toStringAsFixed(2),
          callbackUrl: "https://example.com",
        ),
        onPaymentSuccess: (res) {
          if (!completer.isCompleted) completer.complete(res.refId);
        },
        onPaymentFailure: (_) {
          if (!completer.isCompleted) completer.complete(null);
        },
        onPaymentCancellation: (_) {
          if (!completer.isCompleted) completer.complete(null);
        },
      );
    } catch (e) {
      debugPrint("eSewa SDK error: $e");
      // Complete with null so the caller can cancel the booking gracefully
      if (!completer.isCompleted) completer.complete(null);
      return completer.future;
    }

    return completer.future;
  }
}
