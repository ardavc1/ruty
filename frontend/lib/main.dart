import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/character_selection_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/habit_add_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Türkçe locale data'yı initialize et
  await initializeDateFormatting('tr_TR', null);
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final themeColor = themeProvider.selectedTheme;
          return MaterialApp(
            title: 'Ruty',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeColor.color,
                brightness: Brightness.light,
              ),
              primaryColor: themeColor.color,
              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
              useMaterial3: true,
              textTheme: TextTheme(
                displayLarge: TextStyle(fontSize: 32 * themeProvider.fontSizeMultiplier),
                displayMedium: TextStyle(fontSize: 28 * themeProvider.fontSizeMultiplier),
                displaySmall: TextStyle(fontSize: 24 * themeProvider.fontSizeMultiplier),
                headlineLarge: TextStyle(fontSize: 22 * themeProvider.fontSizeMultiplier),
                headlineMedium: TextStyle(fontSize: 20 * themeProvider.fontSizeMultiplier),
                headlineSmall: TextStyle(fontSize: 18 * themeProvider.fontSizeMultiplier),
                titleLarge: TextStyle(fontSize: 16 * themeProvider.fontSizeMultiplier),
                titleMedium: TextStyle(fontSize: 14 * themeProvider.fontSizeMultiplier),
                titleSmall: TextStyle(fontSize: 12 * themeProvider.fontSizeMultiplier),
                bodyLarge: TextStyle(fontSize: 16 * themeProvider.fontSizeMultiplier),
                bodyMedium: TextStyle(fontSize: 14 * themeProvider.fontSizeMultiplier),
                bodySmall: TextStyle(fontSize: 12 * themeProvider.fontSizeMultiplier),
                labelLarge: TextStyle(fontSize: 14 * themeProvider.fontSizeMultiplier),
                labelMedium: TextStyle(fontSize: 12 * themeProvider.fontSizeMultiplier),
                labelSmall: TextStyle(fontSize: 10 * themeProvider.fontSizeMultiplier),
              ).apply(
                bodyColor: Colors.black87,
                displayColor: Colors.black87,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: themeColor.color,
                elevation: 0,
                titleTextStyle: TextStyle(
                  color: themeColor.color,
                  fontSize: 20 * themeProvider.fontSizeMultiplier,
                  fontWeight: FontWeight.bold,
                ),
                iconTheme: IconThemeData(color: themeColor.color),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: themeColor.color,
                  side: BorderSide(color: themeColor.color, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: themeColor.color,
                foregroundColor: Colors.white,
              ),
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(),
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/character-selection': (context) => const CharacterSelectionScreen(),
              '/home': (context) => const HomeScreen(),
              '/habit-add': (context) => const HabitAddScreen(),
            },
          );
        },
      ),
    );
  }
}