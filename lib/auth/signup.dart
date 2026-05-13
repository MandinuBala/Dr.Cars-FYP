import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dr_cars_fyp/l10n/app_strings.dart';
import 'package:dr_cars_fyp/providers/locale_provider.dart';
import 'signin.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _role = 'Vehicle Owner';
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        role: _role,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              'Account created successfully!',
              style: GoogleFonts.jost(color: Colors.white),
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SignInScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Sign Up Failed: ${e.toString()}',
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
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_showPassword,
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
          focusedErrorBorder: OutlineInputBorder(
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
            (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            },
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
              AppStrings.get('signup_title', lang),
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
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // ── Logo ─────────────────────────────────────────
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
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Create Account',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Join DR. CARS today',
                      style: GoogleFonts.jost(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    goldDivider(),
                    const SizedBox(height: 8),

                    // ── Fields ────────────────────────────────────────
                    _buildTextField(
                      label: AppStrings.get('full_name', lang),
                      controller: _nameController,
                      icon: Icons.person_outline,
                    ),
                    _buildTextField(
                      label: AppStrings.get('email', lang),
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'This field is required';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      label: AppStrings.get('username', lang),
                      controller: _usernameController,
                      icon: Icons.alternate_email,
                    ),
                    _buildTextField(
                      label: AppStrings.get('password', lang),
                      controller: _passwordController,
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    // ── Role Dropdown ─────────────────────────────────
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderGold),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _role,
                        style: GoogleFonts.jost(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        dropdownColor: AppColors.surfaceElevated,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.gold,
                        ),
                        selectedItemBuilder:
                            (context) =>
                                ['Vehicle Owner', 'Service Center']
                                    .map(
                                      (item) => Text(
                                        item,
                                        style: GoogleFonts.jost(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                    .toList(),
                        decoration: InputDecoration(
                          labelText: AppStrings.get('create_account_as', lang),
                          labelStyle: GoogleFonts.jost(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          floatingLabelStyle: GoogleFonts.jost(
                            color: AppColors.gold,
                            fontSize: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
                            color: AppColors.gold,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'Vehicle Owner',
                            child: Text(
                              AppStrings.get('vehicle_owner', lang),
                              style: GoogleFonts.jost(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Service Center',
                            child: Text(
                              AppStrings.get('service_center', lang),
                              style: GoogleFonts.jost(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _role = value);
                        },
                      ),
                    ),

                    // ── Sign Up Button ────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
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
                                  AppStrings.get('sign_up', lang),
                                  style: GoogleFonts.jost(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                    color: AppColors.obsidian,
                                  ),
                                ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Already have account ──────────────────────────
                    TextButton(
                      onPressed:
                          () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => SignInScreen()),
                          ),
                      child: Text(
                        AppStrings.get('already_account', lang),
                        style: GoogleFonts.jost(
                          color: AppColors.gold,
                          fontSize: 13,
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
      },
    );
  }
}
