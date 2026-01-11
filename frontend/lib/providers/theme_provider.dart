import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeColor {
  final String name;
  final Color color;
  final Color lightColor;

  const ThemeColor({
    required this.name,
    required this.color,
    required this.lightColor,
  });
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeColorKey = 'theme_color_index';
  static const String _fontSizeKey = 'font_size_index';

  static const List<String> availableFontSizes = ['Küçük', 'Normal', 'Büyük'];
  static const List<double> fontSizeMultipliers = [0.9, 1.0, 1.15];

  static const List<ThemeColor> availableColors = [
    ThemeColor(
      name: 'Mavi',
      color: Color(0xFF499BCF),
      lightColor: Color(0xFF8EC5FC),
    ),
    ThemeColor(
      name: 'Mor',
      color: Color(0xFF9C27B0),
      lightColor: Color(0xFFCE93D8),
    ),
    ThemeColor(
      name: 'Yeşil',
      color: Color(0xFF4CAF50),
      lightColor: Color(0xFFA5D6A7),
    ),
    ThemeColor(
      name: 'Turuncu',
      color: Color(0xFFFF9800),
      lightColor: Color(0xFFFFCC80),
    ),
    ThemeColor(
      name: 'Pembe',
      color: Color(0xFFE91E63),
      lightColor: Color(0xFFF48FB1),
    ),
  ];

  int _selectedColorIndex = 0;
  int _selectedFontSizeIndex = 1; // Normal varsayılan

  ThemeProvider() {
    _loadThemeColor();
    _loadFontSize();
  }

  int get selectedColorIndex => _selectedColorIndex;
  int get selectedFontSizeIndex => _selectedFontSizeIndex;
  double get fontSizeMultiplier => fontSizeMultipliers[_selectedFontSizeIndex];
  String get fontSizeLabel => availableFontSizes[_selectedFontSizeIndex];
  
  ThemeColor get selectedTheme => availableColors[_selectedColorIndex];
  Color get primaryColor => selectedTheme.color;
  Color get lightColor => selectedTheme.lightColor;

  Future<void> _loadThemeColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorIndex = prefs.getInt(_themeColorKey);
      if (colorIndex != null && colorIndex >= 0 && colorIndex < availableColors.length) {
        _selectedColorIndex = colorIndex;
        notifyListeners();
      }
    } catch (e) {
      // Hata durumunda varsayılan rengi kullan
    }
  }

  Future<void> _loadFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fontSizeIndex = prefs.getInt(_fontSizeKey);
      if (fontSizeIndex != null && fontSizeIndex >= 0 && fontSizeIndex < availableFontSizes.length) {
        _selectedFontSizeIndex = fontSizeIndex;
        notifyListeners();
      }
    } catch (e) {
      // Hata durumunda varsayılan boyutu kullan
    }
  }

  Future<void> setPrimaryColorIndex(int index) async {
    if (index >= 0 && index < availableColors.length) {
      _selectedColorIndex = index;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_themeColorKey, index);
      } catch (e) {
        // Hata durumunda devam et
      }
    }
  }

  Future<void> setFontSizeIndex(int index) async {
    if (index >= 0 && index < availableFontSizes.length) {
      _selectedFontSizeIndex = index;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_fontSizeKey, index);
      } catch (e) {
        // Hata durumunda devam et
      }
    }
  }
}

