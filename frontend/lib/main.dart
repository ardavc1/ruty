import 'package:flutter/material.dart';
import 'package:frontend/login_screen.dart';
import 'register_screen.dart';
import 'habit_list.dart';
import 'pet_selection_screen.dart';
import 'habit_add_page.dart';

void main() {
  runApp(const MainApp());
}

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
      initialRoute: '/register',
      routes: {
        '/register': (_) => const RegisterScreen(),
        '/login': (_) => const LoginScreen(),
        '/animal': (_) => const PetSelectionScreen(),
        '/habit-add': (_) => const HabitAddPage(),
        '/habit-list': (_) => const HabitListScreen(),
      },
    );
  }
}
