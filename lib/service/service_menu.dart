import 'dart:convert';

import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/auth/signin.dart';
import 'package:dr_cars_fyp/service/service_receipts_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'records_screen.dart';
import 'package:dr_cars_fyp/appointments/appointments_screen.dart';
import 'add_vehicle.dart';

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: FutureBuilder<Map<String, dynamic>>(
          future: _loadHeaderData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                "Loading...",
                style: TextStyle(color: Colors.white),
              );
            }
            if (!snapshot.hasData) {
              return const Text(
                "Welcome",
                style: TextStyle(color: Colors.white),
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
                      "Welcome $name - Service Center",
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
                      icon: const Icon(Icons.receipt_long, color: Colors.white),
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
                SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  child: Image.asset('images/bg_removed_logo.png', height: 150),
                ),
                const SizedBox(height: 50),
                _buildMenuButton(
                  context,
                  text: "Add New",
                  subtext: "Add new vehicles and add services",
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
                  text: "Records",
                  subtext: "For quick view of services (For non users)",
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
                  text: "Appointments",
                  subtext: "Accept service appointments",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentsScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 100),
                ElevatedButton(
                  onPressed: () async {
                    await _authService.logout();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SignInScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    "Sign Out",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String text,
    required String subtext,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 300,
      height: 90,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(subtext, style: const TextStyle(fontSize: 12)),
          ],
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
