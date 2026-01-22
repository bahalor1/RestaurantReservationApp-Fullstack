import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: constant_identifier_names
const String _API_URL = 'http://10.0.2.2:3000';
// ignore: non_constant_identifier_names
int CURRENT_USER_ID = 0;
// ignore: non_constant_identifier_names
String CURRENT_USER_NAME = "";
// ignore: non_constant_identifier_names
String CURRENT_USER_EMAIL = "";
// ignore: non_constant_identifier_names
String? CURRENT_USER_BIRTH_DATE;

class ApiService {
  final Dio _dio = Dio();

  static final Set<int> _localFavorites = {};

  Future<List<dynamic>> getRestaurants({
    String? searchQuery,
    String? category,
  }) async {
    // Önce kayıtlı favorileri yükle
    await _loadFavoritesFromDisk();

    try {
      Map<String, dynamic> queryParams = {};
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }
      if (category != null && category != 'Tümü') {
        queryParams['category'] = category;
      }

      final response = await _dio.get(
        '$_API_URL/restaurants',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;

        // Gelen veriyi favori listemizle karşılaştırıp işaretliyoruz
        for (var item in data) {
          int id = item['restaurant_id']; // veya 'id'
          if (_localFavorites.contains(id)) {
            item['is_favorite'] = true;
          } else {
            item['is_favorite'] = false;
          }
        }
        return data;
      } else {
        throw Exception('Veri alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Hata: $e');
    }
  }

  Future<void> clearHistory(int userId) async {
    try {
      await _dio.delete('$_API_URL/users/$userId/history');
    } catch (e) {
      throw Exception('Geçmiş silinemedi.');
    }
  }

  Future<void> updatePassword(int userId, String newPassword) async {
    try {
      final response = await _dio.put(
        '$_API_URL/users/$userId/password',
        data: {'newPassword': newPassword},
      );

      if (response.statusCode != 200) {
        throw Exception('Şifre değiştirilemedi.');
      }
    } catch (e) {
      throw Exception('Hata: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      // ADRESİN '/auth/login' OLDUĞUNA DİKKAT ET
      final response = await _dio.post(
        '$_API_URL/auth/login',
        data: {
          'email': email, // Backend 'email' bekliyor
          'password': password, // Backend 'password' bekliyor
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        CURRENT_USER_ID = data['id'];
        CURRENT_USER_NAME = data['name'] ?? "Kullanıcı";
        CURRENT_USER_EMAIL = data['email'];
        if (data['birth_date'] != null) {
          String rawDate = data['birth_date'].toString();
          // Sadece ilk 10 karakteri al (YYYY-MM-DD)
          CURRENT_USER_BIRTH_DATE = rawDate.length > 10
              ? rawDate.substring(0, 10)
              : rawDate;
        } else {
          CURRENT_USER_BIRTH_DATE = null;
        }

        // ignore: avoid_print
        print(
          "Giriş Yapan: $CURRENT_USER_NAME, Doğum Tarihi: $CURRENT_USER_BIRTH_DATE",
        );
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Giriş başarısız. Bilgileri kontrol edin.');
    }
  }

  Future<void> saveSession(int userId, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
    await prefs.setString('userName', userName);
  }

  // 2. Oturumu Kontrol Et (Uygulama açılırken çağıracağız)
  // Eğer kayıt varsa true döner ve Global değişkenleri doldurur
  Future<bool> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('userId')) {
      CURRENT_USER_ID = prefs.getInt('userId') ?? 0;
      // İstersen ismi de kaydedip çekebilirsin, şimdilik ID yeterli
      return true; // Oturum var
    }
    return false; // Oturum yok
  }

  // 3. Oturumu Sil (Çıkış yaparken çağıracağız)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Tüm kayıtlı verileri sil
  }

