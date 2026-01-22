import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:restaurant_app/services/api_service.dart';
import 'package:restaurant_app/utils/app_localizations.dart';

class RestaurantDetailPage extends StatefulWidget {
  final int restaurantId;
  final String name;
  final String cuisine;
  final String description;
  final String? imageUrl;

  const RestaurantDetailPage({
    super.key,
    required this.restaurantId,
    required this.name,
    required this.cuisine,
    required this.description,
    this.imageUrl,
  });

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  final ApiService _apiService = ApiService();

  DateTime? _selectedDate;

  int? _selectedSlotId;

  int _selectedPartySize = 2;

  bool _isBookingLoading = false;

  List<dynamic> _availableSlots = [];
  bool _isLoadingSlots = false;
  String? _slotError;

  // Tarih seçici
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      locale: Locale(AppStrings.language),
      builder: (context, child) {
        // Temayı özelleştirebilirsin
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue, // Seçili tarih rengi
              onPrimary: Colors.white, // Seçili tarih yazı rengi
              onSurface: Colors.black, // Diğer yazı renkleri
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue, // Buton yazı rengi
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedSlotId = null;
        _availableSlots = [];
      });
      _fetchSlots();
    }
  }

  Future<void> _fetchSlots() async {
    if (_selectedDate == null) return;

    setState(() {
      _isLoadingSlots = true;
      _slotError = null;
    });

    try {
      String dateString =
          "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      final slots = await _apiService.getAvailability(
        widget.restaurantId,
        dateString,
      );

      setState(() {
        _availableSlots = slots;
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() {
        _slotError = AppStrings.get('msg_slot_error');
        _isLoadingSlots = false;
      });
    }
  }

  // --- YENİ: Rezervasyon Oluşturma Fonksiyonu ---
  Future<void> _createReservation() async {
    if (_selectedSlotId == null || _selectedDate == null) return;

    setState(() {
      _isBookingLoading = true;
    });

    try {
      String dateString = _selectedDate!.toIso8601String().substring(0, 10);

      // Servise kişi sayısını da gönderiyoruz
      await _apiService.createBooking(
        _selectedSlotId!,
        dateString,
        _selectedPartySize,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('msg_reservation_success')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Başarılı olursa seçimi sıfırla ve listeyi yenile (kapasite düşüşünü görmek için)
        setState(() {
          _selectedSlotId = null;
        });
        _fetchSlots();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${AppStrings.get('msg_error_prefix')} ${e.toString().replaceFirst("Exception: ", "")}",
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBookingLoading = false;
        });
      }
    }
  }

  // --- YENİ SAAT SEÇME PENCERESİ ---
  void _showTimeSlotPicker() {
    if (_availableSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('msg_select_date_first')),
        ), // "Lütfen önce tarih...")
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Text(
                AppStrings.get('label_select_time'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _availableSlots.length,
                  itemBuilder: (context, index) {
                    final slot = _availableSlots[index];

                    final now = DateTime.now();
                    bool isToday =
                        _selectedDate!.year == now.year &&
                        _selectedDate!.month == now.month &&
                        _selectedDate!.day == now.day;

                    bool isPastTime = false;
                    if (isToday) {
                      List<String> parts = slot['time'].toString().split(':');
                      DateTime slotTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        int.parse(parts[0]),
                        int.parse(parts[1]),
                      );

                      if (slotTime.isBefore(now)) {
                        isPastTime = true;
                      }
                    }

                    final isFull = slot['available'] <= 0;
                    final isSelectable = !isPastTime && !isFull;
                    final isSelected = _selectedSlotId == slot['slot_id'];

                    return GestureDetector(
                      onTap: isSelectable
                          ? () {
                              setState(() {
                                _selectedSlotId = slot['slot_id'];
                              });
                              Navigator.pop(context);
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue[600]
                              : (isSelectable
                                    ? Colors.white
                                    : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.black38
                                : Colors.grey[300]!,
                          ),
                          boxShadow: isSelectable && !isSelected
                              ? [
                                  BoxShadow(
                                    // ignore: deprecated_member_use
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slot['time'].toString().substring(0, 5),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isSelectable
                                          ? Colors.black87
                                          : Colors.grey),
                                decoration: isPastTime
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),

                            const SizedBox(height: 2),

                            if (!isPastTime)
                              Text(
                                isFull
                                    ? AppStrings.get('status_full')
                                    : "(${slot['available']} ${AppStrings.get('text_available')})",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                  color: isSelected
                                      // ignore: deprecated_member_use
                                      ? Colors.white.withOpacity(0.9)
                                      : (isFull ? Colors.red : Colors.black87),
                                ),
                              )
                            else
                              Text(
                                AppStrings.get('status_past'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.imageUrl != null)
              CachedNetworkImage(
                imageUrl: widget.imageUrl!,
                width: double.infinity,
                height: 250,
                alignment: Alignment(0, 0.5),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey[400],
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.cuisine,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(widget.description, style: TextStyle(fontSize: 12)),
                  SizedBox(height: 10),
                  Divider(color: Colors.grey, endIndent: 20, height: 5),
                  SizedBox(height: 10),

                  Text(
                    AppStrings.get('label_reservation_date'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      label: Text(
                        _selectedDate == null
                            ? AppStrings.get('label_select_date')
                            : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () => _selectDate(context),
                    ),
                  ),

                  SizedBox(height: 20),

                  Text(
                    AppStrings.get('label_party_size'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedPartySize,
                        isExpanded: true,
                        items: List.generate(10, (index) => index + 1).map((
                          number,
                        ) {
                          return DropdownMenuItem<int>(
                            value: number,
                            child: Text(
                              "$number ${AppStrings.get('label_person')}",
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPartySize = value!;
                          });
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  if (_selectedDate == null)
                    Center(
                      child: Text(
                        AppStrings.get('msg_select_date_first'),
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else if (_isLoadingSlots)
                    Center(child: CircularProgressIndicator())
                  else if (_slotError != null)
                    Center(
                      child: Text(
                        _slotError!,
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  else if (_availableSlots.isEmpty)
                    Center(child: Text(AppStrings.get('msg_no_slots')))
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('label_available_slots'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: Icon(
                              Icons.access_time,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            label: Text(
                              _selectedSlotId == null
                                  ? AppStrings.get('label_select_time')
                                  : _availableSlots
                                        .firstWhere(
                                          (slot) =>
                                              slot['slot_id'] ==
                                              _selectedSlotId,
                                          orElse: () => {
                                            'time': AppStrings.get(
                                              'status_selected',
                                            ),
                                          },
                                        )['time']
                                        .toString()
                                        .substring(0, 5),
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              // Seçim yapıldıysa mavi, yapılmadıysa gri kenarlık
                              side: BorderSide(
                                color: _selectedSlotId != null
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.grey,
                              ),
                            ),
                            onPressed: (_selectedDate == null)
                                ? null
                                : _showTimeSlotPicker,
                          ),
                        ),

                        SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                (_selectedSlotId == null || _isBookingLoading)
                                ? null
                                : _createReservation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isBookingLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    AppStrings.get('btn_create_reservation'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 50),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
