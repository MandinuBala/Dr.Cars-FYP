import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/main.dart';
import 'package:dr_cars_fyp/user/main_dashboard.dart';
import 'package:dr_cars_fyp/map/mapscreen.dart';
import 'package:dr_cars_fyp/obd/OBD2.dart';
import 'package:dr_cars_fyp/service/service_history.dart';
import 'package:dr_cars_fyp/user/user_profile.dart';
import 'package:dr_cars_fyp/auth/signin.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:dr_cars_fyp/l10n/app_strings.dart';
import 'package:dr_cars_fyp/providers/locale_provider.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dr_cars_fyp/widgets/app_bottom_nav.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String _selectedLanguage = 'en';
  bool _isLoading = false;

  String t(String key) => AppStrings.get(key, _selectedLanguage);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadUserData();
  }

  Future<void> _loadPreferences() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = p.getBool('darkMode') ?? false;
      _selectedLanguage = p.getString('language') ?? 'en';
      _notificationsEnabled = p.getBool('notificationsEnabled') ?? true;
      themeNotifier.value = _darkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _nameController.text =
            user['Name']?.toString() ?? user['name']?.toString() ?? '';
        _emailController.text =
            user['Email']?.toString() ?? user['email']?.toString() ?? '';
        _phoneController.text =
            user['Contact']?.toString() ?? user['contact']?.toString() ?? '';
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setString('language', _selectedLanguage);
    themeNotifier.value = _darkMode ? ThemeMode.dark : ThemeMode.light;
    await saveLocale(_selectedLanguage);

    final userId = await _authService.getCurrentUserId();
    if (userId != null && userId.isNotEmpty) {
      await _authService.updateUserById(userId, {
        'Name': _nameController.text.trim(),
        'Email': _emailController.text.trim(),
        'Contact': _phoneController.text.trim(),
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'contact': _phoneController.text.trim(),
        'language': _selectedLanguage,
      });
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t('save'))));
    setState(() => _isLoading = false);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  void _showPersonalInfoDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(t('personal_information')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: t('personal_information'),
                  ),
                ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('cancel')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _saveSettings();
                },
                child: Text(t('save')),
              ),
            ],
          ),
    );
  }

  void _showChangePasswordDialog() {
    final cur = TextEditingController();
    final neu = TextEditingController();
    final conf = TextEditingController();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(t('change_password')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: cur,
                  decoration: InputDecoration(labelText: t('current_password')),
                  obscureText: true,
                ),
                TextField(
                  controller: neu,
                  decoration: InputDecoration(labelText: t('new_password')),
                  obscureText: true,
                ),
                TextField(
                  controller: conf,
                  decoration: InputDecoration(labelText: t('confirm_password')),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('cancel')),
              ),
              TextButton(
                onPressed: () async {
                  if (neu.text != conf.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Passwords do not match')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  try {
                    final userId = await _authService.getCurrentUserId();
                    if (userId == null || userId.isEmpty) {
                      throw Exception('User not found');
                    }

                    await _authService.changePassword(
                      userId: userId,
                      currentPassword: cur.text,
                      newPassword: neu.text,
                    );

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Password changed')));
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: Text(t('change')),
              ),
            ],
          ),
    );
  }

  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(t('help_support')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: Text(t('contact_email')),
                  subtitle: const Text('support@drcars.com'),
                  onTap: () => _launchUrl('mailto:support@drcars.com'),
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text(t('contact_call')),
                  subtitle: const Text('+94 77 211 1426'),
                  onTap: () => _launchUrl('tel:+94772111426'),
                ),
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: Text(t('contact_chat')),
                  subtitle: const Text('WhatsApp'),
                  onTap: () => _launchUrl('https://wa.me/+94772111426'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('close')),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(t('about')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('images/logo.png', height: 80),
                const SizedBox(height: 12),
                const Text('Dr. Cars v1.0.0'),
                const Text('© 2025 Dr. Cars. All rights reserved.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('close')),
              ),
            ],
          ),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(t('logout_confirm_title')),
            content: Text(t('logout_confirm')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('no')),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _authService.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => SignInScreen()),
                    (_) => false,
                  );
                },
                child: Text(t('yes')),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(t('delete_confirm_title')),
            content: Text(t('delete_confirm')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('no')),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final userId = await _authService.getCurrentUserId();
                  if (userId != null && userId.isNotEmpty) {
                    await _authService.deleteUserById(userId);
                  }
                  await _authService.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => SignInScreen()),
                    (_) => false,
                  );
                },
                child: Text(
                  t('yes'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Privacy Policy'),
            content: SingleChildScrollView(
              child: Text('''Privacy Policy for Dr Cars

Effective Date: April 23, 2025

At Dr Cars, we are committed to protecting your privacy. This Privacy Policy explains how we collect, use, and protect your information when you use our car service booking app.

1. Information We Collect

When you use Dr Cars, we may collect the following personal information:
- Full Name
- Address
- Phone Number
- Email Address
- Username

This information is collected to provide you with a smooth and personalized experience when booking car services.

2. How We Use Your Information

We use your information to:
- Register and manage your account
- Process and confirm your service bookings
- Communicate with you regarding your bookings and support inquiries
- Improve our services and user experience
- Ensure security and prevent unauthorized access

3. Data Sharing

We do not sell, trade, or rent your personal information to third parties. We may share your information only:
- With service professionals (e.g., mechanics or garages) to fulfill your booking
- When required by law or legal process
- To protect the rights, property, or safety of Dr Cars and its users

4. Data Security

We implement reasonable safeguards to protect your personal information from unauthorized access, use, or disclosure.

5. Your Choices

You can review, update, or delete your personal information by contacting us or through your account settings in the app.

6. Changes to This Policy

We may update this Privacy Policy from time to time. If we make any significant changes, we will notify you through the app or by email.

7. Contact Us

If you have any questions or concerns about this Privacy Policy, please contact us at:
- Email: support@drcars.com
- Phone: +94 77 211 1426
- Chat: https://wa.me/+94772111426
'''),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('close')),
              ),
            ],
          ),
    );
  }

  void _showTerms() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Terms and Conditions'),
            content: SingleChildScrollView(
              child: Text('''Terms and Conditions for Dr Cars

Effective Date: April 23, 2025

Please read these Terms and Conditions ("Terms") carefully before using the Dr Cars app. By accessing or using the app, you agree to be bound by these Terms.

1. Use of the App
You agree to use the Dr Cars app only for lawful purposes and in accordance with these Terms. You may not misuse the app or interfere with its normal operation.

2. Service Bookings
All service bookings made through the app are subject to availability and confirmation. We reserve the right to cancel or refuse any booking at our discretion.

3. User Information
You are responsible for providing accurate and up-to-date information during registration and booking. Any false or misleading information may result in suspension of your account.

4. Payments
Prices and fees for services are displayed in the app and may vary based on location and service provider. All payments must be completed as per the method specified during booking.

5. Cancellations and Refunds
You may cancel a service within the allowed cancellation window specified during booking. Refunds (if applicable) are processed based on the service provider’s policy.

6. Intellectual Property
All content, branding, and features of the Dr Cars app are the property of Dr Cars or its licensors. You may not copy, modify, or distribute any part of the app without permission.

7. Limitation of Liability
Dr Cars is not responsible for any direct or indirect damages resulting from use of the app or services booked through it. We act solely as a platform connecting users and service providers.

8. Changes to Terms
We may update these Terms from time to time. Continued use of the app after changes means you accept the new Terms.

9. Governing Law
These Terms are governed by and interpreted in accordance with the laws of [Your Country/Region].

10. Contact Us
If you have any questions about these Terms, please contact us at:
Email: support@drcars.com
Phone: +94 77 211 1426
Chat: https://wa.me/+94772111426
'''),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('close')),
              ),
            ],
          ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Text(
      title.toUpperCase(),
      style: GoogleFonts.jost(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.5,
        color: AppColors.gold,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, lang, _) {
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppStrings.get('settings', lang),
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppColors.obsidian,
            elevation: 0,
            leading: const BackButton(),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _isLoading ? null : _saveSettings,
              ),
            ],
          ),
          body:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _sectionHeader(t('account_settings')),
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(t('personal_information')),
                        onTap: _showPersonalInfoDialog,
                      ),
                      ListTile(
                        leading: const Icon(Icons.notifications_outlined),
                        title: Text(t('notifications')),
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (v) async {
                            if (v) {
                              await OneSignal.User.pushSubscription.optIn();
                            } else {
                              await OneSignal.User.pushSubscription.optOut();
                            }
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('notificationsEnabled', v);
                            setState(() => _notificationsEnabled = v);
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(
                          t('language'),
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: DropdownButton<String>(
                          value: _selectedLanguage,
                          items: const [
                            DropdownMenuItem(
                              value: 'en',
                              child: Text(
                                'English',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'si',
                              child: Text(
                                'සිංහල',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ta',
                              child: Text(
                                'தமிழ்',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedLanguage = v);
                              saveLocale(v);
                            }
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.dark_mode),
                        title: Text(t('dark_mode')),
                        trailing: Switch(
                          value: _darkMode,
                          onChanged:
                              (v) => setState(() {
                                _darkMode = v;
                                themeNotifier.value =
                                    v ? ThemeMode.dark : ThemeMode.light;
                              }),
                        ),
                      ),
                      _sectionHeader(t('privacy_security')),
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: Text(t('privacy_policy')),
                        onTap: _showPrivacyPolicy,
                      ),
                      ListTile(
                        leading: const Icon(Icons.password),
                        title: Text(t('change_password')),
                        onTap: _showChangePasswordDialog,
                      ),
                      _sectionHeader(t('support')),
                      ListTile(
                        leading: const Icon(Icons.help_outline),
                        title: Text(t('help_support')),
                        onTap: _showHelpSupportDialog,
                      ),
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(t('terms')),
                        onTap: _showTerms,
                      ),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: Text(t('about')),
                        onTap: _showAboutDialog,
                      ),
                      _sectionHeader(t('account_actions')),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        title: Text(
                          t('delete_account'),
                          style: const TextStyle(color: Colors.red),
                        ),
                        onTap: _showDeleteConfirm,
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: Text(t('logout')),
                        onTap: _showLogoutConfirm,
                      ),
                    ],
                  ),
          bottomNavigationBar: AppBottomNav(currentIndex: 4),
        );
      },
    );
  }
}