  // 2. Kayıt Ol (Adım 1)
  Future<void> register(
    String name,
    String email,
    String password,
    String dob,
  ) async {
    try {
      // ignore: unused_local_variable
      final response = await _dio.post(
        '$_API_URL/auth/register',
        data: {'name': name, 'email': email, 'password': password, 'dob': dob},
      );
      // ... (hata yakalama kısımları aynı kalabilir)
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 3. Kod Doğrula (Genel)
  Future<void> verifyCode(String email, String code) async {
    try {
      // ADRESİN SONUNA DİKKAT ET: /verify-code OLMALI
      await _dio.post(
        '$_API_URL/auth/verify-code',
        data: {'email': email, 'code': code},
      );
    } catch (e) {
      throw Exception('Kod doğrulanamadı: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final response = await _dio.get('$_API_URL/users/$userId');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Profil bilgileri alınamadı.');
      }
    } catch (e) {
      throw Exception('Hata: $e');
    }
  }

  Future<void> deleteAccount(int userId) async {
    try {
      final response = await _dio.delete('$_API_URL/users/$userId');
      if (response.statusCode != 200) {
        throw Exception('Hesap silinemedi.');
      }
    } catch (e) {
      throw Exception('Hata: $e');
    }
  }

  // 4. Şifremi Unuttum (Kod İste)
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('$_API_URL/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Hata oluştu');
    }
  }

  // 5. Yeni Şifre Belirle
  Future<void> resetPassword(String email, String newPassword) async {
    try {
      await _dio.post(
        '$_API_URL/auth/reset-password',
        data: {'email': email, 'new_password': newPassword},
      );
      // ignore: unused_catch_clause
    } on DioException catch (e) {
      throw Exception('Şifre yenilenemedi.');
    }
  }

  Future<List<dynamic>> getMyReservations(int userId) async {
    try {
      final response = await _dio.get('$_API_URL/users/$userId/reservations');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Rezervasyonlar yüklenemedi.');
      }
    } catch (e) {
      throw Exception('Hata: $e');
    }
  }

  Future<void> cancelBooking(int bookingId) async {
    try {
      final response = await _dio.delete('$_API_URL/bookings/$bookingId');
      if (response.statusCode != 200) {
        throw Exception('İptal edilemedi.');
      }
    } catch (e) {
      throw Exception('Hata: $e');
    }
  }

  Future<List<dynamic>> getAvailability(int restaurantId, String date) async {
    try {
      final response = await _dio.get(
        '$_API_URL/restaurants/$restaurantId/availability',
        queryParameters: {'date': date},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Müsaitlik bilgisi alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Hata: $e');
    }
  }

  // 1. Kod Gönder
  Future<void> sendResetCode(String email) async {
    try {
      await _dio.post('$_API_URL/auth/send-code', data: {'email': email});
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Kod gönderilemedi.');
    }
  }

  // 2. Kodu Doğrula
  Future<bool> verifyResetCode(String email, String code) async {
    try {
      await _dio.post(
        '$_API_URL/auth/verify-code',
        data: {'email': email, 'code': code},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // 3. Şifreyi Sıfırla
  Future<void> resetPasswordWithEmail(String email, String newPassword) async {
    try {
      await _dio.post(
        '$_API_URL/auth/reset-password',
        data: {'email': email, 'newPassword': newPassword},
      );
    } catch (e) {
      throw Exception('Şifre güncellenemedi.');
    }
  }

  Future<void> _loadFavoritesFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? saved = prefs.getStringList('saved_favorites');
    if (saved != null) {
      _localFavorites.clear();
      _localFavorites.addAll(saved.map((e) => int.parse(e)));
    }
  }

  Future<void> _saveFavoritesToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> stringList = _localFavorites.map((e) => e.toString()).toList();
    await prefs.setStringList('saved_favorites', stringList);
  }

  Future<bool> toggleFavorite(int userId, int restaurantId) async {
    // Listede güncelle
    if (_localFavorites.contains(restaurantId)) {
      _localFavorites.remove(restaurantId);
    } else {
      _localFavorites.add(restaurantId);
    }

    // Diske kaydet (Kalıcı olması için)
    await _saveFavoritesToDisk();

    return true;
  }

  Future<List<dynamic>> getFavorites(int userId) async {
    // 1. Önce tüm restoranları çek (veya favorileri yükle)
    await _loadFavoritesFromDisk();

    try {
      // API'den güncel restoran listesini alıyoruz
      // (Gerçek bir app'te /favorites endpoint'i olur, şimdilik filtreliyoruz)
      final response = await _dio.get('$_API_URL/restaurants');
      if (response.statusCode == 200) {
        List<dynamic> all = response.data;
        // Sadece ID'si kayıtlı olanları filtrele
        var favorites = all
            .where((r) => _localFavorites.contains(r['restaurant_id']))
            .toList();

        // is_favorite bilgisini true yap (ekranda kırmızı kalp için)
        for (var f in favorites) {
          f['is_favorite'] = true;
        }

        return favorites;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> createBooking(int slotId, String date, int partySize) async {
    try {
      final response = await _dio.post(
        '$_API_URL/book',
        data: {
          'user_id': CURRENT_USER_ID,
          'slot_id': slotId,
          'booking_date': date,
          'party_size': partySize,
        },
      );

      if (response.statusCode == 201) {
        return;
      } else {
        throw Exception(response.data['message'] ?? 'Rezervasyon yapılamadı.');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Bağlantı hatası: ${e.message}');
    }
  }
}
