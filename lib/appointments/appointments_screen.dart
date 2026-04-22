import 'dart:async';
import 'dart:convert';

import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();

  String? serviceCenterUid;
  DateTime? selectedDate;

  // Separate lists per tab
  List<Map<String, dynamic>> _pendingAppointments = [];
  List<Map<String, dynamic>> _acceptedAppointments = [];
  List<Map<String, dynamic>> _rejectedAppointments = [];

  bool _isLoading = true;
  Timer? _pollingTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initialize();
    // Poll every 15 seconds to catch new appointments
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchAllSilently();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadUser();
    await _fetchAll();
  }

  Future<void> _loadUser() async {
    final currentUser = await _authService.getCurrentUser();
    final uid =
        currentUser?['uid']?.toString() ??
        currentUser?['id']?.toString() ??
        currentUser?['_id']?.toString() ??
        currentUser?['userId']?.toString();

    if (uid != null && uid.isNotEmpty && mounted) {
      setState(() => serviceCenterUid = uid);
    }
  }

  Future<void> _fetchAll() async {
    if (serviceCenterUid == null || serviceCenterUid!.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    await Future.wait([
      _fetchByStatus('pending'),
      _fetchByStatus('accepted'),
      _fetchByStatus('rejected'),
    ]);

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchAllSilently() async {
    if (!mounted || serviceCenterUid == null) return;
    await Future.wait([
      _fetchByStatus('pending'),
      _fetchByStatus('accepted'),
      _fetchByStatus('rejected'),
    ]);
  }

  Future<void> _fetchByStatus(String status) async {
    final uid = serviceCenterUid;
    if (uid == null || uid.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse(
          '${_authService.baseUrl}/appointments/service-center/${Uri.encodeComponent(uid)}?status=$status',
        ),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        final fetched =
            decoded
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();

        // Sort by date ascending
        fetched.sort((a, b) {
          final aDate = _parseDateTime(a['date'] ?? a['createdAt']);
          final bDate = _parseDateTime(b['date'] ?? b['createdAt']);
          return aDate.compareTo(bDate);
        });

        if (mounted) {
          setState(() {
            if (status == 'pending') _pendingAppointments = fetched;
            if (status == 'accepted') _acceptedAppointments = fetched;
            if (status == 'rejected') _rejectedAppointments = fetched;
          });
        }
      }
    } catch (_) {
      // Silent fail — keep existing list
    }
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime(2000);
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime(2000);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is Map && value['\$date'] != null) {
      return DateTime.tryParse(value['\$date'].toString()) ?? DateTime(2000);
    }
    return DateTime.tryParse(value.toString()) ?? DateTime(2000);
  }

  Future<void> _updateStatus(String appointmentId, String newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('${_authService.baseUrl}/appointments/$appointmentId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _fetchAll(); // Refresh all tabs
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus == 'accepted'
                    ? "✅ Appointment accepted."
                    : "❌ Appointment rejected.",
              ),
              backgroundColor:
                  newStatus == 'accepted' ? Colors.green : Colors.red,
            ),
          );
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue is String) return dateValue.split('T').first;
    if (dateValue is DateTime)
      return dateValue.toIso8601String().split('T').first;
    return '-';
  }

  List<Map<String, dynamic>> _applyDateFilter(List<Map<String, dynamic>> list) {
    if (selectedDate == null) return list;
    return list.where((data) {
      final docDate = _parseDateTime(data['date']);
      return docDate.year == selectedDate!.year &&
          docDate.month == selectedDate!.month &&
          docDate.day == selectedDate!.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Appointments",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Date filter
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: "Filter by date",
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => selectedDate = picked);
              }
            },
          ),
          if (selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: "Clear date filter",
              onPressed: () => setState(() => selectedDate = null),
            ),
          // Manual refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: _fetchAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: [
            _tabLabel("Pending", _pendingAppointments.length),
            _tabLabel("Accepted", _acceptedAppointments.length),
            _tabLabel("Rejected", _rejectedAppointments.length),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildAppointmentList(
                    _applyDateFilter(_pendingAppointments),
                    'pending',
                  ),
                  _buildAppointmentList(
                    _applyDateFilter(_acceptedAppointments),
                    'accepted',
                  ),
                  _buildAppointmentList(
                    _applyDateFilter(_rejectedAppointments),
                    'rejected',
                  ),
                ],
              ),
    );
  }

  Widget _tabLabel(String label, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    label == 'Pending'
                        ? Colors.amber
                        : label == 'Accepted'
                        ? Colors.green
                        : Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentList(
    List<Map<String, dynamic>> appointments,
    String status,
  ) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'pending'
                  ? Icons.hourglass_empty
                  : status == 'accepted'
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              "No $status appointments${selectedDate != null ? ' on this date' : ''}.",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final data = appointments[index];
          final appointmentId = data['_id']?.toString() ?? '';
          final serviceTypes = data['serviceTypes'];
          final serviceTypesText =
              serviceTypes is List
                  ? serviceTypes.map((item) => item.toString()).join(', ')
                  : '-';

          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data['vehicleNumber'] ?? '-',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _statusBadge(status),
                    ],
                  ),
                  const Divider(height: 16),

                  _infoRow(Icons.directions_car, "Model", data['vehicleModel']),
                  _infoRow(
                    Icons.calendar_today,
                    "Date",
                    _formatDate(data['date']),
                  ),
                  _infoRow(Icons.access_time, "Time", data['time']),
                  _infoRow(Icons.phone, "Contact", data['Contact']),
                  _infoRow(Icons.build, "Services", serviceTypesText),

                  const SizedBox(height: 12),

                  // Action buttons based on status
                  if (status == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                appointmentId.isEmpty
                                    ? null
                                    : () => _updateStatus(
                                      appointmentId,
                                      'accepted',
                                    ),
                            icon: const Icon(Icons.check),
                            label: const Text("Accept"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                appointmentId.isEmpty
                                    ? null
                                    : () => _updateStatus(
                                      appointmentId,
                                      'rejected',
                                    ),
                            icon: const Icon(Icons.close),
                            label: const Text("Reject"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (status == 'accepted')
                    // Info only — no more actions needed
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Customer has been notified.",
                            style: TextStyle(color: Colors.green, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else if (status == 'rejected')
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text(
                            "Customer has been notified of rejection.",
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    if (status == 'accepted') {
      color = Colors.green;
      label = "Accepted";
    } else if (status == 'rejected') {
      color = Colors.red;
      label = "Rejected";
    } else {
      color = Colors.orange;
      label = "Pending";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '-',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
