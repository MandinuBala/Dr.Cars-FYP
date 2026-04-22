import 'dart:convert';

import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ServiceInfoScreen extends StatefulWidget {
  final String vehicleNumber;

  const ServiceInfoScreen({super.key, required this.vehicleNumber});

  @override
  State<ServiceInfoScreen> createState() => _ServiceInfoScreenState();
}

class _ServiceInfoScreenState extends State<ServiceInfoScreen> {
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = await _authService.getCurrentUser();
      final serviceCenterUid =
          currentUser?['uid']?.toString() ??
          currentUser?['id']?.toString() ??
          currentUser?['_id']?.toString() ??
          currentUser?['userId']?.toString();

      if (serviceCenterUid == null || serviceCenterUid.isEmpty) {
        setState(() {
          _records = [];
          _isLoading = false;
        });
        return;
      }

      // FIX: was "done" — correct status is "finished"
      final response = await http.get(
        Uri.parse(
          '${_authService.baseUrl}/service-receipts/service-center/${Uri.encodeComponent(serviceCenterUid)}'
          '?vehicleNumber=${Uri.encodeComponent(widget.vehicleNumber)}&status=finished',
        ),
      );

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _records =
              list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _records = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _records = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading records: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("History: ${widget.vehicleNumber}"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecords,
            tooltip: "Refresh",
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _records.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, size: 60, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      "No finished service records found\nfor ${widget.vehicleNumber}.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadRecords,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final data = _records[index];
                    final services =
                        (data['services'] as Map?)?.map(
                          (key, value) => MapEntry(key.toString(), value),
                        ) ??
                        {};

                    // Calculate total price
                    double total = 0;
                    services.forEach((_, value) {
                      total += double.tryParse(value.toString()) ?? 0;
                    });

                    final createdAtText =
                        data['createdAt']?.toString().split('T').first ?? '-';

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Service Date: $createdAtText",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "Finished",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _infoRow(
                              "Previous Oil Change",
                              data['previousOilChange'],
                            ),
                            _infoRow(
                              "Next Service Date",
                              data['nextServiceDate'],
                            ),
                            _infoRow(
                              "Current Mileage",
                              "${data['currentMileage'] ?? '-'} km",
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Services Done:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            ...services.entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text("• ${entry.key}")),
                                    Text(
                                      "Rs. ${entry.value}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "Total: Rs. ${total.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
