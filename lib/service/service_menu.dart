import 'dart:convert';

import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/auth/signin.dart';
import 'package:dr_cars_fyp/service/service_receipts_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'records_screen.dart';
import 'package:dr_cars_fyp/appointments/appointments_screen.dart';
import 'add_vehicle.dart';
import 'package:dr_cars_fyp/l10n/app_strings.dart';
import 'package:dr_cars_fyp/providers/locale_provider.dart';
import 'package:dr_cars_fyp/settings/settings.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> _loadHeaderData() async {
    final currentUser = await _authService.getCurrentUser();
    final userId =
        currentUser?['uid']?.toString() ??
        currentUser?['id']?.toString() ??
        currentUser?['_id']?.toString() ??
        currentUser?['userId']?.toString();

    String name =
        currentUser?['Name']?.toString() ??
        currentUser?['name']?.toString() ??
        currentUser?['Service Center Name']?.toString() ??
        'Service Center';

    int count = 0;

    if (userId != null && userId.isNotEmpty) {
      final userDoc = await _authService.getUserById(userId);
      if (userDoc != null) {
        name =
            userDoc['Name']?.toString() ??
            userDoc['name']?.toString() ??
            userDoc['Service Center Name']?.toString() ??
            userDoc['serviceCenterName']?.toString() ??
            name;
      }

      final response = await http.get(
        Uri.parse(
          '${_authService.baseUrl}/service-receipts/service-center/${Uri.encodeComponent(userId)}',
        ),
      );

      if (response.statusCode == 200) {
        final receipts = jsonDecode(response.body) as List<dynamic>;
        count =
            receipts.where((r) {
              final status = (r as Map)['status']?.toString();
              return status == 'confirmed' || status == 'rejected';
            }).length;
      }
    }

    return {'name': name, 'count': count};
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.richBlack,
          appBar: AppBar(
            backgroundColor: AppColors.obsidian,
            automaticallyImplyLeading: false,
            title: FutureBuilder<Map<String, dynamic>>(
              future: _loadHeaderData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text(
                    AppStrings.get('loading', lang),
                    style: const TextStyle(color: Colors.white),
                  );
                }
                if (!snapshot.hasData) {
                  return Text(
                    AppStrings.get('welcome_back', lang),
                    style: const TextStyle(color: Colors.white),
                  );
                }

                final data = snapshot.data!;
                final name = data['name']?.toString() ?? 'Service Center';
                final count = (data['count'] as num?)?.toInt() ?? 0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          tooltip: AppStrings.get('settings', lang),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SettingsScreen(),
                              ),
                            );
                          },
                        ),
                        ClipOval(
                          child: Image.asset(
                            'images/logo.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${AppStrings.get('welcome_back', lang)} $name',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ServiceReceiptsPage(),
                              ),
                            );
                          },
                        ),
                        if (count > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          body: SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        'images/bg_removed_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 50),
                    _buildMenuButton(
                      context,
                      text: AppStrings.get('add_new', lang),
                      subtext: AppStrings.get('add_new_sub', lang),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddVehicle()),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildMenuButton(
                      context,
                      text: AppStrings.get('records', lang),
                      subtext: AppStrings.get('records_sub', lang),
                      onPressed: () async {
                        bool isAuthenticated = await showDialog(
                          context: context,
                          builder: (context) => PasswordDialog(),
                        );
                        if (isAuthenticated) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecordsScreen(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Wrong password")),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildMenuButton(
                      context,
                      text: AppStrings.get('appointments', lang),
                      subtext: AppStrings.get('appointments_sub', lang),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 100),
                    ElevatedButton(
                      onPressed: () async {
                        await _authService.logout();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignInScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.error,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                            color: AppColors.error,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        AppStrings.get('sign_out', lang),
                        style: GoogleFonts.jost(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: Colors.white,
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

  Widget _buildMenuButton(
    BuildContext context, {
    required String text,
    required String subtext,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGold),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtext,
                style: GoogleFonts.jost(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PasswordDialog extends StatefulWidget {
  const PasswordDialog({super.key});

  @override
  _PasswordDialogState createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final AuthService _authService = AuthService();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<bool> _verifyPassword() async {
    try {
      final user = await _authService.getCurrentUser();
      final email = user?['email']?.toString() ?? user?['Email']?.toString();
      final password = _passwordController.text.trim();

      if (email == null || password.isEmpty) {
        return false;
      }

      await _authService.login(email, password);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _errorText,
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            setState(() {
              _isLoading = true;
              _errorText = null;
            });

            final isAuthenticated = await _verifyPassword();

            setState(() {
              _isLoading = false;
            });

            if (isAuthenticated) {
              Navigator.of(context).pop(true);
            } else {
              setState(() {
                _errorText = "Wrong password!";
              });
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
