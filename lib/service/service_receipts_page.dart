import 'dart:convert';

import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ServiceReceiptsPage extends StatefulWidget {
  const ServiceReceiptsPage({super.key});

  @override
  State<ServiceReceiptsPage> createState() => _ServiceReceiptsPageState();
}

class _ServiceReceiptsPageState extends State<ServiceReceiptsPage> {
  final AuthService _authService = AuthService();

  // Separate lists for each tab — no FutureBuilder, full manual control
  List<Map<String, dynamic>> _confirmedReceipts = [];
  List<Map<String, dynamic>> _rejectedReceipts = [];
  bool _isLoadingConfirmed = true;
  bool _isLoadingRejected = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadReceipts('confirmed'), _loadReceipts('rejected')]);
  }

  Future<void> _loadReceipts(String status) async {
    if (status == 'confirmed') setState(() => _isLoadingConfirmed = true);
    if (status == 'rejected') setState(() => _isLoadingRejected = true);

    try {
      final currentUser = await _authService.getCurrentUser();
      final currentUserId =
          currentUser?['uid']?.toString() ??
          currentUser?['id']?.toString() ??
          currentUser?['_id']?.toString() ??
          currentUser?['userId']?.toString();

      if (currentUserId == null || currentUserId.isEmpty) {
        _setList(status, []);
        return;
      }

      final response = await http.get(
        Uri.parse(
          '${_authService.baseUrl}/service-receipts/service-center/${Uri.encodeComponent(currentUserId)}?status=${Uri.encodeComponent(status)}',
        ),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        _setList(
          status,
          decoded
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList(),
        );
      } else {
        _setList(status, []);
      }
    } catch (e) {
      _setList(status, []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading $status receipts: $e')),
        );
      }
    }
  }

  void _setList(String status, List<Map<String, dynamic>> data) {
    if (!mounted) return;
    setState(() {
      if (status == 'confirmed') {
        _confirmedReceipts = data;
        _isLoadingConfirmed = false;
      } else {
        _rejectedReceipts = data;
        _isLoadingRejected = false;
      }
    });
  }

  Future<void> _markAsFinished(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('${_authService.baseUrl}/service-receipts/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'finished'}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to update status: ${response.body}');
      }

      // Remove from local list immediately — no re-fetch needed
      setState(() {
        _confirmedReceipts.removeWhere((r) => r['_id']?.toString() == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Service marked as finished.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteReceipt(String id) async {
    // Confirm before delete
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Receipt"),
            content: const Text(
              "Are you sure you want to delete this rejected receipt?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('${_authService.baseUrl}/service-receipts/$id'),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to delete: ${response.body}');
      }

      // Remove from local list immediately
      setState(() {
        _rejectedReceipts.removeWhere((r) => r['_id']?.toString() == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🗑️ Rejected receipt deleted.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Service Receipts"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: "Refresh",
              onPressed: _loadAll,
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Confirmed"),
                    if (_confirmedReceipts.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_confirmedReceipts.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Rejected"),
                    if (_rejectedReceipts.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_rejectedReceipts.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildConfirmedList(), _buildRejectedList()],
        ),
      ),
    );
  }

  Widget _buildConfirmedList() {
    if (_isLoadingConfirmed) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_confirmedReceipts.isEmpty) {
      return const Center(child: Text("No confirmed receipts."));
    }

    return RefreshIndicator(
      onRefresh: () => _loadReceipts('confirmed'),
      child: ListView.builder(
        itemCount: _confirmedReceipts.length,
        itemBuilder: (context, index) {
          final receipt = _confirmedReceipts[index];
          final docId = receipt['_id']?.toString() ?? '';
          final services =
              (receipt['services'] as Map?)?.map(
                (key, value) => MapEntry(key.toString(), value),
              ) ??
              {};

          // Calculate total
          double total = 0;
          services.forEach((_, value) {
            total += double.tryParse(value.toString()) ?? 0;
          });

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            elevation: 3,
            child: ExpansionTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                radius: 14,
                child: Icon(Icons.check, color: Colors.white, size: 16),
              ),
              title: Text(
                "${receipt['vehicleNumber'] ?? '-'}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Mileage: ${receipt['currentMileage'] ?? '-'} km  •  ${receipt['createdAt']?.toString().split('T').first ?? '-'}",
              ),
              children: [
                _receiptInfoTile(
                  "Previous Oil Change",
                  receipt['previousOilChange'],
                ),
                _receiptInfoTile(
                  "Next Service Date",
                  receipt['nextServiceDate'],
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    "Services:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...services.entries.map(
                  (entry) => ListTile(
                    dense: true,
                    title: Text(entry.key),
                    trailing: Text(
                      "Rs. ${entry.value}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
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
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          docId.isEmpty ? null : () => _markAsFinished(docId),
                      icon: const Icon(Icons.done_all),
                      label: const Text("Mark as Finished"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRejectedList() {
    if (_isLoadingRejected) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_rejectedReceipts.isEmpty) {
      return const Center(child: Text("No rejected receipts."));
    }

    return RefreshIndicator(
      onRefresh: () => _loadReceipts('rejected'),
      child: ListView.builder(
        itemCount: _rejectedReceipts.length,
        itemBuilder: (context, index) {
          final receipt = _rejectedReceipts[index];
          final docId = receipt['_id']?.toString() ?? '';
          final services =
              (receipt['services'] as Map?)?.map(
                (key, value) => MapEntry(key.toString(), value),
              ) ??
              {};

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            elevation: 3,
            child: ExpansionTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                radius: 14,
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
              title: Text(
                "${receipt['vehicleNumber'] ?? '-'}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Mileage: ${receipt['currentMileage'] ?? '-'} km  •  ${receipt['createdAt']?.toString().split('T').first ?? '-'}",
              ),
              children: [
                _receiptInfoTile(
                  "Previous Oil Change",
                  receipt['previousOilChange'],
                ),
                _receiptInfoTile(
                  "Next Service Date",
                  receipt['nextServiceDate'],
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    "Services:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...services.entries.map(
                  (entry) => ListTile(
                    dense: true,
                    title: Text(entry.key),
                    trailing: Text("Rs. ${entry.value}"),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          docId.isEmpty ? null : () => _deleteReceipt(docId),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text("Delete Receipt"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _receiptInfoTile(String label, dynamic value) {
    return ListTile(
      dense: true,
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(value?.toString() ?? '-'),
    );
  }
}
