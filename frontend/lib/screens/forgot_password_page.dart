import 'package:flutter/material.dart';
import 'package:restaurant_app/services/api_service.dart';
import 'package:restaurant_app/utils/app_localizations.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _apiService = ApiService();
  final _pageController = PageController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _pass1Controller = TextEditingController();
  final _pass2Controller = TextEditingController();

  // Adım 1: Kod Gönder
  void _sendCode() async {
    try {
      await _apiService.forgotPassword(_emailController.text);
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // Adım 2: Kodu Doğrula
  void _verifyCode() async {
    try {
      await _apiService.verifyCode(_emailController.text, _codeController.text);
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.get('msg_code_wrong'))));
    }
  }

  // Adım 3: Şifre Değiştir
  void _resetPassword() async {
    if (_pass1Controller.text != _pass2Controller.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('msg_passwords_not_match'))),
      );
      return;
    }
    try {
      await _apiService.resetPassword(
        _emailController.text,
        _pass1Controller.text,
      );
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(
        SnackBar(content: Text(AppStrings.get('msg_password_updated'))),
      );
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Giriş ekranına dön
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.get('msg_error'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('title_forgot_password'))),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          // Sayfa 1: Mail
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(AppStrings.get('label_enter_email')),
                SizedBox(height: 16),
                TextField(controller: _emailController),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _sendCode,
                  child: Text(AppStrings.get('btn_send_code')),
                ),
              ],
            ),
          ),
          // Sayfa 2: Kod
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(AppStrings.get('label_enter_code_short')),
                TextField(controller: _codeController),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _verifyCode,
                  child: Text(AppStrings.get('btn_verify')),
                ),
              ],
            ),
          ),
          // Sayfa 3: Yeni Şifre
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(AppStrings.get('label_new_password')),
                TextField(controller: _pass1Controller, obscureText: true),
                SizedBox(height: 16),
                Text(
                  AppStrings.get('label_confirm_password'),
                ), // "Tekrar Girin:"
                TextField(controller: _pass2Controller, obscureText: true),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _resetPassword,
                  child: Text(AppStrings.get('btn_update_password')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
