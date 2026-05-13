import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:dr_cars_fyp/user/main_dashboard.dart';
import 'package:dr_cars_fyp/map/mapscreen.dart';
import 'package:dr_cars_fyp/obd/OBD2.dart';
import 'package:dr_cars_fyp/service/service_history.dart';
import 'package:dr_cars_fyp/user/user_profile.dart';

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.35,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap(BuildContext context, int index) {
    if (index == widget.currentIndex) return;

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

  Future<void> _handleCenterTap(BuildContext context) async {
    if (widget.currentIndex == 2) return;
    // Animate scale up
    await _controller.forward();
    // Brief pause at peak so user sees the pop
    await Future.delayed(const Duration(milliseconds: 60));
    // Navigate — this widget disposes, button resets naturally on new page
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OBD2Page()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ── Base nav bar ─────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.obsidian,
                border: const Border(
                  top: BorderSide(color: AppColors.borderGold, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(context, 0, Icons.home_outlined, Icons.home),
                  _navItem(context, 1, Icons.map_outlined, Icons.map),
                  const SizedBox(width: 56), // spacer for center FAB
                  _navItem(context, 3, Icons.history, Icons.history),
                  _navItem(context, 4, Icons.person_outline, Icons.person),
                ],
              ),
            ),
          ),

          // ── Animated center FAB ──────────────────────────────────────
          Positioned(
            top: -16,
            child: GestureDetector(
              onTap: () => _handleCenterTap(context),
              child: ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.goldLight, AppColors.gold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: AppColors.goldLight.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.45),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Image.asset(
                      'images/bg_removed_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData activeIcon,
  ) {
    final isActive = widget.currentIndex == index;
    return GestureDetector(
      onTap: () => _onTap(context, index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50,
        height: 68,
        child: Center(
          child: Icon(
            isActive ? activeIcon : icon,
            color: isActive ? AppColors.gold : AppColors.textMuted,
            size: 24,
          ),
        ),
      ),
    );
  }
}
