import 'package:dr_cars_fyp/admin/requests/pending_requests_page.dart';
import 'package:dr_cars_fyp/admin/requests/rejected_requests_page.dart';
import 'package:dr_cars_fyp/auth/signin.dart';
import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/auth/auth_service.dart';

class ServiceCenterApprovalPage extends StatefulWidget {
  const ServiceCenterApprovalPage({super.key});

  @override
  State<ServiceCenterApprovalPage> createState() =>
      _ServiceCenterApprovalPageState();
}

class _ServiceCenterApprovalPageState extends State<ServiceCenterApprovalPage> {
  final AuthService _authService = AuthService();
  late final Future<Map<String, dynamic>?> _currentUserFuture;

  @override
  void initState() {
    super.initState();
    _currentUserFuture = _authService.getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _currentUserFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        final role =
            user?['userType']?.toString() ?? user?['User Type']?.toString();

        if (role != 'App Admin') {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Access Denied'),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Only the App Admin account can access this page.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await _authService.logout();
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignInScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Back to Sign In'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text("Service Center Requests"),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  onPressed: () async {
                    await _authService.logout();
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SignInScreen()),
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Sign Out',
                ),
              ],
              bottom: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.grey,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                tabs: [Tab(text: 'Pending'), Tab(text: 'Rejected')],
              ),
            ),
            body: const TabBarView(
              children: [PendingRequestsTab(), RejectedRequestsTab()],
            ),
          ),
        );
      },
    );
  }
}
