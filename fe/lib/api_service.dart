import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  // Update this IP address to match your LAN
  static const String baseUrl = 'http://127.0.0.1:8000'; // Replace with the actual IP
  
  static const Duration timeout = Duration(seconds: 10);

  /// Call the harmonize endpoint
  static Future<Uint8List> harmonize(List<MusicEvent> events) async {
    final request = HarmonizeRequest(
      durationSec: 10,
      events: events,
    );

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/harmonize'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode(request.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          errorData['error_code'] ?? 'unknown_error',
          errorData['message'] ?? 'Unknown error occurred',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('network_error', 'Network error: $e');
    }
  }

  /// Call the evaluation endpoint
  static Future<EvaluateResponse> evaluate(List<MusicEvent> events) async {
    final request = EvaluateRequest(
      durationSec: 10,
      events: events,
    );

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/evaluate'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode(request.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EvaluateResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw ApiException(
          errorData['error_code'] ?? 'unknown_error',
          errorData['message'] ?? 'Unknown error occurred',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('network_error', 'Network error: $e');
    }
  }

  /// Check whether the backend is reachable
  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class ApiException implements Exception {
  final String errorCode;
  final String message;

  ApiException(this.errorCode, this.message);

  @override
  String toString() => 'API Error [$errorCode]: $message';
}