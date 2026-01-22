import 'package:flutter/material.dart';
import 'package:restaurant_app/screens/restaurant_list_page.dart';
import 'package:restaurant_app/screens/my_reservations_page.dart';
import 'package:restaurant_app/screens/profile_page.dart';
import 'package:restaurant_app/screens/settings_page.dart';
import 'package:restaurant_app/utils/app_localizations.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Sayfaların listesi
  final List<Widget> _pages = [
    const RestaurantListPage(), // 0. İndeks
    const MyReservationsPage(), // 1. İndeks
    const ProfilePage(), // 2. İndeks
    const SettingsPage(), // 3. İndeks
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,

        onDestinationSelected: _onItemTapped,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(
              Icons.search,
              color: Theme.of(context).primaryColor,
              size: 25,
            ),
            label: AppStrings.get('tab_home'),
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(
              Icons.calendar_today,
              color: Theme.of(context).primaryColor,
              size: 22,
            ),
            label: AppStrings.get('tab_reservations'),
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(
              Icons.person,
              color: Theme.of(context).primaryColor,
              size: 25,
            ),
            label: AppStrings.get('tab_profile'),
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(
              Icons.settings,
              color: Theme.of(context).primaryColor,
              size: 25,
            ),
            label: AppStrings.get('tab_settings'),
          ),
        ],
      ),
    );
  }
}
