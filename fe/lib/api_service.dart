import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  // 修改这个 IP 地址为你的局域网 IP
  static const String baseUrl = 'http://127.0.0.1:8000'; // 请修改为实际IP
  
  static const Duration timeout = Duration(seconds: 10);

  /// 调用和声生成接口
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

  /// 调用评估接口
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

  /// 检查后端连接
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