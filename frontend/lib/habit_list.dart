import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/habit_add_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HabitFrequency {
  daily,
  weekly,
}

extension HabitFrequencyText on HabitFrequency {
  String get label {
    switch (this) {
      case HabitFrequency.daily:
        return 'Günlük';
      case HabitFrequency.weekly:
        return 'Haftalık';
    }
  }
}

class Habit {
  final String name;
  final String? description;
  final IconData icon;
  final Color color;
  final HabitFrequency frequency;

  int completedCount; // toplam kaç kez yapılmış
  int targetPerWeek; // haftalık hedef (günlük için 7, haftalık için 1 gibi)
  bool isCompletedToday;

  Habit({
    required this.name,
    this.description,
    required this.icon,
    required this.color,
    required this.frequency,
    this.completedCount = 0,
    this.targetPerWeek = 7,
    this.isCompletedToday = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.toARGB32(), // mevcut projendeki yardımcıyı korudum
      'frequency': frequency.name,
      'completedCount': completedCount,
      'targetPerWeek': targetPerWeek,
      'isCompletedToday': isCompletedToday,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
      ),
      color: Color(json['colorValue'] as int),
      frequency: HabitFrequency.values
          .firstWhere((e) => e.name == (json['frequency'] as String)),
      completedCount: (json['completedCount'] as int?) ?? 0,
      targetPerWeek: (json['targetPerWeek'] as int?) ?? 7,
      isCompletedToday: (json['isCompletedToday'] as bool?) ?? false,
    );
  }
}

class HabitListScreen extends StatefulWidget {
  const HabitListScreen({super.key});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  // Başlangıçta boş liste, sonradan storage'dan dolduracağız
  List<Habit> _habits = [];


  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> habitJsonList = prefs.getStringList('habits') ?? [];

    setState(() {
      _habits = habitJsonList
          .map((e) => Habit.fromJson(jsonDecode(e) as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitJsonList = _habits.map((h) => jsonEncode(h.toJson())).toList();
    await prefs.setStringList('habits', habitJsonList);
  }

  void _toggleHabitToday(int index) {
    setState(() {
      final habit = _habits[index];
      if (habit.isCompletedToday) {
        habit.isCompletedToday = false;
        habit.completedCount = (habit.completedCount - 1).clamp(0, 9999);
      } else {
        habit.isCompletedToday = true;
        habit.completedCount++;
      }
    });
    _saveHabits();
  }

  void _removeHabit(int index) {
    setState(() {
      _habits.removeAt(index);
    });
    _saveHabits();
  }

  double _calculateWeeklyProgress(Habit habit) {
    if (habit.targetPerWeek <= 0) return 0;
    final value = habit.completedCount / habit.targetPerWeek;
    return value.clamp(0, 1);
  }

  void _addHabit(
    String name,
    String? description,
    HabitFrequency frequency,
    IconData icon,
    Color color,
  ) {
    setState(() {
      _habits.add(
        Habit(
          name: name,
          description: description,
          icon: icon,
          color: color,
          frequency: frequency,
          targetPerWeek: frequency == HabitFrequency.daily ? 7 : 1,
        ),
      );
    });
    _saveHabits();
  }

  // NOT: Artık dialog kullanılmıyor; elindeki ayrı sayfaya yönlendireceğiz.
  // _openAddHabitDialog() fonksiyonunu kaldırdım.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışkanlıklar'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HabitAddPage(), 
            ),
          ).then((_) {
            // Sayfadan dönünce listeyi yenile (ör. yeni kayıtlar geldiyse)
            _loadHabits();
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni alışkanlık'),
      ),
      body: SafeArea(
        child: _habits.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _habits.length,
                separatorBuilder: (_ , _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final habit = _habits[index];
                  final progress = _calculateWeeklyProgress(habit);

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon + renkli arka plan
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: habit.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              habit.icon,
                              color: habit.color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Orta kısım (isim, açıklama, progress)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                if (habit.description != null &&
                                    habit.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      habit.description!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tip: ${habit.frequency.label}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                // Progress bar + info
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 8,
                                          backgroundColor:
                                              Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${habit.completedCount}/${habit.targetPerWeek}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Haftalık hedef',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Sağ tarafta: bugün tamamla + sil
                          Column(
                            children: [
                              IconButton(
                                onPressed: () => _toggleHabitToday(index),
                                icon: Icon(
                                  habit.isCompletedToday
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: habit.isCompletedToday
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                              Text(
                                'Bugün',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: Colors.grey[700]),
                              ),
                              IconButton(
                                onPressed: () => _removeHabit(index),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.checklist_rounded,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz alışkanlık eklemedin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Başlamak için aşağıdaki butondan yeni bir alışkanlık ekleyebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ÖRNEK: Hedef sayfan için placeholder (kendi sayfanla değiştir)
class AddHabitScreen extends StatelessWidget {
  const AddHabitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Alışkanlık Ekranı')),
      body: const Center(
        child: Text('Buraya elindeki form/ekran gelecek'),
      ),
    );
  }
}
