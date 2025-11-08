import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'habit_list.dart';
import 'pet_selection_screen.dart';
import 'habit_add_page.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF499BCF); // #499bcf
    return MaterialApp(
      title: 'Ruty',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      initialRoute: '/auth',
      routes: {
        '/auth': (_) => const RegisterScreen(),
        '/animal': (_) => const PetSelectionScreen(),
        '/habit-add': (_) => const HabitAddPage(),
        '/habit-list': (_) => const HabitListScreen(),
      },
    );
  }
}
