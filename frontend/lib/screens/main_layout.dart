import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'study_screen.dart';
import 'typing_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';

import '../theme.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Pass the navigation callback to Dashboard so action cards can switch tabs
    final List<Widget> screens = [
      DashboardScreen(onNavigate: _navigateTo),
      const StudyScreen(),
      const TypingScreen(),
      const StatsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: screens[_currentIndex],
            ),
          ),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              borderRadius: 32,
              child: BottomNavigationBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                currentIndex: _currentIndex,
                onTap: _navigateTo,
                selectedItemColor: AppTheme.accentNeon,
                unselectedItemColor: AppTheme.textSecondary,
                showUnselectedLabels: false,
                showSelectedLabels: true,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_rounded),
                    activeIcon: Icon(Icons.dashboard_rounded, size: 28),
                    label: 'Dash',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.timer_outlined),
                    activeIcon: Icon(Icons.timer_rounded, size: 28),
                    label: 'Study',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.keyboard_outlined),
                    activeIcon: Icon(Icons.keyboard_rounded, size: 28),
                    label: 'Type',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart_rounded),
                    activeIcon: Icon(Icons.bar_chart_rounded, size: 28),
                    label: 'Stats',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person_rounded, size: 28),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
