import 'package:flutter/material.dart';

const themeColor = Color(0xFFDBF500);

// Dark theme
final darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xff232323),
  cardColor: const Color(0xff2f2f2f),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFDBF500),
    surface: Color(0xff232323),
    onSurface: Colors.white,
    secondary: Color(0xff2f2f2f),
  ),
);

// Light theme
final lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xffF5F5F5),
  cardColor: const Color(0xffFFFFFF),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFDBF500),
    surface: Color(0xffF5F5F5),
    onSurface: Colors.black,
    secondary: Color(0xffFFFFFF),
  ),
);

// Global notifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

// Helper extensions
extension ThemeExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bgColor => Theme.of(this).scaffoldBackgroundColor;
  
  Color get cardBgColor => isDark 
      ? const Color(0xff2f2f2f) 
      : const Color(0xffFFFFFF);
  
  Color get textColor => isDark 
      ? Colors.white 
      : const Color(0xff1A1A1A);
  
  Color get subtextColor => isDark 
      ? Colors.white70 
      : const Color(0xff555555);
  
  Color get iconBgColor => isDark 
      ? const Color(0xff232323) 
      : const Color(0xffF5F5F5);

  // Nav bar specific
  Color get navBgColor => isDark 
      ? const Color(0xff2f2f2f) 
      : const Color(0xff1A1A1A); // dark bar in light mode

  Color get navUnselectedColor => isDark 
      ? Colors.grey 
      : Colors.white60;

  Color get navSelectedColor => themeColor;
}