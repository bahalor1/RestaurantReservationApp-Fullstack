import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:restaurant_app/services/api_service.dart';
import 'package:restaurant_app/screens/restaurant_detail_page.dart';
import 'package:restaurant_app/screens/favorites_page.dart';
import 'package:restaurant_app/utils/app_localizations.dart';
import 'dart:async';

class RestaurantListPage extends StatefulWidget {
  const RestaurantListPage({super.key});

  @override
  State<RestaurantListPage> createState() => _RestaurantListPageState();
}

class _RestaurantListPageState extends State<RestaurantListPage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _restaurantsFuture;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _selectedCategoryValue = 'Tümü';

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchRestaurants() {
    setState(() {
      _restaurantsFuture = _apiService.getRestaurants(
        searchQuery: _searchController.text,
        category: _selectedCategoryValue,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> categories = [
      {'value': 'Tümü', 'label': AppStrings.get('category_all')},
      {'value': 'Kebap', 'label': AppStrings.get('category_kebab')},
      {'value': 'Balık', 'label': AppStrings.get('category_fish')},
      {'value': 'Burger', 'label': AppStrings.get('category_burger')},
      {'value': 'Pizza', 'label': AppStrings.get('category_pizza')},
      {'value': 'Kahvaltı', 'label': AppStrings.get('category_breakfast')},
      {'value': 'Tatlı', 'label': AppStrings.get('category_dessert')},
      {'value': 'Pide', 'label': AppStrings.get('category_pide')},
      {'value': 'Döner', 'label': AppStrings.get('category_doner')},
      {'value': 'Uzak Doğu', 'label': AppStrings.get('category_asian')},
      {
        'value': 'Ev Yemekleri',
        'label': AppStrings.get('category_home_cooking'),
      },
      {
        'value': 'Sokak Lezzetleri',
        'label': AppStrings.get('category_street_food'),
      },
    ];

    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) => _fetchRestaurants(),
                        onChanged: (value) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 500),
                            () {
                              _fetchRestaurants();
                            },
                          );
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: AppStrings.get('search_hint'),
                          prefixIcon: Icon(
                            Icons.search,
                            color: theme.inputDecorationTheme.prefixIconColor,
                          ),
                          filled: true,
                          fillColor: theme.inputDecorationTheme.fillColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_sharp,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _fetchRestaurants();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FavoritesPage(),
                            ),
                          ).then((_) {
                            _fetchRestaurants();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 7),
                  itemBuilder: (context, index) {
                    final catMap = categories[index];
                    final isSelected =
                        _selectedCategoryValue == catMap['value'];

                    return ChoiceChip(
                      label: Text(catMap['label']!),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategoryValue = catMap['value']!;
                          });
                          _fetchRestaurants();
                        }
                      },
                      selectedColor: theme.chipTheme.selectedColor,
                      backgroundColor: theme.chipTheme.backgroundColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? theme.chipTheme.secondaryLabelStyle?.color
                            : theme.chipTheme.labelStyle?.color,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      showCheckmark: false,
                    );
                  },
                ),
              ),

              const SizedBox(height: 2),

              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _restaurantsFuture,
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
                            const Icon(
                              Icons.search_off,
                              size: 60,
                              color: Colors.grey,
                            ),
                            Text(
                              AppStrings.get('msg_no_data'),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    } else {
                      final restaurants = snapshot.data!;
                      return ListView.separated(
                        padding: const EdgeInsets.all(12.0),
                        itemCount: restaurants.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final restaurant = restaurants[index];

                          return RestaurantCard(
                            restaurant: restaurant,
                            apiService: _apiService,
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
      ),
    );
  }
}

class RestaurantCard extends StatefulWidget {
  final dynamic restaurant;
  final ApiService apiService;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.apiService,
  });

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();

    _isFavorite = widget.restaurant['is_favorite'] ?? false;
  }

  void _toggleFavorite() async {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    widget.restaurant['is_favorite'] = _isFavorite;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite
              ? AppStrings.get('msg_added_fav')
              : AppStrings.get('msg_removed_fav'),
        ),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      await widget.apiService.toggleFavorite(
        CURRENT_USER_ID,
        widget.restaurant['restaurant_id'],
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          widget.restaurant['is_favorite'] = _isFavorite;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name =
        widget.restaurant['name'] ?? AppStrings.get('label_no_name');
    String rawCuisine = widget.restaurant['cuisine_type'] ?? '';
    String displayCuisine = rawCuisine; // Varsayılan olarak aynısını kullan

    // Gelen veriyle AppStrings anahtarlarını eşleştiriyoruz
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
        widget.restaurant['description'] ?? AppStrings.get('label_no_desc');
    final String? imageUrl = widget.restaurant['image_url'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailPage(
              restaurantId: widget.restaurant['restaurant_id'],
              name: name,
              cuisine: displayCuisine,
              description: description,
              imageUrl: imageUrl,
            ),
          ),
        ).then((_) {});
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 4,
        color: Theme.of(context).cardTheme.color,
        child: SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              (imageUrl != null)
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 110,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 110,
                        color: Theme.of(context).cardTheme.color,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 110,
                        color: Theme.of(context).cardTheme.color,
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 110,
                      height: 120,
                      color: Theme.of(context).cardTheme.color,
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 0, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            onTap: _toggleFavorite,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isFavorite ? Colors.red : Colors.grey,
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
