/// Centralised application configuration.
/// Update the [laravelBaseUrl] when deploying to your VPS.
class AppConfig {
  AppConfig._();

  /// Base URL of the Laravel API.
  /// ─────────────────────────────────────────────────────────────────
  /// ⚠️ IMPORTANT: Choose the correct URL for your testing environment:
  ///
  /// • Android EMULATOR ONLY → http://10.0.2.2:8000
  ///   (10.0.2.2 maps to your host machine's localhost)
  ///
  /// • Physical Android device (same WiFi) → http://YOUR_PC_IP:8000
  ///   Run `ipconfig` on Windows to find your LAN IP (e.g. 192.168.1.x)
  ///   Example: http://192.168.1.100:8000
  ///
  /// • Production (VPS) → https://api.jaannetwork.com
  ///
  /// The upload error "SocketConnection timed out, address = 10.0.2.2"
  /// means you're using the emulator URL on a physical device.
  /// ─────────────────────────────────────────────────────────────────
  static const String vpsBaseUrl = 'http://127.0.0.1:8000';

  /// Full endpoint for file upload.
  static const String uploadFileUrl = '$vpsBaseUrl/api/upload';

  /// Full endpoint for file deletion.
  static const String deleteFileUrl = '$vpsBaseUrl/api/delete';

  /// â”€â”€ PayHere Sandbox Configuration â”€â”€
  /// Dummy credentials for testing out the PayHere integration.
  static const bool payHereIsSandbox = true;
  static const String payHereMerchantId =
      '1235338'; // dummy Sandbox Merchant ID
  static const String payHereAppSecret =
      'MjMxMDA1MTQ1NDYxNTI3OTkyNTQ1NDMwODA1MjEwNDcyNDEzOTE='; // dummy app secret
  static const String payHereNotifyUrl =
      '$vpsBaseUrl/api/payhere/notify'; // replace with real webhook eventually
}
