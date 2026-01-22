import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:restaurant_app/screens/splash_screen.dart';
import 'package:restaurant_app/utils/app_localizations.dart';
import 'package:restaurant_app/utils/settings_manager.dart';

// ignore: non_constant_identifier_names
int CURRENT_USER_ID = 0;
// ignore: non_constant_identifier_names
String CURRENT_USER_NAME = "";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: SettingsManager.localeNotifier,
      builder: (context, locale, child) {
        AppStrings.language = locale.languageCode;

        return ValueListenableBuilder<ThemeMode>(
          valueListenable: SettingsManager.themeNotifier,
          builder: (context, themeMode, child) {
            return MaterialApp(
              title: 'Restoran Rezervasyon',
              debugShowCheckedModeBanner: false,

              locale: locale,
              themeMode: themeMode,

              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                primaryColor: Colors.blue,
                scaffoldBackgroundColor: Colors.white,
                cardTheme: CardThemeData(color: Colors.grey[200], elevation: 2),
                iconTheme: const IconThemeData(color: Colors.blue),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                navigationBarTheme: NavigationBarThemeData(
                  indicatorColor: Colors.grey[200],
                  iconTheme: WidgetStateProperty.all(
                    const IconThemeData(color: Colors.blue),
                  ),
                  labelTextStyle: WidgetStateProperty.all(
                    const TextStyle(color: Colors.black, fontSize: 13),
                  ),
                ),
                inputDecorationTheme: InputDecorationThemeData(
                  prefixIconColor: Colors.black,
                  fillColor: Colors.grey[200],
                ),
                chipTheme: ChipThemeData(
                  backgroundColor: Colors.grey[100],
                  labelStyle: const TextStyle(color: Colors.black),
                  selectedColor: Colors.blue,
                  secondaryLabelStyle: const TextStyle(color: Colors.white),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                  showCheckmark: false,
                ),
                colorScheme: const ColorScheme.light(
                  primary: Colors.blue,
                  surface: Colors.white,
                  onSurface: Colors.black87,
                ),
              ),

              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                primaryColor: Colors.indigo.shade900,
                scaffoldBackgroundColor: Colors.black,
                cardTheme: CardThemeData(color: Colors.grey[900], elevation: 2),
                iconTheme: const IconThemeData(color: Color(0xFF3949AB)),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                navigationBarTheme: NavigationBarThemeData(
                  indicatorColor: Color(0xFF1249AB),
                  iconTheme: WidgetStateProperty.all(
                    const IconThemeData(color: Colors.blue),
                  ),
                  labelTextStyle: WidgetStateProperty.all(
                    const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                chipTheme: ChipThemeData(
                  backgroundColor: Colors.grey[900],
                  labelStyle: const TextStyle(color: Colors.white),
                  selectedColor: const Color(0xFF3949AB),
                  secondaryLabelStyle: const TextStyle(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                ),
                inputDecorationTheme: InputDecorationThemeData(
                  prefixIconColor: Colors.grey,
                  fillColor: Colors.grey[800],
                ),
                colorScheme: ColorScheme.dark(
                  primary: Colors.indigo.shade900,
                  surface: Colors.black,
                  onSurface: Colors.white70,
                ),
              ),

              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en', 'US'), Locale('tr', 'TR')],

              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
