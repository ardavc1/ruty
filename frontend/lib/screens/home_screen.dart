import 'package:flutter/material.dart';
import 'habit_selection_screen.dart';
import 'character_selection_screen.dart';
import 'progress_screen.dart';
import 'habit_detail_screen.dart';
import 'focus_screen.dart';
import '../models/habit_model.dart';
import '../services/habit_service.dart';
import '../services/character_service.dart';
import '../services/auth_service.dart';
import '../models/character_model.dart';
import '../models/user_model.dart';
import 'settings_screen.dart';
import 'achievements_screen.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _TasksTab(),
    const ProgressScreen(),
    const _CharacterTab(),
    const _ProfileTab(),
    const FocusScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: themeProvider.primaryColor,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist),
              label: 'Görevler',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights),
              label: 'İlerleme',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: 'Karakter',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer),
              label: 'Odaklanma',
            ),
          ],
        ),
      ),
    );
  }
}

// Görevler Tab
class _TasksTab extends StatefulWidget {
  const _TasksTab();

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  List<HabitModel> _habits = [];
  Map<String, bool> _habitCompletions = {}; // habitId -> isCompleted
  CharacterModel? _character;
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedCalendarDate = DateTime.now(); // Takvim için odaklanılan tarih

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Önce karakteri yükle (timeout ile)
      try {
        final character = await CharacterService.getCharacter()
            .timeout(const Duration(seconds: 5));
        
        // Karakter yoksa karakter seçim ekranına gönder
        if (character == null) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/character-selection');
          return;
        }
        
