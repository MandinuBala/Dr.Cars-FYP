// lib/admin/requests/pending_requests_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
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
        setState(() => _requests = data.cast<Map<String, dynamic>>());
      } else {
        setState(() => _requests = []);
      }
    } catch (e) {
      setState(() => _requests = []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Error loading requests: $e',
              style: GoogleFonts.jost(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isFetching = false);
    }
  }

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

    await _fetchPendingRequests();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              failCount == 0 ? AppColors.success : AppColors.warning,
          content: Text(
            failCount == 0
                ? '✅ Accepted $successCount request(s) successfully.'
                : '⚠️ Accepted $successCount, failed $failCount.',
            style: GoogleFonts.jost(color: Colors.white),
          ),
        ),
      );
    }
  }

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

    await _fetchPendingRequests();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              failCount == 0 ? AppColors.success : AppColors.warning,
          content: Text(
            failCount == 0
                ? '❌ Rejected $successCount request(s).'
                : '⚠️ Rejected $successCount, failed $failCount.',
            style: GoogleFonts.jost(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No pending requests.',
              style: GoogleFonts.jost(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _fetchPendingRequests,
              icon: const Icon(Icons.refresh, color: AppColors.gold),
              label: Text(
                'Refresh',
                style: GoogleFonts.jost(color: AppColors.gold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.gold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── Header row ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_requests.length} pending request(s)',
                style: GoogleFonts.jost(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.gold),
                onPressed: _fetchPendingRequests,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        // ── Request list ────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children:
                _requests.map((data) {
                  final docId = data['_id']?.toString() ?? '';
                  if (docId.isEmpty) return const SizedBox.shrink();
                  final isSelected = selectedRequestIds.contains(docId);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.gold : AppColors.borderGold,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(
                            isSelected ? 0.1 : 0.03,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        expansionTileTheme: const ExpansionTileThemeData(
                          backgroundColor: AppColors.surfaceDark,
                          collapsedBackgroundColor: AppColors.surfaceDark,
                        ),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: Checkbox(
                          value: isSelected,
                          activeColor: AppColors.gold,
                          checkColor: AppColors.obsidian,
                          side: const BorderSide(color: AppColors.textMuted),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
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
                          data['serviceCenterName']?.toString() ?? 'Unnamed',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Owner: ${data['ownerName']?.toString() ?? 'N/A'}',
                          style: GoogleFonts.jost(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        iconColor: AppColors.gold,
                        collapsedIconColor: AppColors.textSecondary,
                        children: [
                          Container(height: 1, color: AppColors.borderGold),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _infoTile(
                                  Icons.email_outlined,
                                  'Email',
                                  data['email'],
                                ),
                                _infoTile(
                                  Icons.person_outline,
                                  'Username',
                                  data['username'],
                                ),
                                _infoTile(
                                  Icons.badge_outlined,
                                  'NIC',
                                  data['nic'],
                                ),
                                _infoTile(
                                  Icons.description_outlined,
                                  'Reg. Cert. No',
                                  data['regNumber'],
                                ),
                                _infoTile(
                                  Icons.location_on_outlined,
                                  'Address',
                                  data['address'],
                                ),
                                _infoTile(
                                  Icons.phone_outlined,
                                  'Contact',
                                  data['contact'],
                                ),
                                _infoTile(
                                  Icons.location_city_outlined,
                                  'City',
                                  data['city'],
                                ),
                                _infoTile(
                                  Icons.notes_outlined,
                                  'Notes',
                                  data['notes'],
                                ),
                                const SizedBox(height: 12),

                                // Per-item action buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            isLoading
                                                ? null
                                                : () async {
                                                  setState(() {
                                                    if (!selectedRequestIds
                                                        .contains(docId)) {
                                                      selectedRequestIds.add(
                                                        docId,
                                                      );
                                                    }
                                                  });
                                                  await _acceptRequests();
                                                },
                                        icon: const Icon(Icons.check, size: 16),
                                        label: Text(
                                          'Accept',
                                          style: GoogleFonts.jost(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.gold,
                                          foregroundColor: AppColors.obsidian,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed:
                                            isLoading
                                                ? null
                                                : () async {
                                                  setState(() {
                                                    if (!selectedRequestIds
                                                        .contains(docId)) {
                                                      selectedRequestIds.add(
                                                        docId,
                                                      );
                                                    }
                                                  });
                                                  await _rejectRequests();
                                                },
                                        icon: const Icon(Icons.close, size: 16),
                                        label: Text(
                                          'Reject',
                                          style: GoogleFonts.jost(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: const BorderSide(
                                            color: AppColors.error,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),

        // ── Bulk action bar ─────────────────────────────────────────────
        if (selectedRequestIds.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              border: const Border(
                top: BorderSide(color: AppColors.borderGold),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${selectedRequestIds.length} selected',
                    style: GoogleFonts.jost(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _acceptRequests,
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: AppColors.obsidian,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.check, size: 16),
                  label: Text(
                    'Accept All',
                    style: GoogleFonts.jost(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.obsidian,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _rejectRequests,
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: AppColors.error,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.close, size: 16),
                  label: Text(
                    'Reject All',
                    style: GoogleFonts.jost(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.gold),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.jost(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value?.toString() ?? 'N/A',
                style: GoogleFonts.jost(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
