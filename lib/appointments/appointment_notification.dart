import 'dart:async';
import 'dart:convert';

import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AppointmentNotificationPage extends StatefulWidget {
  const AppointmentNotificationPage({super.key});

  @override
  State<AppointmentNotificationPage> createState() =>
      _AppointmentNotificationPageState();
}

class _AppointmentNotificationPageState
    extends State<AppointmentNotificationPage> {
  final AuthService _authService = AuthService();
  String? vehicleNumber;
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initializePage();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshAppointmentsSilently();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await _loadVehicleNumber();
    await _fetchAppointments();
  }

  Future<void> _loadVehicleNumber() async {
    final currentUser = await _authService.getCurrentUser();
    final uid =
        currentUser?['uid']?.toString() ??
        currentUser?['id']?.toString() ??
        currentUser?['_id']?.toString() ??
        currentUser?['userId']?.toString();

    if (uid == null || uid.isEmpty) {
      return;
    }

    try {
      final vehicle = await _authService.getVehicleByUserId(uid);
      if (vehicle != null && mounted) {
        setState(() {
          vehicleNumber =
              vehicle['vehicleNumber']?.toString() ??
              vehicle['plateNumber']?.toString();
        });
      }
    } catch (_) {
      // Keep behavior silent and show empty state if lookup fails.
    }
  }

  Future<void> _fetchAppointments() async {
    if (vehicleNumber == null || vehicleNumber!.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _appointments = [];
        });
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '${_authService.baseUrl}/appointments/vehicle/${Uri.encodeComponent(vehicleNumber!)}',
        ),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        if (mounted) {
          setState(() {
            _appointments =
                decoded
                    .map((item) => Map<String, dynamic>.from(item as Map))
                    .toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _appointments = [];
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _appointments = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshAppointmentsSilently() async {
    if (!mounted || vehicleNumber == null || vehicleNumber!.isEmpty) {
      return;
    }
    await _fetchAppointments();
  }

  int _countByStatus(String status) {
    return _appointments.where((a) => a['status'] == status).length;
  }

  List<Map<String, dynamic>> _appointmentsByStatus(String status) {
    return _appointments.where((a) => a['status'] == status).toList();
  }

  Future<Map<String, dynamic>?> _getUserById(String id) async {
    if (id.isEmpty) return null;

    try {
      final response = await http.get(
        Uri.parse('${_authService.baseUrl}/users/${Uri.encodeComponent(id)}'),
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      }
    } catch (_) {
      // Keep UI fallback value on errors.
    }
    return null;
  }

  Future<void> _deleteAppointment(String id) async {
    if (id.isEmpty) return;

    final response = await http.delete(
      Uri.parse('${_authService.baseUrl}/appointments/$id'),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await _fetchAppointments();
      return;
    }

    throw Exception('Failed to delete appointment');
  }

  Future<void> _updateAppointmentStatus(String id, String status) async {
    if (id.isEmpty) return;

    final response = await http.patch(
      Uri.parse('${_authService.baseUrl}/appointments/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await _fetchAppointments();
      return;
    }

    throw Exception('Failed to update appointment');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Appointment Notifications"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: TabBar(
              tabs: [
                _tabLabel("Pending", _countByStatus('pending')),
                _tabLabel("Accepted", _countByStatus('accepted')),
                _tabLabel("Rejected", _countByStatus('rejected')),
              ],
              labelColor: Colors.amber,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.amber,
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildAppointmentList("pending"),
            _buildAppointmentList("accepted"),
            _buildAppointmentList("rejected"),
          ],
        ),
      ),
    );
  }

  Widget _tabLabel(String label, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (count > 0)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(String status) {
    final appointments = _appointmentsByStatus(status);

    if (appointments.isEmpty) {
      return const Center(child: Text('No appointments found.'));
    }

    return ListView.builder(
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        final docId = appointment['_id']?.toString() ?? '';
        final serviceCenterUid =
            appointment['serviceCenterUid']?.toString() ?? '';

        return FutureBuilder<Map<String, dynamic>?>(
          future: _getUserById(serviceCenterUid),
          builder: (context, snapshot) {
            String serviceCenterName = 'Loading...';
            if (snapshot.connectionState == ConnectionState.done) {
              final userData = snapshot.data;
              serviceCenterName =
                  userData?['Service Center Name']?.toString() ??
                  userData?['serviceCenterName']?.toString() ??
                  userData?['name']?.toString() ??
                  'Unknown';
            }

            final serviceTypes = appointment['serviceTypes'];
            final servicesText =
                serviceTypes is List
                    ? serviceTypes.map((e) => e.toString()).join(', ')
                    : '-';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Appointment ${index + 1}: $serviceCenterName"),
                    Text("Model: ${appointment['vehicleModel'] ?? '-'}"),
                    Text(
                      "Date: ${appointment['date']?.toString().split('T').first ?? '-'}",
                    ),
                    Text("Time: ${appointment['time'] ?? '-'}"),
                    Text("Status: ${appointment['status'] ?? '-'}"),
                    const SizedBox(height: 6),
                    Text("Services: $servicesText"),
                    const SizedBox(height: 12),
                    if (status == 'pending') ...[
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _deleteAppointment(docId);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Cancel"),
                      ),
                    ] else if (status == 'accepted') ...[
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _deleteAppointment(docId);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Handed Over Vehicle"),
                      ),
                    ] else if (status == 'rejected') ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await _updateAppointmentStatus(
                                    docId,
                                    'pending',
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Resend Appointment"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await _deleteAppointment(docId);
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Delete"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
