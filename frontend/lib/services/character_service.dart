import 'dart:convert';
import 'api_service.dart';
import 'auth_service.dart';
import '../models/character_model.dart';

class CharacterService {
  // Get user's character
  static Future<CharacterModel?> getCharacter() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await ApiService.authenticatedRequest(
      'GET',
      '/characters',
      token: token,
    );

    if (response.statusCode == 200) {
      return CharacterModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      return null; // Character not found
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to fetch character');
    }
  }

  // Create character (initial selection)
  static Future<CharacterModel> createCharacter({
    required CharacterType type,
    String? customName,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await ApiService.authenticatedRequest(
      'POST',
      '/characters',
      token: token,
      body: {
        'type': type.value,
        if (customName != null && customName.isNotEmpty) 'custom_name': customName,
      },
    );

    if (response.statusCode == 201) {
      return CharacterModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to create character');
    }
  }

  // Update character
  static Future<CharacterModel> updateCharacter({
    CharacterType? type,
    String? customName,
    int? level,
    int? energy,
    int? happiness,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await ApiService.authenticatedRequest(
      'PATCH',
      '/characters',
      token: token,
      body: {
        if (type != null) 'type': type.value,
        if (customName != null) 'custom_name': customName,
        if (level != null) 'level': level,
        if (energy != null) 'energy': energy,
        if (happiness != null) 'happiness': happiness,
      },
    );

    if (response.statusCode == 200) {
      return CharacterModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to update character');
    }
  }
}

