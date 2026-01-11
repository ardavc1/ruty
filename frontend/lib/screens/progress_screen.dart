import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/habit_service.dart';
import '../models/habit_model.dart';
import '../models/habit_instance_model.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<HabitModel> _habits = [];
  List<HabitInstanceModel> _allInstances = [];
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Tüm verileri paralel olarak çek (timeout yok, bekleyeceğiz)
      final results = await Future.wait([
        HabitService.getAllHabits(),
        AuthService.getUserProfile(),
        HabitService.getAllHabitInstances(),
      ]);
      
      if (!mounted) return;
      
      final allHabits = results[0] as List<HabitModel>;
      final user = results[1] as UserModel;
      final allInstances = results[2] as List<HabitInstanceModel>;
      
      setState(() {
        _habits = allHabits;
        _allInstances = allInstances;
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // İstatistikleri hesapla
  int get _totalHabitsCreated => _habits.length;
  
  int get _totalHabitsCompleted {
    return _allInstances.where((instance) => instance.completed).length;
  }
  
  double get _completionPercentage {
    if (_totalHabitsCreated == 0) return 0.0;
    return (_totalHabitsCompleted / _totalHabitsCreated) * 100;
  }
  
  String get _mostActiveDay {
    if (_allInstances.isEmpty) return 'Henüz yok';
    
    // Haftanın günlerini say
    final dayCounts = <int, int>{};
    for (final instance in _allInstances.where((i) => i.completed)) {
      // DateTime.weekday: 1=Monday, 2=Tuesday, ..., 7=Sunday
      // Date'i local timezone'a çevir ve weekday kullan
      final localDate = instance.date.toLocal();
      final weekday = localDate.weekday;
      dayCounts[weekday] = (dayCounts[weekday] ?? 0) + 1;
    }
    
    if (dayCounts.isEmpty) return 'Henüz yok';
    
    final mostActiveWeekday = dayCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    // weekday 1=Pazartesi, 2=Salı, ..., 7=Pazar
    final dayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    // Array index 0'dan başlıyor, weekday 1'den başlıyor, bu yüzden -1 yapıyoruz
    return dayNames[mostActiveWeekday - 1];
  }
  
  int get _daysSinceJoined {
    if (_user?.createdAt == null) return 0;
    final now = DateTime.now();
    final joined = _user!.createdAt!;
    return now.difference(joined).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            'İstatistiklerim',
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
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: context.scaledFontSize(48),
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hata: $_errorMessage',
                          style: context.defaultTextStyle(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: Text(
                            'Yeniden Dene',
                            style: context.textStyle(),
                          ),
                        ),
                      ],
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
                          // İstatistik Kartları
                          _buildStatCard(
                            'Kaç Tane Alışkanlık Oluşturdun?',
                            _totalHabitsCreated.toString(),
                            Icons.add_task,
                            themeProvider.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Kaç Tanesini Tamamladın?',
                            _totalHabitsCompleted.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Tamamlama Yüzdesi',
                            '${_completionPercentage.toStringAsFixed(1)}%',
                            Icons.percent,
                            Colors.orange,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: LinearProgressIndicator(
                                value: _completionPercentage / 100,
                                minHeight: 8,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'En Çok Hangi Gün Görev Yaptın?',
                            _mostActiveDay,
                            Icons.calendar_today,
                            Colors.purple,
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Uygulamaya Kaç Gündür Üyesin?',
                            '$_daysSinceJoined gün',
                            Icons.access_time,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {Widget? child}) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: context.textStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: context.textStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (child != null) child,
          ],
        ),
      ),
    );
  }
}
