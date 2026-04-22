import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'dart:convert';

class RejectedRequestsTab extends StatefulWidget {
  const RejectedRequestsTab({super.key});

  @override
  State<RejectedRequestsTab> createState() => _RejectedRequestsTabState();
}

class _RejectedRequestsTabState extends State<RejectedRequestsTab> {
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _requests = [];
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _fetchRejectedRequests();
  }

  Future<void> _fetchRejectedRequests() async {
    setState(() => _isFetching = true);
    try {
      final response = await http.get(
        Uri.parse(
          '${_authService.baseUrl}/service-center-requests?status=rejected',
        ),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _requests = data.cast<Map<String, dynamic>>();
        });
      } else {
        setState(() => _requests = []);
      }
    } catch (e) {
      setState(() => _requests = []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading rejected requests: $e')),
        );
      }
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _restoreRequest(String id) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${_authService.baseUrl}/service-center-requests/restore/$id',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _fetchRejectedRequests(); // Refresh
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Moved back to pending.")),
          );
        }
      } else {
        throw Exception('Failed with status ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error restoring request: $e')));
      }
    }
  }

  Future<void> _deleteRequest(String id) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Request"),
            content: const Text(
              "Are you sure you want to permanently delete this request? This cannot be undone.",
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
        Uri.parse('${_authService.baseUrl}/service-center-requests/$id'),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _fetchRejectedRequests(); // Refresh
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🗑️ Request deleted permanently.")),
          );
        }
      } else {
        throw Exception('Failed with status ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting request: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text(
              "No rejected requests.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchRejectedRequests,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${_requests.length} rejected request(s)",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchRejectedRequests,
                tooltip: "Refresh",
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _requests.length,
            itemBuilder: (context, index) {
              final data = _requests[index];
              final id = data["_id"]?.toString() ?? '';
              if (id.isEmpty) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 3,
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    radius: 14,
                    child: Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                  title: Text(
                    data["serviceCenterName"]?.toString() ?? "Unnamed",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Owner: ${data["ownerName"]?.toString() ?? "N/A"}",
                  ),
                  children: [
                    _infoTile(Icons.email, "Email", data["email"]),
                    _infoTile(Icons.person, "Username", data["username"]),
                    _infoTile(Icons.badge, "NIC", data["nic"]),
                    _infoTile(
                      Icons.description,
                      "Reg. Cert. No",
                      data["regNumber"],
                    ),
                    _infoTile(Icons.location_on, "Address", data["address"]),
                    _infoTile(Icons.phone, "Contact", data["contact"]),
                    _infoTile(Icons.location_city, "City", data["city"]),
                    _infoTile(Icons.notes, "Notes", data["notes"]),
                    const SizedBox(height: 8),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _restoreRequest(id),
                              icon: const Icon(
                                Icons.restore,
                                color: Colors.black,
                              ),
                              label: const Text(
                                "Restore to Pending",
                                style: TextStyle(color: Colors.black),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _deleteRequest(id),
                              icon: const Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                              ),
                              label: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String title, dynamic value) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.grey[600]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        value?.toString() ?? "N/A",
        style: const TextStyle(fontSize: 14, color: Colors.black),
      ),
      dense: true,
    );
  }
}
