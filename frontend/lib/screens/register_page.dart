import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restaurant_app/services/api_service.dart';
import 'package:restaurant_app/screens/main_screen.dart';
import 'package:restaurant_app/utils/app_localizations.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _apiService = ApiService();
  final _pageController = PageController();

  // Metin Kontrolcüleri
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;

  // TARİH DOĞRULAMA FONKSİYONU
  String? _validateDate(String dateInput) {
    if (dateInput.length != 10) {
      return AppStrings.get('msg_invalid_date_format');
    }

    try {
      int year = int.parse(dateInput.substring(0, 4));
      int month = int.parse(dateInput.substring(5, 7));
      int day = int.parse(dateInput.substring(8, 10));

      if (month < 1 || month > 12) return AppStrings.get('msg_invalid_month');

      DateTime now = DateTime.now();
      if (year < 1930 || year > now.year) {
        return AppStrings.get('msg_invalid_year');
      }

      DateTime enteredDate = DateTime(year, month, day);

      if (enteredDate.isAfter(now)) {
        return AppStrings.get('msg_future_date');
      }

      if (enteredDate.month != month || enteredDate.day != day) {
        return AppStrings.get('msg_invalid_day');
      }

      return null;
    } catch (e) {
      return AppStrings.get('msg_date_error');
    }
  }

  // 1. ADIM: KAYIT OL (BİLGİLERİ GÖNDER)
  void _registerInit() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('msg_fill_all')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? dateError = _validateDate(_dobController.text);
    if (dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dateError), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _dobController.text.trim(),
      );

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${AppStrings.get('msg_error_prefix')} ${e.toString().replaceAll("Exception: ", "")}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //  2. ADIM: KODU DOĞRULA
  void _verifyCode() async {
    if (_codeController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.verifyCode(
        _emailController.text.trim(),
        _codeController.text.trim(),
      );

      try {
        await _apiService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      } catch (loginError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${AppStrings.get('msg_login_failed')}: $loginError",
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('msg_code_error')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('title_register'))),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          // SAYFA 1: BİLGİ GİRİŞİ
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: AppStrings.get('label_fullname'),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 16),

                  // ÖZEL TARİH KUTUSU
                  TextField(
                    controller: _dobController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      DateTextFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: AppStrings.get('label_dob'),
                      hintText: AppStrings.get('hint_dob'),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),

                  // -------------------------
                  SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: AppStrings.get('label_email'),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: AppStrings.get('label_password'),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerInit,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              AppStrings.get('btn_next'),
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // SAYFA 2: KOD DOĞRULAMA
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mark_email_unread, size: 80, color: Colors.blue),
                SizedBox(height: 20),
                Text(
                  AppStrings.get('label_enter_code'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "------",
                    counterText: "",
                  ),
                  style: TextStyle(
                    fontSize: 24,
                    letterSpacing: 5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            AppStrings.get('btn_complete'),
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// YARDIMCI FORMATLAYICI SINIFI
class DateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Rakam olmayanları temizle
    String originalText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 2. Maksimum 8 rakam sınırı (YYYYMMDD)
    if (originalText.length > 8) {
      originalText = originalText.substring(0, 8);
    }

    String formattedText = '';

    for (int i = 0; i < originalText.length; i++) {
      // Yıl kısmı (0-3 arası indeksler)
      if (i < 4) {
        formattedText += originalText[i];
      }
      // Ay kısmı (4. indeks) - Tireden sonraki ilk rakam
      else if (i == 4) {
        formattedText += '-'; // Yıl bitti, tire koy
        formattedText += originalText[i];
      }
      // Ayın devamı (5. indeks)
      else if (i == 5) {
        formattedText += originalText[i];
      }
      // Gün kısmı (6. indeks) - Tireden sonraki ilk rakam
      else if (i == 6) {
        formattedText += '-'; // Ay bitti, tire koy
        formattedText += originalText[i];
      }
      // Günün devamı
      else {
        formattedText += originalText[i];
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
