import 'package:flutter/material.dart';
import 'package:focus_app/services/auth_service.dart';
import 'package:focus_app/screens/login_screen.dart';
import 'package:focus_app/screens/mood_checkin_screen.dart';
import 'package:focus_app/screens/journal_list_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/widgets/glass_container.dart';
import 'package:focus_app/theme/app_theme.dart';

import 'package:focus_app/screens/reflection_screen.dart';
import 'package:focus_app/screens/profile_screen.dart';
import 'package:focus_app/screens/dashboard_screen.dart';
import 'package:focus_app/screens/habit_garden_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    HabitGardenScreen(),
    JournalListScreen(),
    ReflectionScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allow body to extend behind the floating nav
      body: Stack(
        children: [
          _widgetOptions.elementAt(_selectedIndex),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: GlassContainer(
              opacity: 0.9,
              blur: 20,
              borderRadius: BorderRadius.circular(30),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                  _buildNavItem(1, Icons.yard_rounded, Icons.yard_outlined, 'Garden'),
                  _buildNavItem(2, Icons.book_rounded, Icons.book_outlined, 'Journal'),
                  _buildNavItem(3, Icons.lightbulb_rounded, Icons.lightbulb_outline, 'Reflect'),
                  _buildNavItem(4, Icons.person_rounded, Icons.person_outline, 'Profile'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? selectedIcon : unselectedIcon,
          color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
          size: 26,
        ),
      ),
    );
  }
}
