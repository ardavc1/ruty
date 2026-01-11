import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/habit_model.dart';
import '../services/habit_service.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';

class HabitAddScreen extends StatefulWidget {
  final String? presetTitle;
  final Color? presetColor;
  final HabitModel? habitToEdit; // Düzenleme modu için

  const HabitAddScreen({
    super.key,
    this.presetTitle,
    this.presetColor,
    this.habitToEdit,
  });

  @override
  State<HabitAddScreen> createState() => _HabitAddScreenState();
}

class _HabitAddScreenState extends State<HabitAddScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final _targetValueController = TextEditingController();

  // Ana sekme: Tek Seferlik veya Tekrar Eden
  bool _isOneTimeTask = false; // false = Tekrar Eden, true = Tek Seferlik
  
  // Tekrar Eden için alt sekmeler
  late TabController _recurrenceTabController;
  HabitRecurrence _selectedRecurrence = HabitRecurrence.daily;
  
  late Color _selectedColor;
  TimeOfDay? _selectedReminderTime;
  bool _hasReminder = false;
  bool _isLoading = false;
  
  // Hedef
  bool _hasTarget = false;
  double? _targetValue;
  String? _targetUnit;
  final List<String> _targetUnits = ['km', 'ml', 'l', 'saat', 'adım'];
  
  // Günlük: hangi günler (P S C P C Ct Pz = Pazartesi, Salı, Çarşamba, Perşembe, Cuma, Cumartesi, Pazar)
  Set<int> _selectedDailyDays = {}; // 1=Monday, 7=Sunday
  bool _allDaysSelected = true;
  
  // Aylık: ayın hangi tarihleri
  Set<int> _selectedMonthlyDays = {}; // 1-31 arası
  
  // Tek seferlik: spesifik tarih
  DateTime? _oneTimeDate;
  
  // Son tarih (End Date)
  bool _hasEndDate = false;
  bool _endDateType = true; // true = Date, false = Days
  DateTime? _endDate;
  int? _endDays;
  final _endDaysController = TextEditingController();
  
  // Do it at (Saat dilimi)
  int _selectedTimeOfDay = 1; // 0=Morning, 1=Afternoon, 2=Evening
  
  // Takvim için
  DateTime _focusedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    
    // Edit mode kontrolü
    if (widget.habitToEdit != null) {
      // Mevcut habit bilgilerini yükle
      _titleController = TextEditingController(text: widget.habitToEdit!.title);
      _isOneTimeTask = widget.habitToEdit!.isOneTime;
      _selectedRecurrence = widget.habitToEdit!.recurrence;
      
      // Renk
      if (widget.habitToEdit!.color != null) {
        try {
          final colorString = widget.habitToEdit!.color!.replaceAll('#', '');
          _selectedColor = Color(int.parse(colorString, radix: 16) + 0xFF000000);
        } catch (e) {
          _selectedColor = const Color(0xFF499BCF);
        }
      } else {
        _selectedColor = const Color(0xFF499BCF);
      }
      
      // Hatırlatıcı
      _hasReminder = widget.habitToEdit!.hasReminder;
      if (widget.habitToEdit!.reminderTime != null) {
        final parts = widget.habitToEdit!.reminderTime!.split(':');
        if (parts.length == 2) {
          _selectedReminderTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      }
      
      // Hedef
      _hasTarget = widget.habitToEdit!.targetValue != null;
      _targetValue = widget.habitToEdit!.targetValue;
      _targetUnit = widget.habitToEdit!.targetUnit;
      if (_targetValue != null) {
        _targetValueController.text = _targetValue!.toString();
      }
      
      // Günlük günler
      if (widget.habitToEdit!.dailyDays != null && widget.habitToEdit!.dailyDays!.isNotEmpty) {
        _selectedDailyDays = widget.habitToEdit!.dailyDays!.toSet();
        _allDaysSelected = _selectedDailyDays.length == 7;
      } else {
        _selectedDailyDays = {1, 2, 3, 4, 5, 6, 7};
        _allDaysSelected = true;
      }
      
      // Aylık günler
      if (widget.habitToEdit!.monthlyDays != null && widget.habitToEdit!.monthlyDays!.isNotEmpty) {
        _selectedMonthlyDays = widget.habitToEdit!.monthlyDays!.toSet();
      }
      
      // Tek seferlik tarih
      _oneTimeDate = widget.habitToEdit!.oneTimeDate;
      
      // Son tarih
      _hasEndDate = widget.habitToEdit!.hasEndDate;
      _endDateType = widget.habitToEdit!.endDateType == 'days' ? false : true;
      _endDate = widget.habitToEdit!.endDate;
      _endDays = widget.habitToEdit!.endDays;
      if (_endDays != null) {
        _endDaysController.text = _endDays.toString();
      }
      
      // Yapılma saati
      _selectedTimeOfDay = widget.habitToEdit!.timeOfDay ?? 1;
      
      // Tab controller - recurrence'a göre index belirle
      final tabIndex = _selectedRecurrence == HabitRecurrence.daily ? 0 : 1;
      _recurrenceTabController = TabController(length: 2, vsync: this, initialIndex: tabIndex);
    } else {
      // Yeni habit oluşturma
      _titleController = TextEditingController(text: widget.presetTitle ?? '');
      _selectedColor = widget.presetColor ?? const Color(0xFF499BCF);
      _recurrenceTabController = TabController(length: 2, vsync: this);
      _selectedDailyDays = {1, 2, 3, 4, 5, 6, 7};
    }
    
    _recurrenceTabController.addListener(() {
      setState(() {
        // index 0 = daily, index 1 = monthly
        _selectedRecurrence = _recurrenceTabController.index == 0 
            ? HabitRecurrence.daily 
            : HabitRecurrence.monthly;
      });
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Yeni habit oluşturma modunda ve preset color yoksa theme color'u kullan
    if (widget.habitToEdit == null && widget.presetColor == null && _selectedColor == const Color(0xFF499BCF)) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      _selectedColor = themeProvider.primaryColor;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetValueController.dispose();
    _endDaysController.dispose();
    _recurrenceTabController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final colorHex = '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';

      String? reminderTime;
      if (_hasReminder && _selectedReminderTime != null) {
        final hour = _selectedReminderTime!.hour.toString().padLeft(2, '0');
        final minute = _selectedReminderTime!.minute.toString().padLeft(2, '0');
        reminderTime = '$hour:$minute';
      }

      // Recurrence belirleme
      final recurrence = _isOneTimeTask ? HabitRecurrence.daily : _selectedRecurrence;

      // Günlük günleri hazırla
      List<int>? dailyDaysList;
      if (!_isOneTimeTask && recurrence == HabitRecurrence.daily) {
        dailyDaysList = _selectedDailyDays.toList()..sort();
      }

      // Aylık günleri hazırla
      List<int>? monthlyDaysList;
      if (!_isOneTimeTask && recurrence == HabitRecurrence.monthly) {
        monthlyDaysList = _selectedMonthlyDays.toList()..sort();
      }

      // Tek seferlik tarih hazırla
      DateTime? oneTimeDateValue;
      if (_isOneTimeTask && _oneTimeDate != null) {
        oneTimeDateValue = _oneTimeDate;
      }

      // End date hazırla
      DateTime? endDateValue;
      int? endDaysValue;
      String? endDateTypeValue;
      bool hasEndDateValue = _hasEndDate;

      if (_hasEndDate) {
        if (_endDateType) {
          // Date tipi
          endDateValue = _endDate;
          endDateTypeValue = 'date';
        } else {
          // Days tipi
          endDaysValue = _endDays;
          endDateTypeValue = 'days';
        }
      }

      // Hedef değerleri hazırla
      double? targetValueToSave;
      String? targetUnitToSave;
      if (_hasTarget) {
        // Input'tan değer al (eğer varsa)
        if (_targetValueController.text.isNotEmpty) {
          targetValueToSave = double.tryParse(_targetValueController.text.replaceAll(',', '.'));
          targetUnitToSave = _targetUnit;
        } else if (_targetValue != null) {
          // Mevcut değer varsa kullan
          targetValueToSave = _targetValue;
          targetUnitToSave = _targetUnit;
        } else {
          // Hedef seçili ama değer yok
          targetValueToSave = null;
          targetUnitToSave = null;
        }
      } else {
        // Hedef seçili değilse null gönder (hedef kaldırılacak)
        targetValueToSave = null;
        targetUnitToSave = null;
      }

      // Edit mode mu yoksa yeni habit mi?
      if (widget.habitToEdit != null) {
        // Update existing habit
        await HabitService.updateHabit(
          widget.habitToEdit!.id,
          title: _titleController.text.trim(),
          description: null,
          isOneTime: _isOneTimeTask,
          recurrence: recurrence,
          difficulty: 1,
          reminderTime: reminderTime,
          hasReminder: _hasReminder,
          color: colorHex,
          targetValue: targetValueToSave,
          targetUnit: targetUnitToSave,
          hasEndDate: hasEndDateValue,
          endDateType: endDateTypeValue,
          endDate: endDateValue,
          endDays: endDaysValue,
          timeOfDay: _selectedTimeOfDay,
          dailyDays: dailyDaysList,
          monthlyDays: monthlyDaysList,
          oneTimeDate: oneTimeDateValue,
        );
      } else {
        // Create new habit
        await HabitService.createHabit(
          title: _titleController.text.trim(),
          description: null,
          isOneTime: _isOneTimeTask,
          recurrence: recurrence,
          difficulty: 1,
          reminderTime: reminderTime,
          hasReminder: _hasReminder,
          color: colorHex,
          targetValue: targetValueToSave,
          targetUnit: targetUnitToSave,
          hasEndDate: hasEndDateValue,
          endDateType: endDateTypeValue,
          endDate: endDateValue,
          endDays: endDaysValue,
          timeOfDay: _selectedTimeOfDay,
          dailyDays: dailyDaysList,
          monthlyDays: monthlyDaysList,
          oneTimeDate: oneTimeDateValue,
        );
      }

      if (!mounted) return;
      // Basitçe true döndür, detail screen kendisi refresh yapacak
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showTargetUnitPicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) => Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Birim Seç',
                    style: context.textStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _targetUnits.length,
                  itemBuilder: (context, index) {
                    final unit = _targetUnits[index];
                    return ListTile(
                      title: Text(
                        unit,
                        style: context.defaultTextStyle(fontSize: 16),
                      ),
                      trailing: _targetUnit == unit
                          ? Icon(Icons.check, color: themeProvider.primaryColor)
                          : null,
                      onTap: () {
                        setState(() {
                          _targetUnit = unit;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedReminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedReminderTime = picked;
      });
    }
  }

  Future<void> _selectOneTimeDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _oneTimeDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _oneTimeDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  String _getDayLabel(int day) {
    const labels = ['P', 'S', 'Ç', 'P', 'C', 'Ct', 'Pz'];
    return labels[day - 1];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
          color: Colors.grey[600],
        ),
        title:         Text(
          widget.habitToEdit != null ? 'Alışkanlığı Düzenle' : 'Yeni Alışkanlık Oluştur',
          style: context.textStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Ana Sekmeler: Tek Seferlik Görevler / Tekrar Eden Görevler
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isOneTimeTask = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isOneTimeTask ? themeProvider.primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Tekrar Eden Görevler',
                              style: TextStyle(
                                color: !_isOneTimeTask ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isOneTimeTask = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isOneTimeTask ? themeProvider.primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Tek Seferlik Görevler',
                              style: TextStyle(
                                color: _isOneTimeTask ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // İçerik
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Alışkanlık Adı
                      Text(
                        'Alışkanlık Adı',
                        style: context.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Alışkanlık adını girin',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Alışkanlık adı zorunludur';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Renk Seçimi
                      Text(
                        'Renk',
                        style: context.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildColorPicker(),
                      const SizedBox(height: 24),
                      
                      // Tekrar Eden veya Tek Seferlik içeriği
                      if (_isOneTimeTask) ...[
                        // Tek Seferlik Görev
                        _buildOneTimeTaskContent(),
                      ] else ...[
                        // Tekrar Eden Görevler
                        _buildRecurringTaskContent(),
                      ],
                      
                      // Hedef
                      Row(
                        children: [
                          Text(
                            'Hedef',
                            style: context.textStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Checkbox(
                            value: _hasTarget,
                            onChanged: (value) {
                              setState(() {
                                _hasTarget = value ?? false;
                                if (!_hasTarget) {
                                  _targetValue = null;
                                  _targetUnit = null;
                                  _targetValueController.clear();
                                }
                              });
                            },
                            activeColor: themeProvider.primaryColor,
                          ),
                        ],
                      ),
                      if (_hasTarget) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _targetValueController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'Hedef değer',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _targetValue = double.tryParse(value);
                                  });
                                },
                                validator: (value) {
                                  if (_hasTarget && (value == null || value.isEmpty)) {
                                    return 'Hedef değer zorunludur';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _showTargetUnitPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _targetUnit ?? 'Birim',
                                      style: context.defaultTextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey[600]),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      
                      // Do it at (Yapılma Saati)
                      Text(
                        'Yapılma Saati:',
                        style: context.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTimeOfDaySelector(),
                      const SizedBox(height: 24),
                      
                      // Son Tarih
                      Row(
                        children: [
                          Text(
                            'Son Tarih',
                            style: context.textStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _hasEndDate,
                            onChanged: (value) {
                              setState(() {
                                _hasEndDate = value;
                                if (!value) {
                                  _endDate = null;
                                  _endDays = null;
                                  _endDaysController.clear();
                                }
                              });
                            },
                            activeColor: themeProvider.primaryColor,
                          ),
                        ],
                      ),
                      if (_hasEndDate) ...[
                        const SizedBox(height: 12),
                        _buildEndDateSelector(),
                      ],
                      const SizedBox(height: 24),
                      
                      // Hatırlatıcı
                      Row(
                        children: [
                          Text(
                            'Hatırlatıcı Ayarla',
                            style: context.textStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _hasReminder,
                            onChanged: (value) {
                              setState(() {
                                _hasReminder = value;
                                if (value && _selectedReminderTime == null) {
                                  _selectReminderTime();
                                }
                              });
                            },
                            activeColor: themeProvider.primaryColor,
                          ),
                        ],
                      ),
                      if (_hasReminder) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _selectReminderTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedReminderTime != null
                                      ? '${_selectedReminderTime!.hour.toString().padLeft(2, '0')}:${_selectedReminderTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Saat seç',
                                  style: context.defaultTextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                      
                      // Kaydet Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveHabit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                              widget.habitToEdit != null ? 'Güncelle' : 'Kaydet',
                              style: context.whiteTextStyle(
                                fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
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

  Widget _buildColorPicker() {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.orange,
      Colors.deepOrange,
    ];
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = _selectedColor.value == color.value;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.transparent,
                  width: 3,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildOneTimeTaskContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarih Seçimi
        Text(
          'Tarih',
          style: context.textStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _selectOneTimeDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Text(
                  _oneTimeDate != null
                      ? DateFormat('d MMMM yyyy', 'tr_TR').format(_oneTimeDate!)
                      : 'Tarih seç',
                  style: context.defaultTextStyle(fontSize: 14),
                ),
                const Spacer(),
                Icon(Icons.edit, color: Colors.grey[600], size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRecurringTaskContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tekrar Sekmeleri: Günlük, Aylık
        Text(
          'Tekrar',
          style: context.textStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _recurrenceTabController,
            indicator: BoxDecoration(
              color: Provider.of<ThemeProvider>(context, listen: false).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black87,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Günlük'),
              Tab(text: 'Aylık'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Sekme içeriği
        SizedBox(
          height: 420,
          child: TabBarView(
            controller: _recurrenceTabController,
            children: [
              _buildDailyContent(),
              _buildMonthlyContent(),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDailyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _allDaysSelected,
              onChanged: (value) {
                setState(() {
                  _allDaysSelected = value ?? false;
                  if (_allDaysSelected) {
                    _selectedDailyDays = {1, 2, 3, 4, 5, 6, 7};
                  } else {
                    _selectedDailyDays.clear();
                  }
                });
              },
              activeColor: Provider.of<ThemeProvider>(context, listen: false).primaryColor,
            ),
            Text(
              'Tüm günler',
              style: context.defaultTextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Bu günlerde:',
          style: context.defaultTextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final day = index + 1;
            final isSelected = _selectedDailyDays.contains(day);
            final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedDailyDays.remove(day);
                    _allDaysSelected = false;
                  } else {
                    _selectedDailyDays.add(day);
                    if (_selectedDailyDays.length == 7) {
                      _allDaysSelected = true;
                    }
                  }
                });
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? themeProvider.primaryColor : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getDayLabel(day),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMonthlyContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Her ayın ${_selectedMonthlyDays.isEmpty ? '...' : _selectedMonthlyDays.map((d) => '$d').join(', ')}. günü',
            style: context.defaultTextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TableCalendar(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2030, 12, 31),
          focusedDay: _focusedMonth,
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          selectedDayPredicate: (day) => _selectedMonthlyDays.contains(day.day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _focusedMonth = focusedDay;
              if (_selectedMonthlyDays.contains(selectedDay.day)) {
                _selectedMonthlyDays.remove(selectedDay.day);
              } else {
                _selectedMonthlyDays.add(selectedDay.day);
              }
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedMonth = focusedDay;
            });
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Provider.of<ThemeProvider>(context, listen: false).primaryColor,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Provider.of<ThemeProvider>(context, listen: false).primaryColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildTimeOfDaySelector() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final options = ['Sabah', 'Öğleden Sonra', 'Akşam'];
    
    return Row(
      children: List.generate(3, (index) {
        final isSelected = _selectedTimeOfDay == index;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedTimeOfDay = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? themeProvider.primaryColor : Colors.white,
                border: Border.all(
                  color: isSelected ? themeProvider.primaryColor : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  options[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEndDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarih / Gün seçimi
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _endDateType = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _endDateType
                        ? Provider.of<ThemeProvider>(context, listen: false).primaryColor
                        : Colors.white,
                    border: Border.all(
                      color: _endDateType
                          ? Provider.of<ThemeProvider>(context, listen: false).primaryColor
                          : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Tarih',
                      style: TextStyle(
                        color: _endDateType ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _endDateType = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_endDateType
                        ? Provider.of<ThemeProvider>(context, listen: false).primaryColor
                        : Colors.white,
                    border: Border.all(
                      color: !_endDateType
                          ? Provider.of<ThemeProvider>(context, listen: false).primaryColor
                          : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Gün',
                      style: TextStyle(
                        color: !_endDateType ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_endDateType) ...[
          GestureDetector(
            onTap: _selectEndDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _endDate != null
                        ? DateFormat('d MMMM yyyy', 'tr_TR').format(_endDate!)
                        : 'Tarih seç',
                    style: context.defaultTextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  Icon(Icons.edit, color: Colors.grey[600], size: 20),
                ],
              ),
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _endDaysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Gün sayısı',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.refresh, color: Colors.grey[600], size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
                      onPressed: () {},
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _endDays = int.tryParse(value);
                    });
                  },
                ),
              ),
            ],
          ),
          if (_endDays != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_endDays} gün sonra',
              style: context.defaultTextStyle(fontSize: 14),
            ),
          ],
        ],
      ],
    );
  }
}
