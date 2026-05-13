// lib/admin/requests/rejected_requests_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
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
              'Error loading rejected requests: $e',
              style: GoogleFonts.jost(color: Colors.white),
            ),
          ),
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
        await _fetchRejectedRequests();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text(
                '✅ Moved back to pending.',
                style: GoogleFonts.jost(color: Colors.white),
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed with status ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Error restoring request: $e',
              style: GoogleFonts.jost(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteRequest(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.borderGold),
            ),
            title: Text(
              'Delete Request',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            content: Text(
              'Are you sure you want to permanently delete this request? This cannot be undone.',
              style: GoogleFonts.jost(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.jost(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Delete',
                  style: GoogleFonts.jost(fontWeight: FontWeight.w600),
                ),
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
        await _fetchRejectedRequests();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text(
                '🗑️ Request deleted permanently.',
                style: GoogleFonts.jost(color: Colors.white),
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed with status ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Error deleting request: $e',
              style: GoogleFonts.jost(color: Colors.white),
            ),
          ),
        );
      }
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
            const Icon(
              Icons.check_circle_outline,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No rejected requests.',
              style: GoogleFonts.jost(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _fetchRejectedRequests,
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
        // ── Header ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_requests.length} rejected request(s)',
                style: GoogleFonts.jost(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.gold),
                onPressed: _fetchRejectedRequests,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        // ── List ──────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _requests.length,
            itemBuilder: (context, index) {
              final data = _requests[index];
              final id = data['_id']?.toString() ?? '';
              if (id.isEmpty) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGold),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Red left strip ──────────────────────────
                        Container(width: 4, color: AppColors.error),

                        // ── Card content ────────────────────────────
                        Expanded(
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
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.error),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: AppColors.error,
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                data['serviceCenterName']?.toString() ??
                                    'Unnamed',
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
                                Container(
                                  height: 1,
                                  color: AppColors.borderGold,
                                ),
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

                                      // Action buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed:
                                                  () => _restoreRequest(id),
                                              icon: const Icon(
                                                Icons.restore,
                                                size: 16,
                                              ),
                                              label: Text(
                                                'Restore',
                                                style: GoogleFonts.jost(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.gold,
                                                foregroundColor:
                                                    AppColors.obsidian,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed:
                                                  () => _deleteRequest(id),
                                              icon: const Icon(
                                                Icons.delete_forever,
                                                size: 16,
                                              ),
                                              label: Text(
                                                'Delete',
                                                style: GoogleFonts.jost(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.error,
                                                side: const BorderSide(
                                                  color: AppColors.error,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
