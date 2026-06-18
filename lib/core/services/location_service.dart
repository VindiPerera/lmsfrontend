import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  /// Fetches the user's country code based on their IP address.
  /// Defaults to 'US' if there is an error.
  static Future<String> getUserCountryCode() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['countryCode'] ?? 'US';
      }
    } catch (e) {
      // Ignored for fallback
    }
    return 'US'; // Fallback
  }
}
