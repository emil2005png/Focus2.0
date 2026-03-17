import 'package:flutter/material.dart';


import 'package:focus_app/screens/journal_main_screen.dart';

import 'package:focus_app/widgets/glass_container.dart';
import 'package:focus_app/theme/app_theme.dart';

import 'package:focus_app/screens/profile_screen.dart';
import 'package:focus_app/screens/dashboard_screen.dart';
import 'package:focus_app/screens/habit_garden_screen.dart';
import 'package:focus_app/screens/achievements_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;


  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    HabitGardenScreen(),
    AchievementsScreen(),
    JournalMainScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allow body to extend behind the floating nav
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _widgetOptions,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: GlassContainer(
              opacity: 0.9,
              blur: 20,
              borderRadius: BorderRadius.circular(30),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                  _buildNavItem(1, Icons.yard_rounded, Icons.yard_outlined, 'Garden'),
                  _buildNavItem(2, Icons.emoji_events_rounded, Icons.emoji_events_outlined, 'Awards'),
                  _buildNavItem(3, Icons.book_rounded, Icons.book_outlined, 'Journal'),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
              size: 24,
            ),
            if (isSelected)
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
