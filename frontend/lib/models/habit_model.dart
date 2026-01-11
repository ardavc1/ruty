enum HabitRecurrence {
  daily('daily', 'Günlük'),
  weekly('weekly', 'Haftalık'),
  monthly('monthly', 'Aylık');

  final String value;
  final String label;

  const HabitRecurrence(this.value, this.label);
}

class HabitModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final bool isOneTime; // Tek seferlik görev mi?
  final HabitRecurrence recurrence;
  final int difficulty; // 1-5 arası
  final String? reminderTime; // HH:MM formatında
  final bool hasReminder; // Hatırlatıcı aktif mi?
  final String? color; // Hex color
  final double? targetValue; // Hedef değer (sayı)
  final String? targetUnit; // Hedef birim (km, ml, saat, adım, vb.)
  final bool hasEndDate; // Son tarih belirtilmiş mi?
  final String? endDateType; // 'date' veya 'days'
  final DateTime? endDate; // Son tarih
  final int? endDays; // Gün sayısı
  final int? timeOfDay; // 0=Sabah, 1=Öğleden Sonra, 2=Akşam
  final List<int>? dailyDays; // Günlük görevler için seçilen hafta günleri (1-7)
  final List<int>? monthlyDays; // Aylık görevler için seçilen ay günleri (1-31)
  final DateTime? oneTimeDate; // Tek seferlik görev tarihi
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  HabitModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.isOneTime = false,
    required this.recurrence,
    this.difficulty = 1,
    this.reminderTime,
    this.hasReminder = false,
    this.color,
    this.targetValue,
    this.targetUnit,
    this.hasEndDate = false,
    this.endDateType,
    this.endDate,
    this.endDays,
    this.timeOfDay,
    this.dailyDays,
    this.monthlyDays,
    this.oneTimeDate,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isOneTime: json['is_one_time'] as bool? ?? false,
      recurrence: HabitRecurrence.values.firstWhere(
        (e) => e.value == json['recurrence'],
        orElse: () => HabitRecurrence.daily,
      ),
      difficulty: json['difficulty'] as int? ?? 1,
      reminderTime: json['reminder_time'] as String?,
      hasReminder: json['has_reminder'] as bool? ?? false,
      color: json['color'] as String?,
      targetValue: json['target_value'] != null 
          ? (json['target_value'] is num 
              ? (json['target_value'] as num).toDouble() 
              : (double.tryParse(json['target_value'].toString()) ?? null))
          : null,
      targetUnit: json['target_unit'] as String?,
      hasEndDate: json['has_end_date'] as bool? ?? false,
      endDateType: json['end_date_type'] as String?,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      endDays: json['end_days'] as int?,
      timeOfDay: json['time_of_day'] as int?,
      dailyDays: json['daily_days'] != null 
          ? List<int>.from(json['daily_days'] as List)
          : null,
      monthlyDays: json['monthly_days'] != null 
          ? List<int>.from(json['monthly_days'] as List)
          : null,
      oneTimeDate: json['one_time_date'] != null 
          ? DateTime.parse(json['one_time_date'] as String)
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'is_one_time': isOneTime,
      'recurrence': recurrence.value,
      'difficulty': difficulty,
      'reminder_time': reminderTime,
      'has_reminder': hasReminder,
      'color': color,
      'target_value': targetValue,
      'target_unit': targetUnit,
      'has_end_date': hasEndDate,
      'end_date_type': endDateType,
      'end_date': endDate?.toIso8601String().split('T')[0],
      'end_days': endDays,
      'time_of_day': timeOfDay,
      'daily_days': dailyDays,
      'monthly_days': monthlyDays,
      'one_time_date': oneTimeDate?.toIso8601String().split('T')[0],
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

