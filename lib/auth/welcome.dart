import 'package:dr_cars_fyp/auth/signin.dart';
import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/l10n/app_strings.dart';
import 'package:dr_cars_fyp/providers/locale_provider.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.richBlack,
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with gold glow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'images/bg_removed_logo.png',
                        height: 180,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Gold divider
                    goldDivider(),

                    const SizedBox(height: 24),

                    // Welcome text
                    Text(
                      AppStrings.get('welcome', lang),
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'DR. CARS',
                      style: GoogleFonts.jost(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                        letterSpacing: 6,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Language Selector
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderGold),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.surfaceDark,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.language,
                            color: AppColors.gold,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: lang,
                              dropdownColor: AppColors.surfaceElevated,
                              style: GoogleFonts.jost(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'en',
                                  child: Text('🇬🇧  English'),
                                ),
                                DropdownMenuItem(
                                  value: 'si',
                                  child: Text('🇱🇰  සිංහල'),
                                ),
                                DropdownMenuItem(
                                  value: 'ta',
                                  child: Text('🇱🇰  தமிழ்'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) saveLocale(v);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignInScreen(),
                            ),
                          );
                        },
                        child: Text(
                          AppStrings.get('continue_btn', lang),
                          style: GoogleFonts.jost(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: AppColors.obsidian,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
