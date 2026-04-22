import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/user/main_dashboard.dart';
import 'package:dr_cars_fyp/service/service_menu.dart';
import 'package:dr_cars_fyp/auth/signup_selection.dart';
import 'package:dr_cars_fyp/auth/google_profile_completion.dart';
import 'package:dr_cars_fyp/admin/dashboard/admin_dashboard_page.dart';

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
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('images/bg_removed_logo.png', height: 100),
                const SizedBox(height: 20),
                const Text(
                  "Log in to Dr. Cars",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text("Enter your email or username to sign in"),
                const SizedBox(height: 20),

                // Email / Username
                TextFormField(
                  controller: _emailOrUsernameController,
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Please enter email or username'
                              : null,
                  decoration: InputDecoration(
                    hintText: "Email or Username",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  validator:
                      (v) =>
                          (v == null || v.isEmpty)
                              ? 'Password is required'
                              : null,
                  decoration: InputDecoration(
                    hintText: "Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed:
                          () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sign In Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Continue"),
                ),
                const SizedBox(height: 8),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child:
                      _isResettingPassword
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : TextButton(
                            onPressed: _handleResetPassword,
                            child: const Text("Forgot Password?"),
                          ),
                ),

                const SizedBox(height: 20),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "or",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                // Social Buttons
                _isSocialLoading
                    ? const CircularProgressIndicator()
                    : Column(
                      children: [
                        // Google Button
                        OutlinedButton.icon(
                          onPressed: _handleGoogleSignIn,
                          icon: const Icon(
                            Icons.g_mobiledata,
                            color: Colors.red,
                            size: 28,
                          ),
                          label: const Text("Continue with Google"),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Facebook Button
                        OutlinedButton.icon(
                          onPressed: _handleFacebookSignIn,
                          icon: const Icon(
                            Icons.facebook,
                            color: Color(0xFF1877F2),
                          ),
                          label: const Text("Continue with Facebook"),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SignupSelection()),
                      ),
                  child: const Text("Create an account"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
