import 'dart:convert';
import 'api_service.dart';
import 'auth_service.dart';
import '../models/habit_model.dart';
import '../models/habit_instance_model.dart';

class HabitService {
  // Get all habits (only active)
  static Future<List<HabitModel>> getHabits() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await ApiService.authenticatedRequest(
      'GET',
      '/habits',
      token: token,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => HabitModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to fetch habits');
    }
  }

  // Get all habits including deleted ones
  static Future<List<HabitModel>> getAllHabits() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await ApiService.authenticatedRequest(
      'GET',
      '/habits/all',
      token: token,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => HabitModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to fetch all habits');
    }
  }

  // Create habit
  static Future<HabitModel> createHabit({
    required String title,
    String? description,
    bool? isOneTime,
    HabitRecurrence? recurrence,
    int? difficulty,
    String? reminderTime,
    bool? hasReminder,
    String? color,
    double? targetValue,
    String? targetUnit,
    bool? hasEndDate,
    String? endDateType,
    DateTime? endDate,
    int? endDays,
    int? timeOfDay,
    List<int>? dailyDays,
    List<int>? monthlyDays,
    DateTime? oneTimeDate,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final body = <String, dynamic>{
      'title': title,
      if (description != null) 'description': description,
      if (isOneTime != null) 'is_one_time': isOneTime,
      if (recurrence != null) 'recurrence': recurrence.value,
      if (difficulty != null) 'difficulty': difficulty,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (hasReminder != null) 'has_reminder': hasReminder,
      if (color != null) 'color': color,
      if (targetValue != null) 'target_value': targetValue,
      if (targetUnit != null) 'target_unit': targetUnit,
      if (hasEndDate != null) 'has_end_date': hasEndDate,
      if (endDateType != null) 'end_date_type': endDateType,
      if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
      if (endDays != null) 'end_days': endDays,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (dailyDays != null) 'daily_days': dailyDays,
      if (monthlyDays != null) 'monthly_days': monthlyDays,
      if (oneTimeDate != null) 'one_time_date': oneTimeDate.toIso8601String().split('T')[0],
    };

    final response = await ApiService.authenticatedRequest(
      'POST',
      '/habits',
      token: token,
      body: body,
    );

    if (response.statusCode == 201) {
      return HabitModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to create habit');
    }
  }

  // Update habit
  static Future<HabitModel> updateHabit(
    String habitId, {
    String? title,
    String? description,
    bool? isOneTime,
    HabitRecurrence? recurrence,
    int? difficulty,
    String? reminderTime,
    bool? hasReminder,
    String? color,
    double? targetValue,
    String? targetUnit,
    bool? hasEndDate,
    String? endDateType,
    DateTime? endDate,
    int? endDays,
    int? timeOfDay,
    List<int>? dailyDays,
    List<int>? monthlyDays,
    DateTime? oneTimeDate,
    bool? isDeleted,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (isOneTime != null) 'is_one_time': isOneTime,
      if (recurrence != null) 'recurrence': recurrence.value,
      if (difficulty != null) 'difficulty': difficulty,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (hasReminder != null) 'has_reminder': hasReminder,
      if (color != null) 'color': color,
      // targetValue ve targetUnit için null değerleri de gönder (hedef kaldırılması için)
      'target_value': targetValue,
      'target_unit': targetUnit,
      if (hasEndDate != null) 'has_end_date': hasEndDate,
      if (endDateType != null) 'end_date_type': endDateType,
      if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
      if (endDays != null) 'end_days': endDays,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (dailyDays != null) 'daily_days': dailyDays,
      if (monthlyDays != null) 'monthly_days': monthlyDays,
      if (oneTimeDate != null) 'one_time_date': oneTimeDate.toIso8601String().split('T')[0],
      if (isDeleted != null) 'is_deleted': isDeleted,
    };

    final response = await ApiService.authenticatedRequest(
      'PATCH',
      '/habits/$habitId',
      token: token,
      body: body,
    );

    if (response.statusCode == 200) {
      return HabitModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to update habit');
    }
  }

  // Delete habit
  static Future<void> deleteHabit(String habitId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await ApiService.authenticatedRequest(
      'DELETE',
      '/habits/$habitId',
      token: token,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to delete habit');
    }
  }

  // Check habit (complete/incomplete)
  static Future<HabitInstanceModel> checkHabit(
    String habitId, {
    String? date,
    bool? completed,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await ApiService.authenticatedRequest(
      'POST',
      '/habits/$habitId/check',
      token: token,
      body: {
        if (date != null) 'date': date,
        if (completed != null) 'completed': completed,
      },
    );

    if (response.statusCode == 200) {
      return HabitInstanceModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to check habit');
    }
  }

  // Get habit instances
  static Future<List<HabitInstanceModel>> getHabitInstances(
    String habitId, {
    String? startDate,
    String? endDate,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    String endpoint = '/habits/$habitId/instances';
    if (startDate != null || endDate != null) {
      final params = <String>[];
      if (startDate != null) params.add('start_date=$startDate');
      if (endDate != null) params.add('end_date=$endDate');
      endpoint += '?${params.join('&')}';
    }

    final response = await ApiService.authenticatedRequest(
      'GET',
      endpoint,
      token: token,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => HabitInstanceModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to fetch habit instances');
    }
  }

  // Get all habit instances for user (all habits)
  static Future<List<HabitInstanceModel>> getAllHabitInstances() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await ApiService.authenticatedRequest(
      'GET',
      '/habits/instances/all',
      token: token,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => HabitInstanceModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['error'] ?? 'Failed to fetch all habit instances');
    }
  }
}