        setState(() {
          _character = character;
        });
      } catch (e) {
        // Hata kontrolü
        final errorMessage = e.toString().toLowerCase();
        
        // Network/backend hatası - login ekranına gönder
        if (errorMessage.contains('timeout') || 
            errorMessage.contains('connection') ||
            errorMessage.contains('failed to fetch') ||
            errorMessage.contains('network') ||
            errorMessage.contains('not authenticated')) {
          if (!mounted) return;
          // Token geçersiz olabilir, logout yap ve login'e gönder
          await AuthService.logout();
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }
        
        // Karakter bulunamadı veya başka hata - karakter seçim ekranına gönder
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/character-selection');
        return;
      }

      // Sonra alışkanlıkları yükle
      try {
        final habits = await HabitService.getHabits();
        
        // Her habit için seçili tarihe göre completion durumunu kontrol et
        final completions = <String, bool>{};
        for (final habit in habits) {
          final isCompleted = await _checkHabitCompletionForDate(habit, _selectedDate);
          completions[habit.id] = isCompleted;
        }
        
        setState(() {
          _habits = habits;
          _habitCompletions = completions;
          _isLoading = false;
        });
      } catch (e) {
        // Alışkanlıklar yüklenemezse sadece hata göster, karakter varsa devam et
        setState(() {
          _habits = [];
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleHabit(HabitModel habit, bool completed) async {
    try {
      final targetDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final requiredDate = _getRequiredDateForDate(habit, _selectedDate);
      final requiredDateOnly = DateTime(requiredDate.year, requiredDate.month, requiredDate.day);
      
      // Hangi tarih için işaretlenecek?
      DateTime checkDate;
      
      switch (habit.recurrence) {
        case HabitRecurrence.daily:
          // Günlük görevler: seçili tarih dailyDays listesinde olmalı
          if (habit.dailyDays != null && habit.dailyDays!.isNotEmpty) {
            final dayOfWeek = targetDate.weekday;
            if (!habit.dailyDays!.contains(dayOfWeek)) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bu gün için görev bulunamadı'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
          }
          // Seçili tarih için işaretle
          checkDate = targetDate;
          break;
        case HabitRecurrence.weekly:
          // Haftalık görevler: bu haftanın pazartesi günü için işaretle
          checkDate = requiredDateOnly;
          // Seçili tarih bu hafta içinde mi kontrol et
          final weekStart = requiredDateOnly;
          final weekEnd = weekStart.add(const Duration(days: 6));
          if (targetDate.isBefore(weekStart) || targetDate.isAfter(weekEnd)) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bu hafta için görev bulunamadı'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          break;
        case HabitRecurrence.monthly:
          // Aylık görevler: seçili tarih monthlyDays listesinde olmalı
          final dayOfMonth = targetDate.day;
          if (habit.monthlyDays == null || !habit.monthlyDays!.contains(dayOfMonth)) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bu tarih için görev bulunamadı'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          // Seçili tarih için işaretle
          checkDate = targetDate;
          // Seçili tarih ayın o günü mü kontrol et
          if (!requiredDateOnly.isAtSameMomentAs(targetDate)) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bu ay için görev bulunamadı'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          break;
      }
      
      final checkDateStr = DateFormat('yyyy-MM-dd').format(checkDate);
      
      await HabitService.checkHabit(
        habit.id,
        date: checkDateStr,
        completed: completed,
      );
      
      // Completion durumunu güncelle
      final updatedCompletions = <String, bool>{};
      for (final h in _habits) {
        if (h.id == habit.id) {
          updatedCompletions[h.id] = completed;
        } else {
          updatedCompletions[h.id] = _habitCompletions[h.id] ?? false;
        }
      }
      
      setState(() {
        _habitCompletions = updatedCompletions;
      });
      
      // Reload data to get updated character stats and refresh the list
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // Seçili tarihe göre yapılması gereken tarihi hesapla
  DateTime _getRequiredDateForDate(HabitModel habit, DateTime selectedDate) {
    final targetDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
    switch (habit.recurrence) {
      case HabitRecurrence.daily:
        return targetDate;
      case HabitRecurrence.weekly:
        // Haftalık görevler için: görev oluşturulduğu haftanın pazartesi günü
        // Ama seçili tarih için bu haftanın pazartesi gününü döndür
        final weekday = selectedDate.weekday; // 1=Monday, 7=Sunday
        final daysFromMonday = weekday - 1;
        return targetDate.subtract(Duration(days: daysFromMonday));
      case HabitRecurrence.monthly:
        // Aylık görevler için: seçili ayın monthlyDays listesindeki ilk günü
        // (toggle için kullanılıyor, o yüzden ilk seçili günü döndürüyoruz)
        if (habit.monthlyDays != null && habit.monthlyDays!.isNotEmpty) {
          final firstDay = habit.monthlyDays!.first;
          try {
            return DateTime(selectedDate.year, selectedDate.month, firstDay);
          } catch (e) {
            // Eğer ayın o günü yoksa (örn: 31 Şubat), ayın son gününü kullan
            final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
            return DateTime(selectedDate.year, selectedDate.month, firstDay > lastDayOfMonth ? lastDayOfMonth : firstDay);
          }
        }
        // Eğer günler belirtilmemişse, oluşturulduğu günü kullan
        final dayOfMonth = habit.createdAt.day;
        try {
          return DateTime(selectedDate.year, selectedDate.month, dayOfMonth);
        } catch (e) {
          final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
          return DateTime(selectedDate.year, selectedDate.month, dayOfMonth > lastDayOfMonth ? lastDayOfMonth : dayOfMonth);
        }
    }
  }

  // Bir sonraki yapılması gereken tarihi hesapla
  DateTime _getNextRequiredDate(HabitModel habit, DateTime currentDate) {
    final currentRequiredDate = _getRequiredDateForDate(habit, currentDate);
    
    switch (habit.recurrence) {
      case HabitRecurrence.daily:
        return currentRequiredDate.add(const Duration(days: 1));
      case HabitRecurrence.weekly:
        return currentRequiredDate.add(const Duration(days: 7));
      case HabitRecurrence.monthly:
        // Aylık görevler için: monthlyDays listesindeki ilk günün bir sonraki ayı
        if (habit.monthlyDays != null && habit.monthlyDays!.isNotEmpty) {
          final firstDay = habit.monthlyDays!.first;
          if (currentRequiredDate.month == 12) {
            try {
              return DateTime(currentRequiredDate.year + 1, 1, firstDay);
            } catch (e) {
              final lastDay = DateTime(currentRequiredDate.year + 1, 2, 0).day;
              return DateTime(currentRequiredDate.year + 1, 1, firstDay > lastDay ? lastDay : firstDay);
            }
          } else {
            try {
              return DateTime(currentRequiredDate.year, currentRequiredDate.month + 1, firstDay);
            } catch (e) {
              final lastDay = DateTime(currentRequiredDate.year, currentRequiredDate.month + 2, 0).day;
              return DateTime(currentRequiredDate.year, currentRequiredDate.month + 1, firstDay > lastDay ? lastDay : firstDay);
            }
          }
        }
        // Eğer monthlyDays yoksa eski mantık
        final dayOfMonth = habit.createdAt.day;
        if (currentRequiredDate.month == 12) {
          try {
            return DateTime(currentRequiredDate.year + 1, 1, dayOfMonth);
          } catch (e) {
            final lastDay = DateTime(currentRequiredDate.year + 1, 2, 0).day;
            return DateTime(currentRequiredDate.year + 1, 1, dayOfMonth > lastDay ? lastDay : dayOfMonth);
          }
        } else {
          try {
            return DateTime(currentRequiredDate.year, currentRequiredDate.month + 1, dayOfMonth);
          } catch (e) {
            final lastDay = DateTime(currentRequiredDate.year, currentRequiredDate.month + 2, 0).day;
            return DateTime(currentRequiredDate.year, currentRequiredDate.month + 1, dayOfMonth > lastDay ? lastDay : dayOfMonth);
          }
        }
    }
  }

  // Habit'in seçili tarih için tamamlanıp tamamlanmadığını kontrol et
  Future<bool> _checkHabitCompletionForDate(HabitModel habit, DateTime selectedDate) async {
    try {
      final targetDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final requiredDate = _getRequiredDateForDate(habit, selectedDate);
      final requiredDateOnly = DateTime(requiredDate.year, requiredDate.month, requiredDate.day);
      
      // Seçili tarih için kontrol edilecek tarih
      DateTime checkDate;
      
      switch (habit.recurrence) {
        case HabitRecurrence.daily:
          // Günlük görevler: seçili tarih dailyDays listesinde olmalı
          if (habit.dailyDays != null && habit.dailyDays!.isNotEmpty) {
            final dayOfWeek = targetDate.weekday;
            if (!habit.dailyDays!.contains(dayOfWeek)) {
              return false; // Bu gün için görev yok
            }
          }
          // Seçili tarih için kontrol et
          checkDate = targetDate;
          break;
        case HabitRecurrence.weekly:
          // Haftalık görevler: bu haftanın pazartesi günü için kontrol et
          checkDate = requiredDateOnly;
          // Seçili tarih bu hafta içinde mi?
          final weekStart = requiredDateOnly;
          final weekEnd = weekStart.add(const Duration(days: 6));
          if (targetDate.isBefore(weekStart) || targetDate.isAfter(weekEnd)) {
            return false; // Bu hafta için görev yok
          }
          break;
        case HabitRecurrence.monthly:
          // Aylık görevler: seçili tarihin günü monthlyDays listesinde olmalı
          final dayOfMonth = targetDate.day;
          if (habit.monthlyDays == null || !habit.monthlyDays!.contains(dayOfMonth)) {
            return false; // Bu tarih için görev yok
          }
          // Seçili tarih için kontrol et
          checkDate = targetDate;
          break;
      }
      
      final checkDateStr = DateFormat('yyyy-MM-dd').format(checkDate);
      
      final instances = await HabitService.getHabitInstances(
        habit.id,
        startDate: checkDateStr,
        endDate: checkDateStr,
      );
      
      if (instances.isEmpty) {
        return false;
      }
      
      return instances.first.completed;
    } catch (e) {
      return false;
    }
  }

  // Habit'in bugün/yapılması gereken tarih için tamamlanıp tamamlanmadığını kontrol et
  Future<bool> _checkHabitCompletion(HabitModel habit) async {
    return _checkHabitCompletionForDate(habit, DateTime.now());
  }

  // Seçili tarihe göre tüm görevleri getir (kategori ayrımı yok)
  List<HabitModel> _getAllHabitsForDate(DateTime selectedDate) {
    final allHabits = <HabitModel>[];
    final targetDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
    // Tek seferlik görevleri kontrol et
    for (final habit in _habits) {
      if (habit.isOneTime && habit.oneTimeDate != null) {
        final oneTimeDateOnly = DateTime(
          habit.oneTimeDate!.year,
          habit.oneTimeDate!.month,
          habit.oneTimeDate!.day,
        );
        
        // End date kontrolü - end date dahil, sonrası hariç
        bool shouldShow = true;
        if (habit.hasEndDate) {
          DateTime? endDateOnly;
          
          if (habit.endDateType == 'date' && habit.endDate != null) {
            endDateOnly = DateTime(
              habit.endDate!.year,
              habit.endDate!.month,
              habit.endDate!.day,
            );
          } else if (habit.endDateType == 'days' && habit.endDays != null) {
            final habitStartDate = DateTime(
              habit.createdAt.year,
              habit.createdAt.month,
              habit.createdAt.day,
            );
            final endDate = habitStartDate.add(Duration(days: habit.endDays!));
            endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
          }
          
          if (endDateOnly != null) {
            // targetDate > endDateOnly kontrolü
            if (targetDate.year > endDateOnly.year ||
                (targetDate.year == endDateOnly.year && targetDate.month > endDateOnly.month) ||
                (targetDate.year == endDateOnly.year && 
                 targetDate.month == endDateOnly.month && 
                 targetDate.day > endDateOnly.day)) {
              shouldShow = false;
            }
          }
        }
        
        // Tek seferlik görev sadece belirlenen tarihte gösterilir
        if (shouldShow && isSameDay(oneTimeDateOnly, targetDate)) {
          allHabits.add(habit);
        }
      }
    }
    
    allHabits.addAll(_getHabitsForDate(selectedDate, HabitRecurrence.daily));
    allHabits.addAll(_getHabitsForDate(selectedDate, HabitRecurrence.weekly));
    allHabits.addAll(_getHabitsForDate(selectedDate, HabitRecurrence.monthly));
    return allHabits;
  }

  // Seçili tarihe göre görevleri recurrence tipine göre filtrele
  // Sadece o gün için geçerli görevleri göster
  List<HabitModel> _getHabitsForDate(DateTime selectedDate, HabitRecurrence recurrence) {
    final targetDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
    return _habits.where((habit) {
      if (habit.recurrence != recurrence) return false;
      
      // End date kontrolü - end date dahil, sonrası hariç
      if (habit.hasEndDate) {
        DateTime? endDateOnly;
        
        if (habit.endDateType == 'date' && habit.endDate != null) {
          // Belirli bir tarih sonlandırma
          endDateOnly = DateTime(
            habit.endDate!.year,
            habit.endDate!.month,
            habit.endDate!.day,
          );
        } else if (habit.endDateType == 'days' && habit.endDays != null) {
          // Gün sayısı ile sonlandırma
          final habitStartDate = DateTime(
            habit.createdAt.year,
            habit.createdAt.month,
            habit.createdAt.day,
          );
          final endDate = habitStartDate.add(Duration(days: habit.endDays!));
          endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
        }
        
        if (endDateOnly != null) {
          // Seçili tarih son tarihten sonra ise görev gösterilmez (end date dahil)
          // targetDate.compareTo(endDateOnly) > 0 kontrolü
          if (targetDate.year > endDateOnly.year ||
              (targetDate.year == endDateOnly.year && targetDate.month > endDateOnly.month) ||
              (targetDate.year == endDateOnly.year && 
               targetDate.month == endDateOnly.month && 
               targetDate.day > endDateOnly.day)) {
            return false;
          }
        }
      }
      
      final isCompleted = _habitCompletions[habit.id] ?? false;
      
      switch (recurrence) {
        case HabitRecurrence.daily:
          // Günlük görevler: dailyDays listesindeki günlerde geçerli
          if (habit.dailyDays != null && habit.dailyDays!.isNotEmpty) {
            // Seçili tarihin haftanın hangi günü olduğunu al (1=Monday, 7=Sunday)
            final dayOfWeek = targetDate.weekday;
            
            // Bu gün dailyDays listesinde var mı?
            final isDaySelected = habit.dailyDays!.contains(dayOfWeek);
            
            if (!isDaySelected) {
              return false; // Bu gün seçili değilse gösterilmez
            }
          }
          
          if (isCompleted) {
            // Tamamlanmışsa, bir sonraki seçili gün kontrol et
            final requiredDate = _getRequiredDateForDate(habit, selectedDate);
            final nextDate = _getNextRequiredDate(habit, requiredDate);
            final nextDateOnly = DateTime(nextDate.year, nextDate.month, nextDate.day);
            // Bir sonraki seçili gün geldiyse veya geçtiyse göster
            return !nextDateOnly.isAfter(targetDate);
          }
          
          return true; // Tamamlanmamış günlük görevler seçili günlerde gösterilir
          
        case HabitRecurrence.weekly:
          // Haftalık görevler: bu hafta için geçerli (haftanın herhangi bir gününde gösterilir)
          final requiredDate = _getRequiredDateForDate(habit, selectedDate);
          final requiredDateOnly = DateTime(requiredDate.year, requiredDate.month, requiredDate.day);
          final weekStart = requiredDateOnly;
          final weekEnd = weekStart.add(const Duration(days: 6));
          
          // Seçili tarih bu hafta içinde mi?
          final isInThisWeek = !targetDate.isBefore(weekStart) && !targetDate.isAfter(weekEnd);
          
          if (isCompleted) {
            // Bu hafta tamamlandıysa, bir sonraki hafta kontrol et
            final nextDate = _getNextRequiredDate(habit, requiredDate);
            final nextWeekStart = DateTime(nextDate.year, nextDate.month, nextDate.day);
            final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
            // Bir sonraki hafta geldiyse veya geçtiyse göster
            return !targetDate.isBefore(nextWeekStart) && !targetDate.isAfter(nextWeekEnd);
          }
          
          // Bu hafta için göster
          return isInThisWeek;
          
        case HabitRecurrence.monthly:
          // Aylık görevler: monthlyDays listesinde belirtilen günlerde gösterilir
          if (habit.monthlyDays == null || habit.monthlyDays!.isEmpty) {
            return false; // Eğer günler belirtilmemişse gösterilmez
          }
          
          // Seçili tarihin ayın kaçıncı günü olduğunu al
          final dayOfMonth = targetDate.day;
          
          // Bu gün monthlyDays listesinde var mı?
          final isDaySelected = habit.monthlyDays!.contains(dayOfMonth);
          
          if (!isDaySelected) {
            return false; // Bu gün seçili değilse gösterilmez
          }
          
          // Seçili tarih için tamamlama durumunu kontrol et
          if (isCompleted) {
            // Bu ayın bu günü tamamlandıysa, bir sonraki ayın aynı günü kontrol et
            // Bir sonraki ayın bu günü geçmişte mi veya bugün mü?
            DateTime nextMonthDate;
            if (targetDate.month == 12) {
              nextMonthDate = DateTime(targetDate.year + 1, 1, dayOfMonth);
            } else {
              try {
                nextMonthDate = DateTime(targetDate.year, targetDate.month + 1, dayOfMonth);
              } catch (e) {
                // Ayın bu günü yoksa, son gününü al
                final lastDay = DateTime(targetDate.year, targetDate.month + 2, 0).day;
                nextMonthDate = DateTime(targetDate.year, targetDate.month + 1, dayOfMonth > lastDay ? lastDay : dayOfMonth);
              }
            }
            // Bir sonraki ayın bu günü geldiyse veya geçtiyse göster
            return !nextMonthDate.isAfter(targetDate);
          }
          
          // Bu ayın bu günü için göster
          return true;
      }
    }).toList();
  }

  Future<void> _deleteHabit(HabitModel habit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alışkanlığı Sil'),
        content: Text('${habit.title} alışkanlığını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await HabitService.deleteHabit(habit.id);
        _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alışkanlık silindi')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onDateChanged(DateTime newDate) async {
    setState(() {
      _selectedDate = newDate;
      _focusedCalendarDate = newDate;
    });
    
    // Yeni tarih için completion durumlarını güncelle
    final completions = <String, bool>{};
    for (final habit in _habits) {
      final isCompleted = await _checkHabitCompletionForDate(habit, newDate);
      completions[habit.id] = isCompleted;
    }
    
    setState(() {
      _habitCompletions = completions;
    });
  }

  // Takvim dialog'unu göster
  void _showCalendarDialog(BuildContext context) {
    DateTime localFocusedDate = _focusedCalendarDate;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext dialogContext, StateSetter setDialogState) {
            return Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Başlık
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tarih Seç',
                            style: context.textStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(dialogContext),
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Takvim
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: localFocusedDate,
                        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                        calendarFormat: CalendarFormat.month,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: context.textStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          leftChevronIcon: Icon(
                            Icons.chevron_left,
                            color: themeProvider.primaryColor,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: themeProvider.primaryColor,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: themeProvider.primaryColor.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: themeProvider.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          outsideDaysVisible: false,
                          weekendTextStyle: context.defaultTextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        locale: 'tr_TR',
                        onDaySelected: (selectedDay, focusedDay) {
                          // Tarih seçildiğinde dialog'u kapat ve tarihi güncelle
                          Navigator.pop(dialogContext);
                          _onDateChanged(selectedDay);
                        },
                        onPageChanged: (focusedDay) {
                          // Takvim sayfası değiştiğinde odaklanılan tarihi güncelle
                          setDialogState(() {
                            localFocusedDate = focusedDay;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: null, // AppBar'ı kaldırıyoruz, greeting card içinde olacak
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hata: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: Column(
                    children: [
                      // Greeting Section
                      if (_character != null)
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, _) => Container(
                            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                            color: Colors.white,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Merhaba, ${_character!.customName ?? _character!.type.label}',
                                        style: context.defaultTextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('EEEE, d MMMM yyyy', 'en_US').format(_selectedDate),
                                        style: context.defaultTextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF5F5F5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getCharacterEmoji(_character!.type),
                                      style: TextStyle(fontSize: context.scaledFontSize(30)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Date Selector
                      _buildDateSelector(),
                      // Habits List
                      Expanded(
                        child: _habits.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.checklist_rounded,
                                      size: 80,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 20),
                                    Consumer<ThemeProvider>(
                                      builder: (context, themeProvider, _) => Text(
                                        'Henüz alışkanlık eklemedin',
                                        style: context.defaultTextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Consumer<ThemeProvider>(
                                      builder: (context, themeProvider, _) => Text(
                                        'Yeni bir alışkanlık eklemek için\nsağ üstteki + butonuna tıkla',
                                        textAlign: TextAlign.center,
                                        style: context.defaultTextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const HabitSelectionScreen(),
                                          ),
                                        );
                                        if (result == true) {
                                          _loadData();
                                        }
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('İlk Alışkanlığını Ekle'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                                children: [
                                  // "Günlük Görevler" header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Consumer<ThemeProvider>(
                                        builder: (context, themeProvider, _) => Text(
                                          'Günlük Görevler',
                                          style: context.textStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Consumer<ThemeProvider>(
                                        builder: (context, themeProvider, _) => TextButton(
                                          onPressed: () => _showCalendarDialog(context),
                                          child: Text(
                                            'Takvim',
                                            style: context.textStyle(
                                              fontSize: 14,
                                              color: themeProvider.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Tüm görevler tek listede
                                  ..._getAllHabitsForDate(_selectedDate)
                                      .map((habit) => _buildCompactHabitCard(habit, _selectedDate)),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HabitSelectionScreen()),
            );
            if (result == true) {
              _loadData();
            }
          },
          backgroundColor: themeProvider.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => Container(
        height: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.white,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 14, // Son 7 ve sonraki 7 gün
          itemBuilder: (context, index) {
            final date = DateTime.now().subtract(Duration(days: 7 - index));
            final isSelected = date.year == _selectedDate.year &&
                date.month == _selectedDate.month &&
                date.day == _selectedDate.day;
            final isToday = date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day;
            
            return GestureDetector(
              onTap: () => _onDateChanged(date),
              child: Container(
                width: 50,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEE', 'tr_TR').format(date).substring(0, 3),
                      style: context.textStyle(
                        fontSize: 12,
                        color: isSelected
                            ? themeProvider.primaryColor
                            : (isToday ? themeProvider.primaryColor : Colors.grey[600]),
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? themeProvider.primaryColor
                            : (isToday
                                ? themeProvider.primaryColor.withOpacity(0.2)
                                : Colors.transparent),
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(color: themeProvider.primaryColor, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: context.textStyle(
                            fontSize: 16,
                            color: isSelected
                                ? Colors.white
                                : (isToday ? themeProvider.primaryColor : Colors.grey[700]),
                            fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
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

  Widget _buildSectionHeader(String title) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => Text(
        title,
        style: context.textStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getCharacterEmoji(CharacterType type) {
    switch (type) {
      case CharacterType.cat:
        return '🐱';
      case CharacterType.dog:
        return '🐶';
      case CharacterType.rabbit:
        return '🐰';
      case CharacterType.fox:
        return '🦊';
    }
  }

  Widget _buildStat(String label, String value) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: context.whiteTextStyle(
                fontSize: 12,
              ).copyWith(color: Colors.white.withOpacity(0.8)),
            ),
            Text(
              value,
              style: context.whiteTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHabitCard(HabitModel habit, DateTime selectedDate) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isCompleted = _habitCompletions[habit.id] ?? false;
        Color habitColor = themeProvider.primaryColor;
        if (habit.color != null) {
          try {
            final colorString = habit.color!.replaceAll('#', '');
            habitColor = Color(int.parse(colorString, radix: 16) + 0xFF000000);
          } catch (e) {
            habitColor = themeProvider.primaryColor;
          }
        }

        // İkon rengi için farklı renkler kullan
        final iconColors = [
          const Color(0xFF8B4513), // Brown
          const Color(0xFF4CAF50), // Green
          const Color(0xFFE91E63), // Pink
          const Color(0xFFD4A574), // Light brown
        ];
        final iconColor = iconColors[habit.title.hashCode.abs() % iconColors.length];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HabitDetailScreen(habit: habit),
                ),
              );
              if (result == true) {
                _loadData();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Renkli ikon kutusu
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getHabitIcon(habit.title),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Habit Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          style: context.defaultTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tamamlama durumu (boş daire / tikli daire)
                  GestureDetector(
                    onTap: () {
                      _toggleHabit(habit, !isCompleted);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCompleted ? habitColor : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted ? habitColor : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getHabitIcon(String title) {
    // Basit ikon eşleştirmesi
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('water') || lowerTitle.contains('su')) {
      return Icons.water_drop;
    } else if (lowerTitle.contains('meditate') || lowerTitle.contains('meditasyon')) {
      return Icons.self_improvement;
    } else if (lowerTitle.contains('stretch') || lowerTitle.contains('germe')) {
      return Icons.fitness_center;
    } else if (lowerTitle.contains('walk') || lowerTitle.contains('yürü')) {
      return Icons.directions_walk;
    } else if (lowerTitle.contains('book') || lowerTitle.contains('kitap')) {
      return Icons.book;
    } else if (lowerTitle.contains('sport') || lowerTitle.contains('spor')) {
      return Icons.sports_basketball;
    } else {
      return Icons.check_circle;
    }
  }
}


// Karakter Tab
class _CharacterTab extends StatefulWidget {
  const _CharacterTab();

  @override
  State<_CharacterTab> createState() => _CharacterTabState();
}

class _CharacterTabState extends State<_CharacterTab> {
  CharacterModel? _character;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCharacter();
  }

  Future<void> _loadCharacter() async {
    try {
      final character = await CharacterService.getCharacter();
      setState(() {
        _character = character;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Karakterim'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _character == null
              ? const Center(child: Text('Karakter yüklenemedi'))
              : RefreshIndicator(
                  onRefresh: _loadCharacter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Character Card
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, _) => Card(
                            color: themeProvider.lightColor,
                          child: Padding(
                            padding: const EdgeInsets.all(30),
                            child: Column(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                    child: Consumer<ThemeProvider>(
                                      builder: (context, themeProvider, _) => Center(
                                        child: Text(
                                          _getCharacterEmoji(_character!.type),
                                          style: TextStyle(fontSize: context.scaledFontSize(70)),
                                        ),
                                      ),
                                    ),
                                ),
                                const SizedBox(height: 20),
                                Consumer<ThemeProvider>(
                                  builder: (context, themeProvider, _) => Text(
                                    _character!.customName ?? _character!.type.label,
                                    style: context.whiteTextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Consumer<ThemeProvider>(
                                  builder: (context, themeProvider, _) => Text(
                                    'Seviye ${_character!.level}',
                                    style: context.whiteTextStyle(
                                      fontSize: 18,
                                    ).copyWith(color: Colors.white.withOpacity(0.9)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Change Character Button
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, _) => SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CharacterSelectionScreen(),
                                  ),
                                );
                                if (result == true) {
                                  _loadCharacter();
                                }
                              },
                              icon: Icon(Icons.swap_horiz, color: themeProvider.primaryColor),
                              label: Builder(
                                builder: (ctx) => Text(
                                  'Karakteri Değiştir',
                                  style: ctx.textStyle(
                                    fontSize: 16,
                                    color: themeProvider.primaryColor,
                                  ),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: themeProvider.primaryColor,
                                side: BorderSide(color: themeProvider.primaryColor, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Stats
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Consumer<ThemeProvider>(
                                  builder: (context, themeProvider, _) => Text(
                                    'İstatistikler',
                                    style: context.defaultTextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildStatRow(
                                  'Toplam XP',
                                  '${_character!.totalXp}',
                                  Icons.stars,
                                  Colors.amber,
                                ),
                                const SizedBox(height: 15),
                                _buildStatRow(
                                  'Enerji',
                                  '${_character!.energy}/100',
                                  Icons.battery_charging_full,
                                  Colors.green,
                                ),
                                const SizedBox(height: 15),
                                _buildStatRow(
                                  'Mutluluk',
                                  '${_character!.happiness}/100',
                                  Icons.favorite,
                                  Colors.pink,
                                ),
                                const SizedBox(height: 20),
                                // XP Progress
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Consumer<ThemeProvider>(
                                          builder: (context, themeProvider, _) => Text(
                                            'Seviye ${_character!.level} → Seviye ${_character!.level + 1}',
                                            style: context.defaultTextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Consumer<ThemeProvider>(
                                          builder: (context, themeProvider, _) => Text(
                                            '${_character!.currentLevelXp} / ${_character!.xpForNextLevel} XP',
                                            style: context.defaultTextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: _character!.xpForNextLevel > 0
                                          ? _character!.currentLevelXp /
                                              _character!.xpForNextLevel
                                          : 0,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Provider.of<ThemeProvider>(context, listen: false).primaryColor,
                                      ),
                                      minHeight: 8,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  String _getCharacterEmoji(CharacterType type) {
    switch (type) {
      case CharacterType.cat:
        return '🐱';
      case CharacterType.dog:
        return '🐶';
      case CharacterType.rabbit:
        return '🐰';
      case CharacterType.fox:
        return '🦊';
    }
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: context.scaledFontSize(24)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.defaultTextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: context.defaultTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Profil Tab (Placeholder)
class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  UserModel? _user;
  bool _isLoading = true;
  String _motivationalMessage = '';

  // Motivasyon mesajları listesi
  static const List<String> _motivationalMessages = [
    'Her adım, hedefe giden yolda değerlidir! 💪',
    'Bugün yaptığın küçük şeyler, yarın büyük farklar yaratır. ✨',
    'Kendine inan, başarabilirsin! 🌟',
    'Disiplin, başarının anahtarıdır. 🔑',
    'Her gün biraz daha iyileş, sen değerlisin! 💎',
    'Hedeflerin için çalış, hayallerin gerçekleşsin! 🎯',
    'Bugün dünden daha iyi ol, yarın bugünden daha iyi ol! 📈',
    'Sabır ve azim, her kapıyı açar. 🚪',
    'Başarı bir yolculuk, hedef değil. Yolculuğun tadını çıkar! 🛤️',
    'Her başlangıç bir adımdır, bugün ilk adımı at! 👣',
    'Kendine güven, potansiyelin sınırsız! 🚀',
    'Zorluklar seni güçlendirir, pes etme! 💪',
    'Bugün dünün meyvesidir, yarın bugünün meyvesi olacak! 🍎',
    'Küçük ilerlemeler, büyük başarılar getirir! 🎊',
    'Kendinle yarış, dünkü senden daha iyi ol! 🏃',
    'Her gün yeni bir fırsat, bugünü kaçırma! ☀️',
    'Başarısızlık bir son değil, öğrenme fırsatıdır! 📚',
    'İlerlemek için hareket et, harekete geç! ⚡',
    'Hayallerini gerçeğe dönüştürmek senin elinde! 🌈',
    'Her gün yeni bir başlangıç, yeni bir umut! 🌸',
    'Kendini aş, sınırlarını zorla! 🔥',
    'Azimle çalış, başarı seni bulacak! 💼',
    'Bugün yapılacaklar listesi hazırla ve başla! 📋',
    'Her küçük başarı, büyük zaferlerin temelidir! 🏆',
    'Kendine yatırım yap, en değerli yatırım sensin! 💰',
    'Hedeflerine odaklan, dikkatini dağıtma! 🎯',
    'Her gün biraz daha yaklaş, sonuca ulaşacaksın! 🎯',
    'Zamanını doğru kullan, hayatın efendisi ol! ⏰',
    'İyi alışkanlıklar, güzel bir gelecek demektir! 🌟',
    'Bugün yaptığın seçimler, yarını şekillendirir! 🔮',
    'Kendini motive et, başarı seni bekliyor! 💫',
    'Her zorluk, seni daha güçlü yapar! 💪',
    'Sabırla ilerle, sonunda başaracaksın! 🐢',
    'Hayallerin peşinden git, gerçek olacaklar! 🌠',
    'Küçük adımlar büyük sonuçlar doğurur! 👟',
    'Her gün yeni bir şey öğren, gelişmeye devam et! 📖',
    'Kendini şımartma, kendini geliştir! 🌱',
    'Bugün başla, yarın farkı gör! 🌅',
    'Azim ve kararlılık, her kapıyı açar! 🚪',
    'Kendine inan, başaracaksın! ⭐',
  ];

  @override
  void initState() {
    super.initState();
    // Rastgele bir motivasyon mesajı seç
    _motivationalMessage = _motivationalMessages[
        DateTime.now().millisecondsSinceEpoch % _motivationalMessages.length];
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Her zaman database'den (backend'den) kullanıcı bilgilerini çek
      // created_at bilgisi database'de users tablosunda mevcut
      final user = await AuthService.getUserProfile();
      if (!mounted) return;
      
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Hata durumunda kullanıcıya bilgi ver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kullanıcı bilgileri yüklenemedi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Bugün katıldın';
    } else if (difference.inDays == 1) {
      return 'Dün katıldın';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} gün önce katıldın';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 
          ? '1 ay önce katıldın'
          : '$months ay önce katıldın';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 
          ? '1 yıl önce katıldın'
          : '$years yıl önce katıldın';
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış yapılırken hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Profil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUser,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Motivasyon Mesajı
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              themeProvider.primaryColor.withOpacity(0.1),
                              themeProvider.primaryColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: themeProvider.primaryColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: themeProvider.primaryColor,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _motivationalMessage,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Account Info Section
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF499BCF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.email,
                                color: Color(0xFF499BCF),
                              ),
                            ),
                            title: const Text('E-posta'),
                            subtitle: Text(_user?.email ?? 'Bilinmiyor'),
                          ),
                          // Üyelik tarihi - database'den çekiliyor
                          const Divider(height: 1),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                color: Colors.purple,
                              ),
                            ),
                            title: const Text('Üyelik Tarihi'),
                            subtitle: Text(
                              _user?.createdAt != null
                                  ? _formatJoinDate(_user!.createdAt!)
                                  : 'Yükleniyor...',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Achievements Button
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) => SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AchievementsScreen(),
                              ),
                            );
                          },
                          icon: Icon(Icons.emoji_events, color: themeProvider.primaryColor),
                          label: Text(
                            'Başarımlar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.primaryColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: themeProvider.primaryColor,
                            side: BorderSide(color: themeProvider.primaryColor, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Settings Button
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) => SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                          icon: Icon(Icons.settings, color: themeProvider.primaryColor),
                          label: Text(
                            'Ayarlar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.primaryColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: themeProvider.primaryColor,
                            side: BorderSide(color: themeProvider.primaryColor, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          'Çıkış Yap',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}


