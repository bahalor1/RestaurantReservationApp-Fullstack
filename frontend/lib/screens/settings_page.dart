// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:restaurant_app/screens/login_page.dart';
import 'package:restaurant_app/services/api_service.dart';
import 'package:restaurant_app/screens/change_password_page.dart';
import 'package:restaurant_app/utils/settings_manager.dart';
import 'package:restaurant_app/utils/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = SettingsManager.themeNotifier.value == ThemeMode.dark;
  String _selectedLanguage = SettingsManager.localeNotifier.value.languageCode;

  // Çıkış Yapma Fonksiyonu
  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('settings_logout')),
        content: Text(AppStrings.get('dialog_logout_content')),
        actions: [
          // İptal Butonu
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get('btn_cancel')),
          ),

          TextButton(
            onPressed: () async {
              await ApiService().clearSession();

              CURRENT_USER_ID = 0;
              CURRENT_USER_NAME = "";

              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppStrings.get('msg_logout_success'))),
                );
              }
            },
            child: Text(
              AppStrings.get('settings_logout'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('settings_delete_account')), // "Hesabı Sil"
        content: Text(
          AppStrings.get('dialog_delete_account_content'),
        ), // "Geri alınamaz..."
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get('btn_cancel')),
          ),

          TextButton(
            onPressed: () async {
              try {
                await ApiService().deleteAccount(CURRENT_USER_ID);

                CURRENT_USER_ID = 0;
                CURRENT_USER_NAME = "";

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.get('msg_delete_success')),
                      backgroundColor: Colors.grey,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "${AppStrings.get('msg_error_prefix')} ${e.toString().replaceAll('Exception: ', '')}",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              AppStrings.get('btn_delete'), // "Sil"
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.get('tab_settings'),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).cardColor,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            AppStrings.get('general_header'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                // ignore: deprecated_member_use
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.blue),
                  title: Text(
                    AppStrings.get('settings_language'),
                    style: TextStyle(fontSize: 15),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedLanguage == 'tr' ? "Türkçe" : "English",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),

                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(AppStrings.get('dialog_select_language')),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text("🇹🇷 Türkçe"),
                              onTap: () {
                                // Dili değiştir
                                SettingsManager.changeLanguage('tr');

                                // Kendi içindeki değişkeni güncelle (UI yenilensin diye)
                                setState(() {
                                  _selectedLanguage = 'tr';
                                });

                                // Pencereyi kapat
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: const Text("🇺🇸 English"),
                              onTap: () {
                                SettingsManager.changeLanguage('en');

                                setState(() {
                                  _selectedLanguage = 'en';
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                Divider(height: 2, color: Colors.grey),

                ListTile(
                  leading: Icon(
                    _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.purple,
                  ),
                  title: Text(AppStrings.get('settings_dark_mode')),
                  trailing: Switch(
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        _isDarkMode = value;
                      });

                      SettingsManager.toggleTheme(value);
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // --- BÖLÜM 2: HESAP İŞLEMLERİ ---
          Text(
            AppStrings.get('account_header'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                // ignore: deprecated_member_use
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
              ],
            ),
            child: Column(
              children: [
                // Çıkış Yap
                ListTile(
                  onTap: _logout,
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.logout, color: Colors.orange),
                  ),
                  title: Text(AppStrings.get('settings_logout')),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                ),
                Divider(height: 5, color: Colors.grey),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigoAccent[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.password, color: Colors.indigoAccent),
                  ),
                  title: Text(AppStrings.get('settings_change_password')),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // Yeni sayfaya git
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordPage(),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.grey),
                // Hesabı Sil
                ListTile(
                  onTap: _deleteAccount,
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_forever, color: Colors.red),
                  ),
                  title: Text(
                    AppStrings.get('settings_delete_account'),
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // --- VERSİYON BİLGİSİ ---
          Center(
            child: Text(
              "${AppStrings.get('version_text')} 1.0.0",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
