import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/user/main_dashboard.dart';
import 'package:dr_cars_fyp/service/service_menu.dart';
import 'package:dr_cars_fyp/auth/signup_selection.dart';
import 'package:dr_cars_fyp/auth/google_profile_completion.dart';
import 'package:dr_cars_fyp/admin/dashboard/admin_dashboard_page.dart';
import 'package:dr_cars_fyp/l10n/app_strings.dart';
import 'package:dr_cars_fyp/providers/locale_provider.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _showPassword = false;
  bool _isLoading = false;
  bool _isResettingPassword = false;
  bool _isSocialLoading = false;

  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '158386662597-mdtkekcjemn21no9a0micgillvlet4pe.apps.googleusercontent.com',
  );

  void _navigateByRole(Map<String, dynamic> user) {
    final role = user['userType']?.toString();
    Widget screen;
    if (role == "Vehicle Owner") {
      screen = DashboardScreen();
    } else if (role == "Service Center") {
      screen = HomeScreen();
    } else if (role == "App Admin") {
      screen = ServiceCenterApprovalPage();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unauthorized user role.")));
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await _authService.login(
        _emailOrUsernameController.text.trim(),
        _passwordController.text.trim(),
      );
      _navigateByRole(result);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login Failed: ${e.toString()}")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleGoogleSignIn() async {
    setState(() => _isSocialLoading = true);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return;

      final result = await _authService.googleLogin(
        googleId: account.id,
        email: account.email,
        name: account.displayName ?? '',
        photoUrl: account.photoUrl,
      );

      final user = result['user'] ?? result;

      if (result['isNewUser'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => GoogleProfileCompletionPage(
                  uid: user['_id']?.toString() ?? account.id,
                  name: account.displayName ?? '',
                  email: account.email,
                ),
          ),
        );
      } else {
        _navigateByRole(Map<String, dynamic>.from(user));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google Sign-In failed: $e")));
    } finally {
      setState(() => _isSocialLoading = false);
    }
  }

  void _handleFacebookSignIn() async {
    setState(() => _isSocialLoading = true);
    try {
      final loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (loginResult.status != LoginStatus.success) {
        throw Exception("Facebook login cancelled or failed");
      }

      final userData = await FacebookAuth.instance.getUserData(
        fields: "name,email,picture",
      );

      final facebookId = userData['id']?.toString() ?? '';
      final email = userData['email']?.toString() ?? '';
      final name = userData['name']?.toString() ?? '';
      final photoUrl = userData['picture']?['data']?['url']?.toString();

      if (email.isEmpty) {
        throw Exception(
          "Could not retrieve email from Facebook. Please check your Facebook privacy settings.",
        );
      }

      final result = await _authService.facebookLogin(
        facebookId: facebookId,
        email: email,
        name: name,
        photoUrl: photoUrl,
      );

      final user = result['user'] ?? result;

      if (result['isNewUser'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => GoogleProfileCompletionPage(
                  uid: user['_id']?.toString() ?? facebookId,
                  name: name,
                  email: email,
                ),
          ),
        );
      } else {
        _navigateByRole(Map<String, dynamic>.from(user));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Facebook Sign-In failed: $e")));
    } finally {
      setState(() => _isSocialLoading = false);
    }
  }

  void _handleResetPassword() async {
    final input = _emailOrUsernameController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter your email or username")),
      );
      return;
    }
    setState(() => _isResettingPassword = true);
    try {
      await _authService.resetPassword(input);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Password reset link sent")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Reset failed: ${e.toString()}")));
    } finally {
      setState(() => _isResettingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.richBlack,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // Logo
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
                        height: 90,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      AppStrings.get('login_title', lang),
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.get('login_sub', lang),
                      style: GoogleFonts.jost(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

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

                    const SizedBox(height: 24),

                    // Email field
                    TextFormField(
                      controller: _emailOrUsernameController,
                      style: GoogleFonts.jost(color: AppColors.textPrimary),
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? AppStrings.get('email_username', lang)
                                  : null,
                      decoration: InputDecoration(
                        hintText: AppStrings.get('email_username', lang),
                        fillColor: AppColors.surfaceElevated,
                        filled: true,
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: AppColors.gold,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: GoogleFonts.jost(color: AppColors.textPrimary),
                      validator:
                          (v) =>
                              (v == null || v.isEmpty)
                                  ? AppStrings.get('password', lang)
                                  : null,
                      decoration: InputDecoration(
                        hintText: AppStrings.get('password', lang),
                        fillColor: AppColors.surfaceElevated, 
                        filled: true,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.gold,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed:
                              () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignIn,
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
                    const SizedBox(height: 8),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child:
                          _isResettingPassword
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : TextButton(
                                onPressed: _handleResetPassword,
                                child: Text(
                                  AppStrings.get('forgot_password', lang),
                                ),
                              ),
                    ),

                    const SizedBox(height: 16),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: GoogleFonts.jost(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Social Buttons
                    _isSocialLoading
                        ? const CircularProgressIndicator(color: AppColors.gold)
                        : Column(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _handleGoogleSignIn,
                              icon: const Icon(
                                Icons.g_mobiledata,
                                color: Colors.red,
                                size: 28,
                              ),
                              label: Text(
                                AppStrings.get('google_signin', lang),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _handleFacebookSignIn,
                              icon: const Icon(
                                Icons.facebook,
                                color: Color(0xFF1877F2),
                              ),
                              label: Text(
                                AppStrings.get('facebook_signin', lang),
                              ),
                            ),
                          ],
                        ),

                    const SizedBox(height: 20),
                    TextButton(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SignupSelection(),
                            ),
                          ),
                      child: Text(AppStrings.get('create_account', lang)),
                    ),
                    const SizedBox(height: 32),
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
