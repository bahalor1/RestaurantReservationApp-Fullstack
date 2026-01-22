import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:restaurant_app/services/api_service.dart';
import 'package:restaurant_app/utils/app_localizations.dart'; // IMPORT ETMEYİ UNUTMA

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _pastReservationsFuture;

  // Kullanıcı bilgilerini tutacak değişkenler
  Map<String, dynamic>? _userProfile;
  bool _isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    _pastReservationsFuture = _fetchPastReservations();
  }

  Future<void> _fetchProfileData() async {
    try {
      final profile = await _apiService.getUserProfile(CURRENT_USER_ID);
      setState(() {
        _userProfile = profile;
        _isProfileLoading = false;
      });
    } catch (e) {
      setState(() {
        _isProfileLoading = false;
      });
      // ignore: avoid_print
      print("Profil yüklenemedi: $e");
    }
  }

  Future<List<dynamic>> _fetchPastReservations() async {
    try {
      final allReservations = await _apiService.getMyReservations(
        CURRENT_USER_ID,
      );
      final now = DateTime.now();

      final pastReservations = allReservations.where((res) {
        DateTime datePart = DateTime.parse(res['booking_date']);
        List<String> timeParts = res['time'].toString().split(':');

        DateTime reservationTime = DateTime(
          datePart.year,
          datePart.month,
          datePart.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        return reservationTime.isBefore(now);
      }).toList();

      return pastReservations;
    } catch (e) {
      return [];
    }
  }

  Future<void> _clearHistory() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppStrings.get('dialog_clear_history_title'),
        ), // "Geçmişi Temizle"
        content: Text(
          AppStrings.get('dialog_clear_history_content'),
        ), // "Emin misiniz?"
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.get('btn_cancel')), // "Vazgeç/İptal"
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppStrings.get('btn_clear'), // "Temizle"
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.clearHistory(CURRENT_USER_ID);

        if (mounted) {
          setState(() {
            _pastReservationsFuture = _fetchPastReservations();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.get('msg_history_cleared'),
              ), // "Başarıyla temizlendi"
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${AppStrings.get('msg_error_prefix')} $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tarih formatlayıcı
    String formatDate(String? dateString) {
      if (dateString == null) {
        return AppStrings.get('date_not_specified'); // "Belirtilmemiş"
      }
      try {
        DateTime date = DateTime.parse(dateString);
        return "${date.day}/${date.month}/${date.year}";
      } catch (e) {
        return dateString;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: _isProfileLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 3,
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/300?img=68',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          (_userProfile?["name"] == null ||
                                  _userProfile?["name"] == "")
                              ? AppStrings.get(
                                  'guest_user',
                                ) // "Misafir Kullanıcı"
                              : _userProfile?["name"],
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),

                        Text(
                          _userProfile?['email'] ?? "",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cake,
                                size: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                // "Doğum Tarihi: 2025-10-10"
                                "${AppStrings.get('label_birth_date')}: ${formatDate(_userProfile?['birth_date'])}",
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 0),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.get(
                      'profile_reservations',
                    ), // "Geçmiş Rezervasyonlarım"
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),

                  ElevatedButton.icon(
                    onPressed: _clearHistory,
                    icon: Icon(
                      Icons.delete_outlined,
                      size: 15,
                      color: Colors.red[600],
                    ),
                    label: Text(
                      AppStrings.get('profile_history'), // "Geçmişi Sil"
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red[50]),
                      side: WidgetStateProperty.all(BorderSide.none),
                      elevation: WidgetStateProperty.all(0),
                      shape: WidgetStateProperty.all(const StadiumBorder()),
                      overlayColor: WidgetStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        if (states.contains(WidgetState.hovered)) {
                          // ignore: deprecated_member_use
                          return Colors.red.withOpacity(0.2);
                        }
                        if (states.contains(WidgetState.pressed)) {
                          // ignore: deprecated_member_use
                          return Colors.red.withOpacity(0.3);
                        }
                        return null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 0),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _pastReservationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(AppStrings.get('err_loading')),
                    ); // "Yüklenemedi."
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 60,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppStrings.get(
                              'no_past_reservations',
                            ), // "Geçmiş rezervasyonunuz yok."
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  } else {
                    final history = snapshot.data!;

                    return ListView.separated(
                      padding: const EdgeInsets.all(10),
                      itemCount: history.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final res = history[index];
                        String dateStr = res['booking_date']
                            .toString()
                            .substring(0, 10);

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 0.3,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: (res['image_url'] != null)
                                  ? CachedNetworkImage(
                                      imageUrl: res['image_url'],
                                      width: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.restaurant),
                                    ),
                            ),
                            title: Text(
                              res['restaurant_name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              // "2025-10-10 • 4 Kişi"
                              "$dateStr • ${res['party_size']} ${AppStrings.get('label_person')}",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
