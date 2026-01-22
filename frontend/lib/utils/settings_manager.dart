import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';


class SettingsManager {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
    ThemeMode.light,
  );
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(
    const Locale('tr'),
  );

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark =
        prefs.getBool('isDark') ??
        false; // Kayıt yoksa varsayılan false (Aydınlık)
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

    // 2. Dili Yükle
    final langCode =
        prefs.getString('language') ?? 'tr'; // Kayıt yoksa varsayılan 'tr'
    localeNotifier.value = Locale(langCode);
  }
  

  // Temayı Değiştir (Koyu / Açık)
  static void toggleTheme(bool isDark) async {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark); // Hafızaya kaydet
  }

  // Dili Değiştir (tr / en)
  static Future<void> changeLanguage(String languageCode) async {
    // 1. Uygulamaya yeni dili bildir
    localeNotifier.value = Locale(languageCode);
    
    // 2. Sözlük dosyasındaki aktif dili güncelle
    AppStrings.language = languageCode;

    // 3. Tercihi telefona kaydet (Kalıcı olması için)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
  }
  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Kayıtlı dili çek, yoksa 'tr' yap
    String savedLang = prefs.getString('language') ?? 'tr';
    
    localeNotifier.value = Locale(savedLang);
    AppStrings.language = savedLang; // Sözlüğe de bildir
  }
}
