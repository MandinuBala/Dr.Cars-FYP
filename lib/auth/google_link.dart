import 'package:flutter/material.dart';
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
  final _authService = AuthService();

  Future<void> _linkAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Check if email already exists
      final existingUser = await _authService.getUserByEmail(widget.email);
      if (existingUser != null) {
        // Update the user with password and link googleId
        await _authService.updateUser(widget.email, {
          "password": passwordController.text.trim(),
          "googleId": widget.googleId,
        });
      } else {
        // Create a new user if not exists
        await _authService.createUser({
          "email": widget.email,
          "password": passwordController.text.trim(),
          "googleId": widget.googleId,
          "userType": widget.userType,
          "createdAt": DateTime.now().toIso8601String(),
        });
      }

      // Redirect to dashboard
      Widget screen;
      if (widget.userType == "Vehicle Owner") {
        screen = DashboardScreen();
      } else if (widget.userType == "Service Center") {
        screen = HomeScreen();
      } else {
        screen = ServiceCenterApprovalPage();
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => screen),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Link Google Account")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Enter a password to link with Google"),
              const SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Password"),
                validator: (val) =>
                    val == null || val.length < 6 ? "Min 6 chars" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: "Confirm Password"),
                validator: (val) =>
                    val != passwordController.text ? "Passwords mismatch" : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : _linkAccount,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Link Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
