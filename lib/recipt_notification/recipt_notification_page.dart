import 'dart:async';
import 'dart:convert';

import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

bool _isRefreshing = false;

class ReceiptNotificationPage extends StatefulWidget {
  const ReceiptNotificationPage({super.key});

  @override
  State<ReceiptNotificationPage> createState() =>
      _ReceiptNotificationPageState();
}

class _ReceiptNotificationPageState extends State<ReceiptNotificationPage> {
  final AuthService _authService = AuthService();
  String? vehicleNumber;
  List<Map<String, dynamic>> _receipts = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _initializePage();
    });
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshSilently();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await _loadVehicleNumber();
    await _loadReceipts();
  }

  Tab _buildTabWithBadge(String label, int count) {
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
        ],
      ),
    );
  }

  Future<void> _loadVehicleNumber() async {
    final user = await _authService.getCurrentUser();
    final uid =
        user?['uid']?.toString() ??
        user?['id']?.toString() ??
        user?['_id']?.toString() ??
        user?['userId']?.toString();

    if (uid != null && uid.isNotEmpty) {
      final vehicleDoc = await _authService.getVehicleByUserId(uid);
      if (vehicleDoc != null) {
        setState(() {
          vehicleNumber =
              vehicleDoc['vehicleNumber']?.toString() ??
              vehicleDoc['plateNumber']?.toString();
        });
      }
    }
  }

  Future<void> _loadReceipts() async {
    if (vehicleNumber == null || vehicleNumber!.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _receipts = [];
        });
      }
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '${_authService.baseUrl}/service-receipts/vehicle/${Uri.encodeComponent(vehicleNumber!)}',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        if (mounted) {
          setState(() {
            _receipts =
                decoded
                    .map((item) => Map<String, dynamic>.from(item as Map))
                    .toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _receipts = [];
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _receipts = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshSilently() async {
    if (!mounted || _isRefreshing) return;
    _isRefreshing = true;
    await _loadReceipts();
    _isRefreshing = false;
  }

  Future<void> _updateStatus(String id, String status) async {
    final response = await http.patch(
      Uri.parse('${_authService.baseUrl}/service-receipts/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update receipt');
    }

    await _loadReceipts();
  }

  List<Map<String, dynamic>> _receiptsByStatus(String status) {
    return _receipts.where((r) => r['status'] == status).toList();
  }

  Map<String, int> _statusCounts() {
    final counts = {
      'not confirmed': 0,
      'confirmed': 0,
      'rejected': 0,
      'finished': 0,
    };

    for (final receipt in _receipts) {
      final String status = (receipt['status'] ?? '').toString();
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }

    return counts;
  }

  int _calculateTotal(Map<String, dynamic> services) {
    int total = 0;
    services.forEach((key, value) {
      try {
        total += int.tryParse(value.toString()) ?? 0;
      } catch (_) {}
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final counts = _statusCounts();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Receipt Notifications"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: TabBar(
              isScrollable: true,
              labelColor: Colors.amber,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.amber,
              tabs: [
                _buildTabWithBadge("Pending", counts['not confirmed']!),
                _buildTabWithBadge("Confirmed", counts['confirmed']!),
                _buildTabWithBadge("Rejected", counts['rejected']!),
                _buildTabWithBadge("Finished", counts['finished']!),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildReceiptList("not confirmed", true),
            _buildReceiptList("confirmed", false),
            _buildReceiptList("rejected", false),
            _buildReceiptList("finished", false),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptList(String status, bool showActions) {
    final receipts = _receiptsByStatus(status);

    if (receipts.isEmpty) {
      return Center(child: Text("No $status receipts found."));
    }

    return ListView.builder(
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final receipt = receipts[index];
        final receiptId = receipt['_id']?.toString() ?? '';
        final services =
            (receipt['services'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value),
            ) ??
            {};

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ExpansionTile(
            title: Text(
              "Receipt ${index + 1}: ${receipt['Service Center Name'] ?? '-'}",
            ),
            subtitle: Text("Mileage: ${receipt['currentMileage']}"),
            children: [
              ListTile(
                title: const Text("Previous Oil Change"),
                subtitle: Text(receipt['previousOilChange']?.toString() ?? '-'),
              ),
              ListTile(
                title: const Text("Next Service Date"),
                subtitle: Text(receipt['nextServiceDate']?.toString() ?? '-'),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Services:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...services.entries
                  .map(
                    (entry) => ListTile(
                      title: Text(entry.key),
                      trailing: Text("Rs. ${entry.value}"),
                    ),
                  )
                  .toList(),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      "Total: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Rs. ${_calculateTotal(Map<String, dynamic>.from(services))}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              if (showActions)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _updateStatus(receiptId, "confirmed");
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                            return;
                          }

                          if (mounted) {
                            Future.microtask(() {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Receipt confirmed."),
                                ),
                              );
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Confirm"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _updateStatus(receiptId, "rejected");
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                            return;
                          }

                          if (mounted) {
                            Future.microtask(() {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Receipt rejected."),
                                ),
                              );
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Reject"),
                      ),
                    ],
                  ),
                )
              else if (status == "finished")
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await _updateStatus(receiptId, "done");
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                        return;
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Marked as done.")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Done"),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
