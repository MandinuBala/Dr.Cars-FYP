import 'package:dr_cars_fyp/service/check_service_acc_availability.dart';
import 'package:dr_cars_fyp/auth/signup.dart';
import 'package:dr_cars_fyp/auth/signup_service.dart';
import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/l10n/app_strings.dart';
import 'package:dr_cars_fyp/providers/locale_provider.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupSelection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.richBlack,
          appBar: AppBar(
            backgroundColor: AppColors.obsidian,
            foregroundColor: AppColors.textPrimary,
            iconTheme: const IconThemeData(color: AppColors.gold),
            title: Text(
              AppStrings.get('create_account_as', lang),
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ───────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.15),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'images/bg_removed_logo.png',
                      height: 100,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'DR. CARS',
                    style: GoogleFonts.jost(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.get('create_account_as', lang),
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  goldDivider(),
                  const SizedBox(height: 8),

                  // ── Vehicle Owner Card ──────────────────────────────
                  _buildRoleCard(
                    context: context,
                    icon: Icons.directions_car_outlined,
                    title: AppStrings.get('vehicle_owner', lang),
                    subtitle: 'Manage your vehicle, book services\nand track maintenance history',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SignUpPage()),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Service Center Card ─────────────────────────────
                  _buildRoleCard(
                    context: context,
                    icon: Icons.store_outlined,
                    title: AppStrings.get('service_center', lang),
                    subtitle: 'Manage appointments, receipts\nand customer vehicles',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceCenterRequestScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Check availability link ─────────────────────────
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckRequestStatusPage(),
                      ),
                    ),
                    icon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    label: Text(
                      'Check service center account availability',
                      style: GoogleFonts.jost(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGold),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.3),
                ),
              ),
              child: Icon(
                icon,
                color: AppColors.gold,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.jost(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.gold,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}