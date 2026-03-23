import 'package:flutter/material.dart';


import 'package:focus_app/widgets/glass_container.dart';
import 'package:focus_app/theme/app_theme.dart';

import 'package:focus_app/screens/profile_screen.dart';
import 'package:focus_app/screens/dashboard_screen.dart';
import 'package:focus_app/screens/habit_garden_screen.dart';
import 'package:focus_app/screens/calendar_screen.dart';
import 'package:focus_app/screens/focus_timer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;


  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    CalendarScreen(),
    FocusTimerScreen(),
    HabitGardenScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    // Block navigation away from focus timer when it's running
    if (FocusTimerScreen.isTimerRunning.value && index != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Focus timer is running! Pause or stop it first. 🔒'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
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
            child: ValueListenableBuilder<bool>(
              valueListenable: FocusTimerScreen.isTimerRunning,
              builder: (context, timerActive, child) {
                return GlassContainer(
                  opacity: 0.9,
                  blur: 20,
                  borderRadius: BorderRadius.circular(30),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Home', timerActive),
                      _buildNavItem(1, Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Plan', timerActive),
                      _buildNavItem(2, Icons.timer_rounded, Icons.timer_outlined, 'Focus', timerActive),
                      _buildNavItem(3, Icons.yard_rounded, Icons.yard_outlined, 'Garden', timerActive),
                      _buildNavItem(4, Icons.person_rounded, Icons.person_outline, 'Profile', timerActive),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon, String label, bool timerActive) {
    final isSelected = _selectedIndex == index;
    // Dim non-Focus tabs when timer is active
    final isLocked = timerActive && index != 2;
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
              color: isLocked
                  ? Colors.grey[300]
                  : (isSelected ? AppTheme.primaryColor : Colors.grey[400]),
              size: 24,
            ),
            if (isSelected)
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isLocked ? Colors.grey[300] : AppTheme.primaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
