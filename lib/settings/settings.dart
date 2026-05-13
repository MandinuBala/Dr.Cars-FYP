// lib/settings/Settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/main.dart';
import 'package:dr_cars_fyp/user/main_dashboard.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            t('save'),
            style: GoogleFonts.jost(color: Colors.white),
          ),
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  // ── Themed text field for dialogs ─────────────────────────────────────────
  Widget _dialogTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: GoogleFonts.jost(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.jost(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          floatingLabelStyle: GoogleFonts.jost(
            color: AppColors.gold,
            fontSize: 12,
          ),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderGold),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderGold),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // ── Themed alert dialog ───────────────────────────────────────────────────
  Future<T?> _showThemedDialog<T>(Widget dialog) {
    return showDialog<T>(context: context, builder: (_) => dialog);
  }

  void _showPersonalInfoDialog() {
    _showThemedDialog(
      AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderGold),
        ),
        title: Text(
          t('personal_information'),
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogTextField(_nameController, 'Name'),
            _dialogTextField(_emailController, 'Email'),
            _dialogTextField(_phoneController, 'Phone'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t('cancel'),
              style: GoogleFonts.jost(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.obsidian,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              t('save'),
              style: GoogleFonts.jost(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final cur = TextEditingController();
    final neu = TextEditingController();
    final conf = TextEditingController();

    _showThemedDialog(
      AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderGold),
        ),
        title: Text(
          t('change_password'),
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogTextField(cur, t('current_password')),
            _dialogTextField(neu, t('new_password')),
            _dialogTextField(conf, t('confirm_password')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t('cancel'),
              style: GoogleFonts.jost(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (neu.text != conf.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.error,
                    content: Text(
                      'Passwords do not match',
                      style: GoogleFonts.jost(color: Colors.white),
                    ),
                  ),
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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text(
                        'Password changed successfully.',
                        style: GoogleFonts.jost(color: Colors.white),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.error,
                      content: Text(
                        'Error: $e',
                        style: GoogleFonts.jost(color: Colors.white),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.obsidian,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              t('change'),
              style: GoogleFonts.jost(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog() {
    _showThemedDialog(
      AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderGold),
        ),
        title: Text(
          t('help_support'),
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _contactTile(
              Icons.email_outlined,
              t('contact_email'),
              'support@drcars.com',
              () => _launchUrl('mailto:support@drcars.com'),
            ),
            _contactTile(
              Icons.phone_outlined,
              t('contact_call'),
              '+94 77 211 1426',
              () => _launchUrl('tel:+94772111426'),
            ),
            _contactTile(
              Icons.chat_outlined,
              t('contact_chat'),
              'WhatsApp',
              () => _launchUrl('https://wa.me/+94772111426'),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                t('close'),
                style: GoogleFonts.jost(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderGold),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gold, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.jost(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.jost(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    _showThemedDialog(
      AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderGold),
        ),
        title: Text(
          t('about'),
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Image.asset('images/logo.png', height: 60),
            ),
            const SizedBox(height: 16),
            Text(
              'Dr. Cars v1.0.0',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '© 2025 Dr. Cars. All rights reserved.',
              style: GoogleFonts.jost(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.obsidian,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                t('close'),
                style: GoogleFonts.jost(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm() {
    _showThemedDialog(
      AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderGold),
        ),
        title: Text(
          t('logout_confirm_title'),
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          t('logout_confirm'),
          style: GoogleFonts.jost(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t('no'),
              style: GoogleFonts.jost(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => SignInScreen()),
                  (_) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              t('yes'),
              style: GoogleFonts.jost(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm() {
    _showThemedDialog(
      AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderGold),
        ),
        title: Text(
          t('delete_confirm_title'),
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          t('delete_confirm'),
          style: GoogleFonts.jost(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              t('no'),
              style: GoogleFonts.jost(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final userId = await _authService.getCurrentUserId();
              if (userId != null && userId.isNotEmpty) {
                await _authService.deleteUserById(userId);
              }
              await _authService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => SignInScreen()),
                  (_) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              t('yes'),
              style: GoogleFonts.jost(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    _showThemedDialog(
      AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderGold),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            '''Privacy Policy for Dr Cars

Effective Date: April 23, 2025

At Dr Cars, we are committed to protecting your privacy...

1. Information We Collect
When you use Dr Cars, we may collect: Full Name, Address, Phone Number, Email Address, Username.

2. How We Use Your Information
We use your information to register and manage your account, process bookings, communicate with you, improve our services, and ensure security.

3. Data Sharing
We do not sell, trade, or rent your personal information to third parties.

4. Data Security
We implement reasonable safeguards to protect your personal information.

5. Contact Us
Email: support@drcars.com
Phone: +94 77 211 1426''',
            style: GoogleFonts.jost(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.obsidian,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                t('close'),
                style: GoogleFonts.jost(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTerms() {
    _showThemedDialog(
      AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderGold),
        ),
        title: Text(
          'Terms and Conditions',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            '''Terms and Conditions for Dr Cars

Effective Date: April 23, 2025

1. Use of the App
You agree to use the Dr Cars app only for lawful purposes.

2. Service Bookings
All bookings are subject to availability and confirmation.

3. User Information
You are responsible for providing accurate information.

4. Payments
Prices and fees are displayed in the app.

5. Cancellations and Refunds
You may cancel within the allowed cancellation window.

6. Intellectual Property
All content and features are the property of Dr Cars.

7. Limitation of Liability
Dr Cars is not responsible for any indirect damages.

8. Contact Us
Email: support@drcars.com
Phone: +94 77 211 1426''',
            style: GoogleFonts.jost(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.obsidian,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                t('close'),
                style: GoogleFonts.jost(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
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

  // ── Settings tile ─────────────────────────────────────────────────────────
  Widget _settingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGold),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.gold, size: 20),
        title: Text(
          title,
          style: GoogleFonts.jost(
            color: titleColor ?? AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textMuted,
            ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
            foregroundColor: AppColors.textPrimary,
            iconTheme: const IconThemeData(color: AppColors.gold),
            title: Text(
              AppStrings.get('settings', lang),
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.save, color: AppColors.gold),
                onPressed: _isLoading ? null : _saveSettings,
              ),
            ],
          ),
          body:
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  )
                  : ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      // ── Account Settings ──────────────────────────
                      _sectionHeader(t('account_settings')),

                      _settingsTile(
                        icon: Icons.person_outline,
                        title: t('personal_information'),
                        onTap: _showPersonalInfoDialog,
                      ),

                      _settingsTile(
                        icon: Icons.notifications_outlined,
                        title: t('notifications'),
                        trailing: Switch(
                          value: _notificationsEnabled,
                          activeColor: AppColors.gold,
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

                      _settingsTile(
                        icon: Icons.language,
                        title: t('language'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderGold),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedLanguage,
                              dropdownColor: AppColors.surfaceElevated,
                              style: GoogleFonts.jost(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.gold,
                                size: 18,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'en',
                                  child: Text('English'),
                                ),
                                DropdownMenuItem(
                                  value: 'si',
                                  child: Text('සිංහල'),
                                ),
                                DropdownMenuItem(
                                  value: 'ta',
                                  child: Text('தமிழ்'),
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
                        ),
                      ),

                      _settingsTile(
                        icon: Icons.dark_mode_outlined,
                        title: t('dark_mode'),
                        trailing: Switch(
                          value: _darkMode,
                          activeColor: AppColors.gold,
                          onChanged:
                              (v) => setState(() {
                                _darkMode = v;
                                themeNotifier.value =
                                    v ? ThemeMode.dark : ThemeMode.light;
                              }),
                        ),
                      ),

                      // ── Privacy & Security ────────────────────────
                      _sectionHeader(t('privacy_security')),

                      _settingsTile(
                        icon: Icons.shield_outlined,
                        title: t('privacy_policy'),
                        onTap: _showPrivacyPolicy,
                      ),
                      _settingsTile(
                        icon: Icons.lock_outline,
                        title: t('change_password'),
                        onTap: _showChangePasswordDialog,
                      ),

                      // ── Support ───────────────────────────────────
                      _sectionHeader(t('support')),

                      _settingsTile(
                        icon: Icons.help_outline,
                        title: t('help_support'),
                        onTap: _showHelpSupportDialog,
                      ),
                      _settingsTile(
                        icon: Icons.description_outlined,
                        title: t('terms'),
                        onTap: _showTerms,
                      ),
                      _settingsTile(
                        icon: Icons.info_outline,
                        title: t('about'),
                        onTap: _showAboutDialog,
                      ),

                      // ── Account Actions ───────────────────────────
                      _sectionHeader(t('account_actions')),

                      _settingsTile(
                        icon: Icons.logout,
                        title: t('logout'),
                        onTap: _showLogoutConfirm,
                      ),
                      _settingsTile(
                        icon: Icons.delete_outline,
                        title: t('delete_account'),
                        titleColor: AppColors.error,
                        iconColor: AppColors.error,
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.error,
                        ),
                        onTap: _showDeleteConfirm,
                      ),
                    ],
                  ),
          bottomNavigationBar: AppBottomNav(currentIndex: 4),
        );
      },
    );
  }
}
