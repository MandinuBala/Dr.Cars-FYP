import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_service.dart';
import '../user/main_dashboard.dart';
import '../service/service_menu.dart';
import '../admin/dashboard/admin_dashboard_page.dart';

class GooglePasswordLinkPage extends StatefulWidget {
  final String email;
  final String googleId;
  final String userType;

  const GooglePasswordLinkPage({
    required this.email,
    required this.googleId,
    required this.userType,
    super.key,
  });

  @override
  State<GooglePasswordLinkPage> createState() => _GooglePasswordLinkPageState();
}

class _GooglePasswordLinkPageState extends State<GooglePasswordLinkPage> {
  final _formKey = GlobalKey<FormState>();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool isLoading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  final _authService = AuthService();

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _linkAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final existingUser = await _authService.getUserByEmail(widget.email);
      if (existingUser != null) {
        await _authService.updateUser(widget.email, {
          'password': passwordController.text.trim(),
          'googleId': widget.googleId,
        });
      } else {
        await _authService.createUser({
          'email': widget.email,
          'password': passwordController.text.trim(),
          'googleId': widget.googleId,
          'userType': widget.userType,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      Widget screen;
      if (widget.userType == 'Vehicle Owner') {
        screen = DashboardScreen();
      } else if (widget.userType == 'Service Center') {
        screen = HomeScreen();
      } else {
        screen = ServiceCenterApprovalPage();
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => screen),
          (route) => false,
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
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.richBlack,
      appBar: AppBar(
        backgroundColor: AppColors.obsidian,
        foregroundColor: AppColors.textPrimary,
        iconTheme: const IconThemeData(color: AppColors.gold),
        title: Text(
          'Link Google Account',
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Google icon ───────────────────────────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceDark,
                    border: Border.all(
                      color: AppColors.gold.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.g_mobiledata,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Link Your Account',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a password to link with\nyour Google account',
                  style: GoogleFonts.jost(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                // ── Email display ─────────────────────────────────
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGold),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        color: AppColors.gold,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.email,
                        style: GoogleFonts.jost(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                goldDivider(),
                const SizedBox(height: 8),

                // ── Password ──────────────────────────────────────
                TextFormField(
                  controller: passwordController,
                  obscureText: !_showPassword,
                  style: GoogleFonts.jost(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    hintStyle: GoogleFonts.jost(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.gold,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed:
                          () => setState(() => _showPassword = !_showPassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGold),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGold),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.gold,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator:
                      (val) =>
                          val == null || val.length < 6
                              ? 'Min 6 characters'
                              : null,
                ),

                const SizedBox(height: 16),

                // ── Confirm Password ──────────────────────────────
                TextFormField(
                  controller: confirmController,
                  obscureText: !_showConfirm,
                  style: GoogleFonts.jost(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    hintStyle: GoogleFonts.jost(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.gold,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirm ? Icons.visibility : Icons.visibility_off,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed:
                          () => setState(() => _showConfirm = !_showConfirm),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGold),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGold),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.gold,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator:
                      (val) =>
                          val != passwordController.text
                              ? 'Passwords do not match'
                              : null,
                ),

                const SizedBox(height: 24),

                // ── Link Button ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _linkAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.obsidian,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.obsidian,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              'LINK ACCOUNT',
                              style: GoogleFonts.jost(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
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
  }
}
