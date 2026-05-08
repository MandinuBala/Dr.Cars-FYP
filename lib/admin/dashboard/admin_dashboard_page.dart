import 'package:dr_cars_fyp/admin/requests/pending_requests_page.dart';
import 'package:dr_cars_fyp/admin/requests/rejected_requests_page.dart';
import 'package:dr_cars_fyp/auth/signin.dart';
import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/l10n/app_strings.dart';
import 'package:dr_cars_fyp/providers/locale_provider.dart';
import 'package:dr_cars_fyp/settings/settings.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceCenterApprovalPage extends StatefulWidget {
  const ServiceCenterApprovalPage({super.key});

  @override
  State<ServiceCenterApprovalPage> createState() =>
      _ServiceCenterApprovalPageState();
}

class _ServiceCenterApprovalPageState extends State<ServiceCenterApprovalPage> {
  final AuthService _authService = AuthService();
  late final Future<Map<String, dynamic>?> _currentUserFuture;

  @override
  void initState() {
    super.initState();
    _currentUserFuture = _authService.getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, lang, _) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: _currentUserFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final user = snapshot.data;
            final role =
                user?['userType']?.toString() ?? user?['User Type']?.toString();

            if (role != 'App Admin') {
              return Scaffold(
                appBar: AppBar(
                  title: Text(AppStrings.get('access_denied', lang)),
                  backgroundColor: AppColors.obsidian,
                  foregroundColor: AppColors.textPrimary,
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.get('admin_only', lang),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            await _authService.logout();
                            if (!context.mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignInScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.obsidian,
                          ),
                          child: Text(AppStrings.get('back_to_signin', lang)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  title: Text(AppStrings.get('service_center_requests', lang)),
                  backgroundColor: AppColors.obsidian,
                  foregroundColor: AppColors.textPrimary,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      tooltip: AppStrings.get('settings', lang),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SettingsScreen()),
                        );
                      },
                    ),
                    IconButton(
                      onPressed: () async {
                        await _authService.logout();
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignInScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: AppStrings.get('sign_out', lang),
                    ),
                  ],
                  bottom: TabBar(
                    indicatorColor: AppColors.gold,
                    labelColor: AppColors.gold,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: GoogleFonts.jost(fontWeight: FontWeight.w600),

                    tabs: [
                      Tab(text: AppStrings.get('pending', lang)),
                      Tab(text: AppStrings.get('rejected', lang)),
                    ],
                  ),
                ),
                body: const TabBarView(
                  children: [PendingRequestsTab(), RejectedRequestsTab()],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
