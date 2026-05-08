import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:dr_cars_fyp/user/main_dashboard.dart';
import 'package:dr_cars_fyp/map/mapscreen.dart';
import 'package:dr_cars_fyp/obd/OBD2.dart';
import 'package:dr_cars_fyp/service/service_history.dart';
import 'package:dr_cars_fyp/user/user_profile.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget target;
    switch (index) {
      case 0:
        target = const DashboardScreen();
        break;
      case 1:
        target = MapScreen();
        break;
      case 2:
        target = const OBD2Page();
        break;
      case 3:
        target = const ServiceHistorypage();
        break;
      case 4:
        target = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.obsidian,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: AppColors.textMuted,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      elevation: 0,
      onTap: (index) => _onTap(context, index),
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: '',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('images/logo.png', width: 30, height: 30),
          label: '',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.history), label: ''),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: '',
        ),
      ],
    );
  }
}
