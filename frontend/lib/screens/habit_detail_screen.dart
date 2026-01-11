import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/habit_model.dart';
import '../services/habit_service.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';
import 'habit_add_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  final HabitModel habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late HabitModel _habit;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _editHabit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitAddScreen(habitToEdit: _habit),
      ),
    );
    
    // Güncelleme yapıldıysa verileri yeniden yükle
    if (result == true || result is HabitModel) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Database'den fresh data çek
        final allHabits = await HabitService.getHabits();
        final updatedHabit = allHabits.firstWhere((h) => h.id == _habit.id);
        
        if (mounted) {
          setState(() {
            _habit = updatedHabit;
            _isLoading = false;
          });
        }
      } catch (e) {
        // Habit bulunamadı (silinmiş olabilir)
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _deleteHabit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alışkanlığı Sil'),
        content: Text('${_habit.title} alışkanlığını silmek istediğinize emin misiniz?'),
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
      setState(() {
        _isLoading = true;
      });

      try {
        await HabitService.deleteHabit(_habit.id);
        if (!mounted) return;
        Navigator.pop(context, true); // true = silindi, listeyi yenile
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            _habit.title,
            style: context.textStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _isLoading ? null : () => _editHabit(context),
              tooltip: 'Düzenle',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _deleteHabit,
              tooltip: 'Sil',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Habit Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Açıklama',
                              style: context.textStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _habit.description ?? 'Açıklama yok',
                              style: context.defaultTextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildInfoChip(
                                  context,
                                  'Tip',
                                  _habit.isOneTime ? 'Tek Seferlik' : _habit.recurrence.label,
                                  themeProvider.primaryColor,
                                ),
                                _buildInfoChip(
                                  context,
                                  'Zorluk',
                                  '${_habit.difficulty}/5',
                                  themeProvider.primaryColor,
                                ),
                                if (_habit.reminderTime != null)
                                  _buildInfoChip(
                                    context,
                                    'Hatırlatıcı',
                                    _habit.reminderTime!,
                                    themeProvider.primaryColor,
                                  ),
                                if (_habit.timeOfDay != null) ...[
                                  _buildInfoChip(
                                    context,
                                    'Yapılma Zamanı',
                                    _getTimeOfDayLabel(_habit.timeOfDay!),
                                    themeProvider.primaryColor,
                                  ),
                                ],
                                if (_habit.hasEndDate) ...[
                                  _buildInfoChip(
                                    context,
                                    'Bitiş Tarihi',
                                    _getEndDateLabel(),
                                    themeProvider.primaryColor,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Hedef Card (sadece gösterim)
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hedef',
                              style: context.textStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: themeProvider.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: themeProvider.primaryColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flag,
                                    color: themeProvider.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _getTargetDisplayText(),
                                      style: context.textStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: themeProvider.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

  String _getTimeOfDayLabel(int timeOfDay) {
    switch (timeOfDay) {
      case 0:
        return 'Sabah';
      case 1:
        return 'Öğleden Sonra';
      case 2:
        return 'Akşam';
      default:
        return 'Belirtilmemiş';
    }
  }

  String _getEndDateLabel() {
    if (!_habit.hasEndDate) {
      return 'Yok';
    }
    
    if (_habit.endDateType == 'date' && _habit.endDate != null) {
      return DateFormat('d MMMM yyyy', 'tr_TR').format(_habit.endDate!);
    } else if (_habit.endDateType == 'days' && _habit.endDays != null) {
      return '${_habit.endDays} gün sonra';
    }
    
    return 'Belirtilmemiş';
  }

  String _getTargetDisplayText() {
    final targetValue = _habit.targetValue;
    final targetUnit = _habit.targetUnit;
    
    if (targetValue != null && targetUnit != null) {
      // Hem değer hem birim var
      final valueStr = targetValue % 1 == 0 
          ? targetValue.toInt().toString() 
          : targetValue.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      return '$valueStr $targetUnit';
    } else if (targetValue != null) {
      // Sadece değer var
      return targetValue % 1 == 0 
          ? targetValue.toInt().toString() 
          : targetValue.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    } else if (targetUnit != null) {
      // Sadece birim var (bu normalde olmamalı ama yine de gösterelim)
      return targetUnit;
    } else {
      // Hiçbiri yok
      return 'Hedef belirtilmemiş';
    }
  }

  Widget _buildInfoChip(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: context.textStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
