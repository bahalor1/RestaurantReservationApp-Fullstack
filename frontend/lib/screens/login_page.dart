import 'package:flutter/material.dart';
import 'package:restaurant_app/screens/main_screen.dart';
import 'package:restaurant_app/screens/register_page.dart';
import 'package:restaurant_app/screens/forgot_password_page.dart';
import 'package:restaurant_app/services/api_service.dart';
import 'package:restaurant_app/utils/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isObscure = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      bool success = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (success) {
        // --- YENİ EKLENEN KISIM ---
        // Eğer "Beni Hatırla" seçiliyse, verileri telefona kaydet
        if (_rememberMe) {
          await _apiService.saveSession(CURRENT_USER_ID, CURRENT_USER_NAME);
        }
        // ---------------------------

        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.restaurant_menu, size: 80, color: Colors.blue),
              SizedBox(height: 10),
              Text(
                AppStrings.get('title_app_name'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: AppStrings.get('label_email'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: AppStrings.get('label_password'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.lock),
                  // Göz İkonu
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SOL TARAFTA: HESAP OLUŞTUR
                  Padding(
                    padding: const EdgeInsets.only(top: 0, left: 2),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterPage()),
                      ),
                      child: Text(
                        AppStrings.get('btn_create_account'),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  // 2. SAĞ TARAFTA: SÜTUN (Üstte Şifremi Unuttum, Altta Beni Hatırla)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end, // Sağa yasla
                    children: [
                      // Üst: Şifremi Unuttum Linki
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotPasswordPage(),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 2, top: 0),
                          child: Text(
                            AppStrings.get('label_forgot_password'),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              decoration:
                                  TextDecoration.underline, // Altı çizili olsun
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4), // Altta boşluk
                      // Alt: Beni Hatırla Satırı
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                            child: Text(AppStrings.get('label_remember_me')),
                          ),
                          SizedBox(width: 4),
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: Colors.blue,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        AppStrings.get('btn_login'),
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
