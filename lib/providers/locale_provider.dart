import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global language notifier — works exactly like themeNotifier in main.dart
/// Any page that listens to this will rebuild instantly when language changes.
final ValueNotifier<String> localeNotifier = ValueNotifier<String>('en');

/// Call this once in main() to load the saved language from SharedPreferences
Future<void> initLocale() async {
  final prefs = await SharedPreferences.getInstance();
  localeNotifier.value = prefs.getString('language') ?? 'en';
}

/// Call this when user picks a new language (in Settings)
Future<void> saveLocale(String code) async {
  localeNotifier.value = code;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language', code);
}
