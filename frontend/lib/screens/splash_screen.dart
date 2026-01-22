import 'package:flutter/material.dart';
import 'package:restaurant_app/screens/login_page.dart';
import 'package:restaurant_app/screens/main_screen.dart';
import 'package:restaurant_app/services/api_service.dart';
import 'package:restaurant_app/utils/settings_manager.dart';
import 'package:restaurant_app/utils/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 1. Ayarları Yükle ve Animasyon İçin Bekle
    // (En az 2 saniye ekranda kalsın ki logo görünsün, kullanıcı anlasın)
    await Future.wait([
      SettingsManager.init(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    // Dil ayarını AppStrings'e bildir (Yükleme bittikten sonra)
    AppStrings.language = SettingsManager.localeNotifier.value.languageCode;

    // 2. Oturum Kontrolü Yap
    final apiService = ApiService();
    bool isLoggedIn = await apiService.checkSession();

    // 3. Yönlendirme (Login olmuşsa Ana Sayfa, olmamışsa Giriş)
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              isLoggedIn ? const MainScreen() : const LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arkaplan rengini temadan al (Light: Beyaz, Dark: Siyah)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Animasyonu (Esneyerek büyüme efekti)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 1),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 100,
                    color: Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Uygulama İsmi
            Text(
              "Restorante",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 40),

            // Yükleniyor Çubuğu
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
