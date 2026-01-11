class HabitInstanceModel {
  final String id;
  final String habitId;
  final DateTime date;
  final bool completed;
  final int xpAwarded;
  final bool isDeleted;
  final DateTime updatedAt;

  HabitInstanceModel({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
    this.xpAwarded = 0,
    this.isDeleted = false,
    required this.updatedAt,
  });

  factory HabitInstanceModel.fromJson(Map<String, dynamic> json) {
    // Date string'i parse et - backend'den 'YYYY-MM-DD' formatında geliyor
    final dateStr = json['date'] as String;
    final dateParts = dateStr.split('T')[0].split('-');
    final date = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );
    
    return HabitInstanceModel(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      date: date, // Local date olarak parse et
      completed: json['completed'] as bool,
      xpAwarded: json['xp_awarded'] as int? ?? 0,
      isDeleted: json['is_deleted'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': date.toIso8601String().split('T')[0],
      'completed': completed,
      'xp_awarded': xpAwarded,
      'is_deleted': isDeleted,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

