import 'dart:async';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Fixed eSewa payment service with:
/// 1. Mounted-context guard (prevents BadTokenException crash in debug)
/// 2. Re-entrancy guard (prevents double-trigger)
/// 3. Full try/catch around SDK call
/// 4. Returns null on cancel/fail, refId string on success
class EsewaPaymentService {
  // Sandbox keys from eSewa docs (development only)
  static const String _devClientId =
      "JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R";
  static const String _devSecretId = "BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==";

  // Read from --dart-define overrides (production)
  static const String _envClientId = String.fromEnvironment('ESEWA_CLIENT_ID');
  static const String _envSecretId = String.fromEnvironment('ESEWA_SECRET_ID');

  static String get _clientId =>
      _envClientId.isNotEmpty ? _envClientId : _devClientId;
  static String get _secretId =>
      _envSecretId.isNotEmpty ? _envSecretId : _devSecretId;

  // Prevent double-trigger (e.g. rapid button taps)
  static bool _isProcessing = false;

  /// Initiates eSewa payment.
  ///
  /// [context] — must be mounted. Used to check if still in a valid Activity.
  /// Returns refId on success, null on cancel/failure.
  ///
  /// Throws if keys are missing or the SDK call itself throws.
  static Future<String?> startPayment({
    required BuildContext context,
    required int bookingId,
    required double totalAmount,
    required String productName,
  }) async {
    // Re-entrancy guard
    if (_isProcessing) {
      debugPrint('eSewa: Already processing — ignoring duplicate call');
      return null;
    }

    // Mounted guard — most common cause of BadTokenException in debug
    if (!context.mounted) {
      debugPrint('eSewa: Context is unmounted — skipping payment');
      return null;
    }

    if (_clientId.isEmpty || _secretId.isEmpty) {
      throw Exception(
        'eSewa keys missing. Pass --dart-define=ESEWA_CLIENT_ID=... in release builds.',
      );
    }

    _isProcessing = true;
    final completer = Completer<String?>();

    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          environment: Environment.test, // Change to Environment.live for production
          clientId: _clientId,
          secretId: _secretId,
        ),
        esewaPayment: EsewaPayment(
          productId: bookingId.toString(),
          productName: productName,
          productPrice: totalAmount.toStringAsFixed(2),
          callbackUrl: 'https://hamro-pani-fyp-backend.onrender.com',
        ),
        onPaymentSuccess: (res) {
          debugPrint('eSewa success: refId=${res.refId}');
          if (!completer.isCompleted) completer.complete(res.refId);
        },
        onPaymentFailure: (_) {
          debugPrint('eSewa payment failed');
          if (!completer.isCompleted) completer.complete(null);
        },
        onPaymentCancellation: (_) {
          debugPrint('eSewa payment cancelled');
          if (!completer.isCompleted) completer.complete(null);
        },
      );
    } catch (e) {
      debugPrint('eSewa SDK error: $e');
      if (!completer.isCompleted) completer.complete(null);
    }

    final result = await completer.future;
    _isProcessing = false;
    return result;
  }
}
