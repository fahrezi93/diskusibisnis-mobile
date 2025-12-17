import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
  }
}
