// lib/auth/google_profile_completion.dart
import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_service.dart';
import '../user/main_dashboard.dart';

class GoogleProfileCompletionPage extends StatefulWidget {
  final String uid;
  final String name;
  final String email;

  const GoogleProfileCompletionPage({
    required this.uid,
    required this.name,
    required this.email,
    super.key,
  });

  @override
  State<GoogleProfileCompletionPage> createState() =>
      _GoogleProfileCompletionPageState();
}

class _GoogleProfileCompletionPageState
    extends State<GoogleProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final addressController = TextEditingController();
  final contactController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirm = false;

  final _authService = AuthService();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    contactController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final existingUser = await _authService.getUserByUsername(
        usernameController.text.trim(),
      );
      if (existingUser != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text(
                'Username already taken.',
                style: GoogleFonts.jost(color: Colors.white),
              ),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      await _authService.createUser({
        'uid': widget.uid,
        'name': widget.name,
        'email': widget.email,
        'username': usernameController.text.trim(),
        'password': passwordController.text.trim(),
        'address': addressController.text.trim(),
        'contact': contactController.text.trim(),
        'userType': 'Vehicle Owner',
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Luxury text field ─────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isConfirm = false,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    final isObscure =
        isPassword
            ? !_showPassword
            : isConfirm
            ? !_showConfirm
            : false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        style: GoogleFonts.jost(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.jost(color: AppColors.textMuted, fontSize: 14),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          prefixIcon: Icon(icon, color: AppColors.gold, size: 20),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed:
                        () => setState(() => _showPassword = !_showPassword),
                  )
                  : isConfirm
                  ? IconButton(
                    icon: Icon(
                      _showConfirm ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed:
                        () => setState(() => _showConfirm = !_showConfirm),
                  )
                  : null,
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
            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
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
            validator ??
            (required
                ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
                : null),
      ),
    );
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
          'Complete Profile',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
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
                      const SizedBox(height: 16),
                      Text(
                        'Complete Your Profile',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Just a few more details to get started',
                        style: GoogleFonts.jost(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Google account info card ──────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGold),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.gold,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: GoogleFonts.jost(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              widget.email,
                              style: GoogleFonts.jost(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Google',
                          style: GoogleFonts.jost(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                goldDivider(),

                // ── Account Details ───────────────────────────────
                luxuryLabel('Account Details'),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: usernameController,
                  label: 'Username',
                  icon: Icons.alternate_email,
                ),
                _buildTextField(
                  controller: passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'This field is required';
                    }
                    if (val.length < 6) {
                      return 'Min 6 characters';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  controller: confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock_outline,
                  isConfirm: true,
                  validator:
                      (val) =>
                          val != passwordController.text
                              ? 'Passwords do not match'
                              : null,
                ),

                // ── Personal Details ──────────────────────────────
                luxuryLabel('Personal Details'),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: addressController,
                  label: 'Address',
                  icon: Icons.location_on_outlined,
                  required: false,
                ),
                _buildTextField(
                  controller: contactController,
                  label: 'Contact Number',
                  icon: Icons.phone_outlined,
                  required: false,
                ),

                const SizedBox(height: 8),

                // ── Submit Button ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitProfile,
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
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.obsidian,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              'COMPLETE PROFILE',
                              style: GoogleFonts.jost(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: AppColors.obsidian,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
