import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Backend API Base URL
  static String getApiBaseUrl() {
    // Environment variable'dan URL al (öncelikli)
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // Platform bazlı varsayılan URL'ler
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else if (Platform.isAndroid) {
      // Android emülatör için 10.0.2.2 (localhost'un Android emülatördeki karşılığı)
      // Gerçek cihaz için: Bilgisayarınızın yerel IP adresini kullanın
      return 'http://10.0.2.2:8080';
    } else if (Platform.isIOS) {
      // iOS simulator için localhost
      // Gerçek cihaz için: Bilgisayarınızın yerel IP adresini kullanın
      return 'http://localhost:8080';
    } else {
      // Desktop (Windows, Linux, macOS) için localhost
      return 'http://localhost:8080';
    }
  }

  static String get baseUrl => getApiBaseUrl();

  // Token ile authenticated request yap
  static Future<http.Response> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Public request (auth gerektirmeyen)
  static Future<http.Response> publicRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {'Content-Type': 'application/json'};

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await http.get(url, headers: headers);
        case 'POST':
          return await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Health check
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await publicRequest('GET', '/health');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Backend connection failed: $e');
    }
  }
}

