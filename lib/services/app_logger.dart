import 'package:flutter/foundation.dart';

/// Journalisation centralisée : détails techniques uniquement en debug.
class AppLogger {
  AppLogger._();

  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void api({
    required String label,
    String? endpoint,
    int? statusCode,
    String? responseBody,
    Object? body,
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer(label);
    if (endpoint != null) buffer.write(': $endpoint');
    if (statusCode != null) buffer.write(' [$statusCode]');
    debugPrint(buffer.toString());
    if (body != null) debugPrint('Données: $body');
    if (responseBody != null) debugPrint('Response body: $responseBody');
  }

  static void error(String label, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('$label: $error');
      if (stack != null) debugPrint(stack.toString());
    }
  }
}
