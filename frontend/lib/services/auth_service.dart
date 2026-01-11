import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Token'ı kaydet
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Token'ı al
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // User bilgilerini kaydet
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // User bilgilerini al
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // Kullanıcının giriş yapıp yapmadığını kontrol et
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Çıkış yap - tüm auth bilgilerini sil
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Register
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await ApiService.publicRequest(
      'POST',
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        if (displayName != null) 'display_name': displayName,
      },
    );

    if (response.statusCode == 201) {
      final responseBody = response.body;
      if (responseBody.isEmpty) {
        throw Exception('Empty response from server');
      }
      
      final data = jsonDecode(responseBody);
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid response format');
      }
      
      // Token ve user bilgilerini kaydet
      if (data['token'] != null) {
        await saveToken(data['token'].toString());
      }
      if (data['user'] != null && data['user'] is Map) {
        try {
          final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
          await saveUser(user);
        } catch (e) {
          print('Error parsing user data: $e');
          // User parse edilemese bile token varsa devam et
        }
      }
      
      return data;
    } else {
      final responseBody = response.body;
      if (responseBody.isEmpty) {
        throw Exception('Registration failed with status ${response.statusCode}');
      }
      
      try {
        final error = jsonDecode(responseBody);
        if (error is Map && error['error'] != null) {
          throw Exception(error['error'].toString());
        }
        throw Exception('Registration failed');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Registration failed: ${response.statusCode}');
      }
    }
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.publicRequest(
      'POST',
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final responseBody = response.body;
      if (responseBody.isEmpty) {
        throw Exception('Empty response from server');
      }
      
      final data = jsonDecode(responseBody);
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid response format');
      }
      
      // Token ve user bilgilerini kaydet
      if (data['token'] != null) {
        await saveToken(data['token'].toString());
      }
      if (data['user'] != null && data['user'] is Map) {
        try {
          final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
          await saveUser(user);
        } catch (e) {
          print('Error parsing user data: $e');
          // User parse edilemese bile token varsa devam et
        }
      }
      
      return data;
    } else {
      final responseBody = response.body;
      if (responseBody.isEmpty) {
        throw Exception('Login failed with status ${response.statusCode}');
      }
      
      try {
        final error = jsonDecode(responseBody);
        if (error is Map && error['error'] != null) {
          throw Exception(error['error'].toString());
        }
        throw Exception('Login failed');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Login failed: ${response.statusCode}');
      }
    }
  }

  // Get current user profile from backend
  static Future<UserModel> getUserProfile() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await ApiService.authenticatedRequest(
      'GET',
      '/auth/me',
      token: token,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = UserModel.fromJson(data);
      // Update local storage
      await saveUser(user);
      return user;
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to fetch user profile');
    }
  }
}

