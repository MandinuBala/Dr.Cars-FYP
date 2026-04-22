import 'package:flutter/material.dart';
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

  final _authService = AuthService();

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Check if username is unique
      final existingUser =
          await _authService.getUserByUsername(usernameController.text.trim());
      if (existingUser != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Username taken")));
        setState(() => _isLoading = false);
        return;
      }

      // Save profile to DB
      await _authService.createUser({
        "uid": widget.uid,
        "name": widget.name,
        "email": widget.email,
        "username": usernameController.text.trim(),
        "password": passwordController.text.trim(),
        "address": addressController.text.trim(),
        "contact": contactController.text.trim(),
        "userType": "Vehicle Owner",
        "createdAt": DateTime.now().toIso8601String(),
      });

      // Redirect to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text("Complete Profile for ${widget.name} (${widget.email})"),
              const SizedBox(height: 20),
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: "Username"),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
                validator: (val) =>
                    val == null || val.length < 6 ? "Min 6 chars" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: "Confirm Password"),
                validator: (val) =>
                    val != passwordController.text ? "Passwords mismatch" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Address"),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: contactController,
                decoration: const InputDecoration(labelText: "Contact"),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Complete Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
