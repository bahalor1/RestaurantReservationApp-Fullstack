import 'dart:async';
import 'package:flutter/material.dart';
import 'package:restaurant_app/services/api_service.dart';
import 'package:restaurant_app/screens/login_page.dart';
import 'package:restaurant_app/utils/app_localizations.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final ApiService _apiService = ApiService();

  // Hangi Aşamadayız?
  // 0: Giriş Doğrulama (Eski Şifre)
  // 1: Mail Kod Doğrulama (OTP)
  // 2: Yeni Şifre Belirleme
  int _currentStep = 0;
  bool _isLoading = false;

  // Sayaç için
  Timer? _timer;
  int _start = 30;
  bool _isTimerActive = false;

  // Controller'lar
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- SAYAÇ BAŞLAT ---
  void _startTimer() {
    setState(() {
      _isTimerActive = true;
      _start = 30;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _isTimerActive = false;
          timer.cancel();
        });
      } else {
        setState(() => _start--);
      }
    });
  }

  // ADIM 1: KİMLİK DOĞRULA VE KOD GÖNDER
  void _verifyAndSendCode() async {
    String email = _emailController.text.trim();
    String oldPass = _oldPasswordController.text.trim();

    if (email.isEmpty || oldPass.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.get('msg_fill_all'))));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Önce giriş bilgilerini kontrol et (Eski şifre doğru mu?)
      bool isValidUser = await _apiService.login(email, oldPass);

      if (isValidUser) {
        // 2. Bilgiler doğruysa, mail adresine kod gönder
        await _apiService.sendResetCode(email);

        setState(() {
          _currentStep = 1; // Kod ekranına geç
          _isLoading = false;
        });
        _startTimer();

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.get('msg_code_sent'))),
        );
      } else {
        throw Exception(AppStrings.get('msg_login_error'));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Giriş bilgileri hatalı, lütfen kontrol edin."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ADIM 2: KODU DOĞRULA
  void _verifyCode() async {
    String code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    // Backend'deki kod doğrulama servisini kullanıyoruz
    bool isCodeValid = await _apiService.verifyResetCode(
      _emailController.text.trim(),
      code,
    );

    if (isCodeValid) {
      setState(() {
        _currentStep = 2; // Yeni şifre ekranına geç
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('msg_code_wrong')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ADIM 3: YENİ ŞİFREYİ KAYDET
  void _saveNewPassword() async {
    String newPass = _newPasswordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) return;

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('msg_passwords_not_match')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Şifreyi güncelle
      await _apiService.updatePassword(CURRENT_USER_ID, newPass);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.get('msg_password_changed_success'),
            ), // "Başarıyla değiştirildi"
            backgroundColor: Colors.green,
          ),
        );

        // Çıkış yap ve Login'e at
        await _apiService.clearSession();
        CURRENT_USER_ID = 0;

        Navigator.pushAndRemoveUntil(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${AppStrings.get('msg_error_prefix')} $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(AppStrings.get('title_change_password'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- AŞAMA 1: GİRİŞ DOĞRULAMA ---
            if (_currentStep == 0) ...[
              const SizedBox(height: 100),
              const Icon(Icons.shield, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                AppStrings.get('msg_verify_identity'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: AppStrings.get('label_email'),
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppStrings.get('label_current_password'),
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.blue[600]),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                  onPressed: _isLoading ? null : _verifyAndSendCode,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(AppStrings.get('btn_verify_and_send')),
                ),
              ),
            ],

            // --- AŞAMA 2: MAİL KODU ---
            if (_currentStep == 1) ...[
              const SizedBox(height: 60),
              Icon(Icons.mark_email_read, size: 80, color: Colors.blue[600]),
              const SizedBox(height: 20),
              Text(
                "${_emailController.text} ${AppStrings.get('msg_enter_code_sent_to')}",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 5),
                decoration: InputDecoration(
                  hintText: AppStrings.get('hint_code_placeholder'),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.blue[600]),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                  onPressed: _isLoading ? null : _verifyCode,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(AppStrings.get('btn_confirm_code')),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                child: TextButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      Colors.grey.shade100,
                    ),
                    foregroundColor: WidgetStateProperty.all(Colors.black),
                  ),
                  onPressed: _isTimerActive
                      ? null
                      : () async {
                          await _apiService.sendResetCode(
                            _emailController.text.trim(),
                          );
                          _startTimer();
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppStrings.get('msg_code_resent')),
                            ),
                          );
                        },
                  child: Text(
                    _isTimerActive
                        ? "${AppStrings.get('msg_resend_wait')} $_start sn" // "Bekleyin..."
                        : AppStrings.get('btn_resend_code'), // "Tekrar Gönder"
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],

            // --- AŞAMA 3: YENİ ŞİFRE ---
            if (_currentStep == 2) ...[
              const Icon(Icons.lock_reset, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              Text(
                AppStrings.get('msg_identity_verified'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppStrings.get('label_new_password'),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppStrings.get('label_confirm_password'),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.check_circle_outline),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveNewPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(AppStrings.get('btn_change_password')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
