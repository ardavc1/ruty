import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

extension ThemeExtension on BuildContext {
  ThemeProvider get themeProvider => Provider.of<ThemeProvider>(this, listen: false);
  
  Color get primaryColor => themeProvider.primaryColor;
  Color get lightColor => themeProvider.lightColor;
  double get fontSizeMultiplier => themeProvider.fontSizeMultiplier;
  
  // Helper method for fontSize
  double scaledFontSize(double baseSize) => baseSize * fontSizeMultiplier;
  
  // Helper method for TextStyle with theme
  TextStyle textStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize != null ? scaledFontSize(fontSize) : null,
      fontWeight: fontWeight,
      color: color ?? primaryColor,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
  
  // Helper for white text on colored background
  TextStyle whiteTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize != null ? scaledFontSize(fontSize) : null,
      fontWeight: fontWeight,
      color: Colors.white,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
  
  // Helper for default text color (black/grey)
  TextStyle defaultTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize != null ? scaledFontSize(fontSize) : null,
      fontWeight: fontWeight,
      color: color ?? Colors.black87,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

