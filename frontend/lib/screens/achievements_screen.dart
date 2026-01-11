import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character_model.dart';
import '../models/user_model.dart';
import '../models/habit_instance_model.dart';
import '../services/character_service.dart';
import '../services/auth_service.dart';
import '../services/habit_service.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  CharacterModel? _character;
  UserModel? _user;
  List<HabitInstanceModel> _completedInstances = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Paralel olarak veri çek (timeout yok)
      final results = await Future.wait([
        CharacterService.getCharacter(),
        AuthService.getUserProfile(),
        HabitService.getAllHabitInstances(),
      ]);

      if (!mounted) return;

      setState(() {
        _character = results[0] as CharacterModel?;
        _user = results[1] as UserModel;
        final allInstances = results[2] as List<HabitInstanceModel>;
        _completedInstances = allInstances.where((i) => i.completed).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Başarımlar listesi
  List<Achievement> get _achievements {
    final characterLevel = _character?.level ?? 0;
    final completedTasks = _completedInstances.length;
    final daysSinceJoined = _user?.createdAt != null
        ? DateTime.now().difference(_user!.createdAt!).inDays
        : 0;

    return [
      // Level başarımları (her 5 level)
      ...List.generate(10, (index) {
        final targetLevel = (index + 1) * 5;
        return Achievement(
          id: 'level_$targetLevel',
          title: 'Level $targetLevel\'a Ulaş',
          description: 'Hayvanını $targetLevel. seviyeye çıkar',
          icon: Icons.stars,
          target: targetLevel,
          current: characterLevel,
          category: AchievementCategory.level,
        );
      }),

      // Görev tamamlama başarımları
      Achievement(
        id: 'tasks_25',
        title: 'İlk Adımlar',
        description: '25 görev tamamla',
        icon: Icons.check_circle_outline,
        target: 25,
        current: completedTasks,
        category: AchievementCategory.tasks,
      ),
      Achievement(
        id: 'tasks_50',
        title: 'Yarı Yolda',
        description: '50 görev tamamla',
        icon: Icons.check_circle,
        target: 50,
        current: completedTasks,
        category: AchievementCategory.tasks,
      ),
      Achievement(
        id: 'tasks_100',
        title: 'Yüzler Kulübü',
        description: '100 görev tamamla',
        icon: Icons.emoji_events,
        target: 100,
        current: completedTasks,
        category: AchievementCategory.tasks,
      ),
      Achievement(
        id: 'tasks_200',
        title: 'Başarı Ustası',
        description: '200 görev tamamla',
        icon: Icons.workspace_premium,
        target: 200,
        current: completedTasks,
        category: AchievementCategory.tasks,
      ),
      Achievement(
        id: 'tasks_500',
        title: 'Efsane',
        description: '500 görev tamamla',
        icon: Icons.military_tech,
        target: 500,
        current: completedTasks,
        category: AchievementCategory.tasks,
      ),

      // Kayıt olma süresi başarımları
      Achievement(
        id: 'streak_1',
        title: 'İlk Gün',
        description: '1 gün üye ol',
        icon: Icons.calendar_today,
        target: 1,
        current: daysSinceJoined,
        category: AchievementCategory.streak,
      ),
      Achievement(
        id: 'streak_30',
        title: 'Bir Ay',
        description: '1 ay üye ol',
        icon: Icons.calendar_month,
        target: 30,
        current: daysSinceJoined,
        category: AchievementCategory.streak,
      ),
      Achievement(
        id: 'streak_180',
        title: 'Altı Ay',
        description: '6 ay üye ol',
        icon: Icons.event,
        target: 180,
        current: daysSinceJoined,
        category: AchievementCategory.streak,
      ),
      Achievement(
        id: 'streak_365',
        title: 'Bir Yıl',
        description: '1 yıl üye ol',
        icon: Icons.cake,
        target: 365,
        current: daysSinceJoined,
        category: AchievementCategory.streak,
      ),

      // Ek başarımlar
      Achievement(
        id: 'xp_1000',
        title: 'XP Toplayıcı',
        description: '1000 XP kazan',
        icon: Icons.auto_awesome,
        target: 1000,
        current: _character?.totalXp ?? 0,
        category: AchievementCategory.xp,
      ),
      Achievement(
        id: 'xp_5000',
        title: 'XP Ustası',
        description: '5000 XP kazan',
        icon: Icons.workspace_premium,
        target: 5000,
        current: _character?.totalXp ?? 0,
        category: AchievementCategory.xp,
      ),
      Achievement(
        id: 'xp_10000',
        title: 'XP Efsanesi',
        description: '10000 XP kazan',
        icon: Icons.stars,
        target: 10000,
        current: _character?.totalXp ?? 0,
        category: AchievementCategory.xp,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
            'Başarımlar',
            style: context.textStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: themeProvider.primaryColor,
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: themeProvider.primaryColor,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İstatistik Özeti
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              themeProvider.primaryColor.withOpacity(0.1),
                              themeProvider.primaryColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: themeProvider.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Kazanılan',
                              _achievements.where((a) => a.isCompleted).length,
                              _achievements.length,
                              Icons.emoji_events,
                              themeProvider.primaryColor,
                            ),
                            _buildStatItem(
                              'İlerleme',
                              _achievements.where((a) => a.progress > 0 && !a.isCompleted).length,
                              _achievements.length,
                              Icons.trending_up,
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Başarımlar Listesi
                      ..._achievements.map((achievement) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildAchievementCard(achievement, themeProvider),
                          )),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, int total, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement, ThemeProvider themeProvider) {
    final isCompleted = achievement.isCompleted;
    final progress = achievement.progress;
    final color = isCompleted ? themeProvider.primaryColor : Colors.grey[400]!;

    return Card(
      elevation: isCompleted ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted ? color.withOpacity(0.3) : Colors.grey[300]!,
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // İkon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    achievement.icon,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                // Başlık ve Açıklama
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              achievement.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            Icon(
                              Icons.check_circle,
                              color: color,
                              size: 24,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // İlerleme Çubuğu
            if (!isCompleted)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'İlerleme',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${achievement.current}/${achievement.target}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tamamlandı! 🎉',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Başarım Modeli
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int target;
  final int current;
  final AchievementCategory category;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    required this.current,
    required this.category,
  });

  bool get isCompleted => current >= target;

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
}

enum AchievementCategory {
  level,
  tasks,
  streak,
  xp,
}
