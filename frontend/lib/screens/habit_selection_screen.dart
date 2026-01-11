import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_utils.dart';
import 'habit_add_screen.dart';

class PopularHabit {
  final String title;
  final IconData icon;
  final Color color;

  const PopularHabit({
    required this.title,
    required this.icon,
    required this.color,
  });
}

class HabitSelectionScreen extends StatefulWidget {
  const HabitSelectionScreen({super.key});

  @override
  State<HabitSelectionScreen> createState() => _HabitSelectionScreenState();
}

class _HabitSelectionScreenState extends State<HabitSelectionScreen> {
  final List<PopularHabit> _popularHabits = const [
    PopularHabit(
      title: 'Dişini fırçala',
      icon: Icons.cleaning_services,
      color: Color(0xFF2196F3),
    ),
    PopularHabit(
      title: 'Erken Uyan',
      icon: Icons.alarm,
      color: Color(0xFFF44336),
    ),
    PopularHabit(
      title: 'Spor Yap',
      icon: Icons.fitness_center,
      color: Color(0xFFFF9800),
    ),
    PopularHabit(
      title: 'Yürüyüş Yap',
      icon: Icons.directions_walk,
      color: Color(0xFF9C27B0),
    ),
    PopularHabit(
      title: 'Bisiklet Sür',
      icon: Icons.directions_bike,
      color: Color(0xFF4CAF50),
    ),
    PopularHabit(
      title: 'Meditasyon Yap',
      icon: Icons.self_improvement,
      color: Color(0xFF00BCD4),
    ),
    PopularHabit(
      title: 'Müzik Dinle',
      icon: Icons.headphones,
      color: Color(0xFF9E9E9E),
    ),
    PopularHabit(
      title: 'Cilt Bakımı Yap',
      icon: Icons.spa,
      color: Color(0xFFE91E63),
    ),
  ];

  Future<void> _openHabitAddWithPreset(PopularHabit habit) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitAddScreen(
          presetTitle: habit.title,
          presetColor: habit.color,
        ),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true); // Geri dön ve yeni habit eklendiğini bildir
    }
  }

  Future<void> _navigateToManualAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HabitAddScreen()),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true); // Geri dön ve yeni habit eklendiğini bildir
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Provider.of<ThemeProvider>(context, listen: false).primaryColor),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Popüler Alışkanlıklar Başlık
            const Text(
              'Popüler Alışkanlıklar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF499BCF),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Bir alışkanlık seçin ve özelleştirin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            // Popüler Alışkanlıklar Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
              ),
              itemCount: _popularHabits.length,
              itemBuilder: (context, index) {
                final habit = _popularHabits[index];

                return GestureDetector(
                  onTap: () => _openHabitAddWithPreset(habit),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: habit.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              habit.icon,
                              color: habit.color,
                              size: 35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) => Text(
                              habit.title,
                              style: context.defaultTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            // Divider
            const Divider(thickness: 1),
            const SizedBox(height: 30),
            // Manuel Oluştur Butonu
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => Text(
                'Manuel Oluştur',
                style: context.textStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => Text(
                'Kendi alışkanlığını özelleştirerek oluştur',
                style: context.defaultTextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 70,
              child: OutlinedButton.icon(
                onPressed: _navigateToManualAdd,
                icon: const Icon(Icons.add_circle_outline, size: 28),
                label: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) => Text(
                    'Yeni Alışkanlık Oluştur',
                    style: context.textStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Provider.of<ThemeProvider>(context, listen: false).primaryColor,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

