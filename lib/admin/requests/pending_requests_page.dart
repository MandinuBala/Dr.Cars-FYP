import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'dart:convert';

class PendingRequestsTab extends StatefulWidget {
  const PendingRequestsTab({super.key});

  @override
  State<PendingRequestsTab> createState() => _PendingRequestsTabState();
}

class _PendingRequestsTabState extends State<PendingRequestsTab> {
  final AuthService _authService = AuthService();

  List<String> selectedRequestIds = [];
  bool isLoading = false;
  List<Map<String, dynamic>> _requests = [];
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  // ================= FETCH PENDING REQUESTS =================
  Future<void> _fetchPendingRequests() async {
    setState(() => _isFetching = true);
    try {
      final response = await http.get(
        Uri.parse(
          '${_authService.baseUrl}/service-center-requests?status=pending',
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading requests: $e')));
      }
    } finally {
      setState(() => _isFetching = false);
    }
  }

  // ================= ACCEPT =================
  Future<void> _acceptRequests() async {
    setState(() => isLoading = true);

    int successCount = 0;
    int failCount = 0;

    for (String requestId in selectedRequestIds) {
      try {
        final response = await http.post(
          Uri.parse(
            '${_authService.baseUrl}/service-center-requests/accept/$requestId',
          ),
          headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (_) {
        failCount++;
      }
    }

    setState(() {
      selectedRequestIds.clear();
      isLoading = false;
    });

    await _fetchPendingRequests(); // Refresh list

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failCount == 0
                ? "✅ Accepted $successCount request(s) successfully."
                : "⚠️ Accepted $successCount, failed $failCount.",
          ),
        ),
      );
    }
  }

  // ================= REJECT =================
  Future<void> _rejectRequests() async {
    setState(() => isLoading = true);

    int successCount = 0;
    int failCount = 0;

    for (String requestId in selectedRequestIds) {
      try {
        final response = await http.put(
          Uri.parse(
            '${_authService.baseUrl}/service-center-requests/reject/$requestId',
          ),
          headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (_) {
        failCount++;
      }
    }

    setState(() {
      selectedRequestIds.clear();
      isLoading = false;
    });

    await _fetchPendingRequests(); // Refresh list

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failCount == 0
                ? "❌ Rejected $successCount request(s)."
                : "⚠️ Rejected $successCount, failed $failCount.",
          ),
        ),
      );
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
            const Icon(Icons.inbox, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              "No pending requests.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchPendingRequests,
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
        // Refresh button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${_requests.length} pending request(s)",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchPendingRequests,
                tooltip: "Refresh",
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children:
                _requests.map((data) {
                  final docId = data["_id"]?.toString() ?? '';
                  if (docId.isEmpty) return const SizedBox.shrink();

                  final isSelected = selectedRequestIds.contains(docId);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 3,
                    child: ExpansionTile(
                      leading: Checkbox(
                        value: isSelected,
                        activeColor: Colors.black,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedRequestIds.add(docId);
                            } else {
                              selectedRequestIds.remove(docId);
                            }
                          });
                        },
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
                        _infoTile(
                          Icons.location_on,
                          "Address",
                          data["address"],
                        ),
                        _infoTile(Icons.phone, "Contact", data["contact"]),
                        _infoTile(Icons.location_city, "City", data["city"]),
                        _infoTile(Icons.notes, "Notes", data["notes"]),
                        const SizedBox(height: 8),

                        // Per-item quick action buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      isLoading
                                          ? null
                                          : () async {
                                            setState(() {
                                              if (!selectedRequestIds.contains(
                                                docId,
                                              )) {
                                                selectedRequestIds.add(docId);
                                              }
                                            });
                                            await _acceptRequests();
                                          },
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  ),
                                  label: const Text(
                                    "Accept",
                                    style: TextStyle(color: Colors.green),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.green),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      isLoading
                                          ? null
                                          : () async {
                                            setState(() {
                                              if (!selectedRequestIds.contains(
                                                docId,
                                              )) {
                                                selectedRequestIds.add(docId);
                                              }
                                            });
                                            await _rejectRequests();
                                          },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    "Reject",
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
                }).toList(),
          ),
        ),

        // Bulk action buttons (shown when multiple selected)
        if (selectedRequestIds.length > 1)
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "${selectedRequestIds.length} selected",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _acceptRequests,
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.check),
                  label: const Text("Accept All"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _rejectRequests,
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.close),
                  label: const Text("Reject All"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
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
