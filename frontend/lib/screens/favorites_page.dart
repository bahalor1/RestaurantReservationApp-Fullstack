import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:restaurant_app/services/api_service.dart';
import 'package:restaurant_app/screens/restaurant_detail_page.dart';
// CURRENT_USER_ID için
import 'package:restaurant_app/utils/app_localizations.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // Listeyi yenilemek için fonksiyon
  void _loadFavorites() {
    setState(() {
      _favoritesFuture = _apiService.getFavorites(CURRENT_USER_ID);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('title_favorites'))),
      body: FutureBuilder<List<dynamic>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(AppStrings.get('msg_error')));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.get('msg_no_favorites'),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          } else {
            final favorites = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: favorites.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final restaurant = favorites[index];
                return _buildFavoriteCard(context, restaurant, theme);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildFavoriteCard(
    BuildContext context,
    dynamic restaurant,
    ThemeData theme,
  ) {
    final String name = restaurant['name'] ?? AppStrings.get('label_no_name');
    String rawCuisine = restaurant['cuisine_type'] ?? '';
    String displayCuisine = rawCuisine; // Varsayılan

    // Veritabanından gelen Türkçe veriyi AppStrings ile eşleştiriyoruz
    if (rawCuisine == 'Kebap') {
      displayCuisine = AppStrings.get('category_kebab');
    } else if (rawCuisine == 'Balık') {
      displayCuisine = AppStrings.get('category_fish');
    } else if (rawCuisine == 'Burger') {
      displayCuisine = AppStrings.get('category_burger');
    } else if (rawCuisine == 'Pizza') {
      displayCuisine = AppStrings.get('category_pizza');
    } else if (rawCuisine == 'Kahvaltı') {
      displayCuisine = AppStrings.get('category_breakfast');
    } else if (rawCuisine == 'Tatlı') {
      displayCuisine = AppStrings.get('category_dessert');
    } else if (rawCuisine == 'Pide') {
      displayCuisine = AppStrings.get('category_pide');
    } else if (rawCuisine == 'Döner') {
      displayCuisine = AppStrings.get('category_doner');
    } else if (rawCuisine == 'Uzak Doğu') {
      displayCuisine = AppStrings.get('category_asian');
    } else if (rawCuisine == 'Ev Yemekleri') {
      displayCuisine = AppStrings.get('category_home_cooking');
    } else if (rawCuisine == 'Sokak Lezzetleri') {
      displayCuisine = AppStrings.get('category_street_food');
    }
    final String description =
        restaurant['description'] ?? AppStrings.get('label_no_desc');
    final String? imageUrl = restaurant['image_url'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailPage(
              restaurantId: restaurant['restaurant_id'],
              name: name,
              cuisine: displayCuisine,
              description: description,
              imageUrl: imageUrl,
            ),
          ),
        ).then((_) {
          _loadFavorites();
        });
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        color: theme.cardTheme.color,
        child: SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                height: 120,
                child: (imageUrl != null)
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.restaurant, color: Colors.grey),
                      )
                    : const Icon(Icons.restaurant, color: Colors.grey),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          GestureDetector(
                            onTap: () async {
                              await _apiService.toggleFavorite(
                                CURRENT_USER_ID,
                                restaurant['restaurant_id'],
                              );

                              _loadFavorites();

                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.get('msg_removed_fav'),
                                  ),
                                  duration: const Duration(milliseconds: 800),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 4.0,
                                right: 4.0,
                              ),
                              child: Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),
                      Text(
                        displayCuisine,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- SAĞ: OK İŞARETİ ---
              Container(
                width: 35,
                color: Theme.of(context).colorScheme.primary,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
