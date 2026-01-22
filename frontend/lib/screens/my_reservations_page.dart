import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:restaurant_app/services/api_service.dart';
import 'package:restaurant_app/screens/main_screen.dart';
import 'package:restaurant_app/utils/app_localizations.dart';

class MyReservationsPage extends StatefulWidget {
  const MyReservationsPage({super.key});

  @override
  State<MyReservationsPage> createState() => _MyReservationsPageState();
}

class _MyReservationsPageState extends State<MyReservationsPage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _reservationsFuture;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  void _loadReservations() {
    setState(() {
      _reservationsFuture = _apiService.getMyReservations(CURRENT_USER_ID);
    });
  }

  Future<void> _cancelReservation(int bookingId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppStrings.get('dialog_cancel_reservation_title'),
        ), // "Rezervasyonu İptal Et"
        content: Text(
          AppStrings.get('dialog_cancel_reservation_content'),
        ), // "Emin misiniz?"
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            // Temadan gelen yazı rengini kullan (Siyah/Beyaz)
            child: Text(
              AppStrings.get('btn_no'), // "Hayır"
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppStrings.get('btn_yes'), // "Evet"
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.cancelBooking(bookingId);

        setState(() {
          _loadReservations();
        });

        ScaffoldMessenger.of(
          // ignore: use_build_context_synchronously
          context,
        ).showSnackBar(
          SnackBar(content: Text(AppStrings.get('msg_reservation_cancelled'))),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${AppStrings.get('msg_error_prefix')} $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('reservations_title'))),
      body: FutureBuilder<List<dynamic>>(
        future: _reservationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "${AppStrings.get('msg_error_prefix')} ${snapshot.error}",
              ),
            );
          } else {
            final allReservations = snapshot.data ?? [];
            final now = DateTime.now();

            // FİLTRELEME: Sadece zamanı GEÇMEMİŞ (Gelecek) olanları al
            final upcomingReservations = allReservations.where((res) {
              try {
                DateTime datePart = DateTime.parse(res['booking_date']);
                List<String> timeParts = res['time'].toString().split(':');
                int hour = int.parse(timeParts[0]);
                int minute = int.parse(timeParts[1]);

                DateTime reservationTime = DateTime(
                  datePart.year,
                  datePart.month,
                  datePart.day,
                  hour,
                  minute,
                );

                return reservationTime.isAfter(now);
              } catch (e) {
                return false;
              }
            }).toList();

            // EĞER HİÇ REZERVASYON YOKSA (VEYA HEPSİ GEÇMİŞSE)
            if (upcomingReservations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 80,
                      color: Colors.blue[100],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppStrings.get('reservations_lowtitle'),
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 30),

                    // HEMEN REZERVASYON YAP BUTONU
                    ElevatedButton.icon(
                      onPressed: () {
                        // Menünün kaybolmaması için Ana Ekrana sıfırlıyoruz
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.restaurant, color: Colors.white),
                      label: Text(AppStrings.get('reservations_cleanpage')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: upcomingReservations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final res = upcomingReservations[index];

                // Tarihi string olarak al (YYYY-MM-DD)
                String dateStr = res['booking_date'].toString().substring(
                  0,
                  10,
                );

                return Card(
                  color: Colors.white70,
                  elevation: 3,
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        (res['image_url'] != null)
                            ? CachedNetworkImage(
                                imageUrl: res['image_url'],
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 100,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 100,
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.restaurant,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              )
                            : Container(
                                width: 100,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.restaurant,
                                  color: Colors.grey[400],
                                ),
                              ),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  res['restaurant_name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      res['time'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 14,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${res['party_size']} ${AppStrings.get('label_person')}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              _cancelReservation(res['booking_id']),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
