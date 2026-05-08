// lib/service/service_receipts_page.dart
import 'dart:convert';

import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceReceiptsPage extends StatefulWidget {
  const ServiceReceiptsPage({super.key});

  @override
  State<ServiceReceiptsPage> createState() => _ServiceReceiptsPageState();
}

class _ServiceReceiptsPageState extends State<ServiceReceiptsPage> {
  final AuthService _authService = AuthService();

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

      setState(() {
        _confirmedReceipts.removeWhere((r) => r['_id']?.toString() == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              '✅ Service marked as finished.',
              style: GoogleFonts.jost(color: Colors.white),
            ),
          ),
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
              'Delete Receipt',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            content: Text(
              'Are you sure you want to delete this rejected receipt?',
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
        Uri.parse('${_authService.baseUrl}/service-receipts/$id'),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to delete: ${response.body}');
      }

      setState(() {
        _rejectedReceipts.removeWhere((r) => r['_id']?.toString() == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              '🗑️ Rejected receipt deleted.',
              style: GoogleFonts.jost(color: Colors.white),
            ),
          ),
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

  // ── Tab with badge ────────────────────────────────────────────────────────
  Widget _tabWithBadge(String label, int count, Color badgeColor) {
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
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.jost(
                  fontSize: 11,
                  color:
                      badgeColor == AppColors.gold
                          ? AppColors.obsidian
                          : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Reusable card wrapper with colored left strip ─────────────────────────
  Widget _buildCard({required Color stripColor, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGold),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.05),
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
              Container(width: 4, color: stripColor),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.richBlack,
        appBar: AppBar(
          backgroundColor: AppColors.obsidian,
          foregroundColor: AppColors.textPrimary,
          centerTitle: true,
          title: Text(
            'Service Receipts',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.gold),
              tooltip: 'Refresh',
              onPressed: _loadAll,
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.gold,
            indicatorWeight: 2,
            labelStyle: GoogleFonts.jost(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.jost(fontSize: 13),
            tabs: [
              _tabWithBadge(
                'Confirmed',
                _confirmedReceipts.length,
                AppColors.gold,
              ),
              _tabWithBadge(
                'Rejected',
                _rejectedReceipts.length,
                AppColors.error,
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

  // ── Confirmed list ────────────────────────────────────────────────────────
  Widget _buildConfirmedList() {
    if (_isLoadingConfirmed) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_confirmedReceipts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No confirmed receipts.',
              style: GoogleFonts.jost(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () => _loadReceipts('confirmed'),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _confirmedReceipts.length,
        itemBuilder: (context, index) {
          final receipt = _confirmedReceipts[index];
          final docId = receipt['_id']?.toString() ?? '';
          final services =
              (receipt['services'] as Map?)?.map(
                (key, value) => MapEntry(key.toString(), value),
              ) ??
              {};

          double total = 0;
          services.forEach((_, value) {
            total += double.tryParse(value.toString()) ?? 0;
          });

          return _buildCard(
            stripColor: AppColors.success,
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
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.success),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.success,
                    size: 16,
                  ),
                ),
                title: Text(
                  receipt['vehicleNumber'] ?? '-',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Mileage: ${receipt['currentMileage'] ?? '-'} km  •  ${receipt['createdAt']?.toString().split('T').first ?? '-'}',
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(
                          'Previous Oil Change',
                          receipt['previousOilChange'],
                        ),
                        const SizedBox(height: 8),
                        _infoRow(
                          'Next Service Date',
                          receipt['nextServiceDate'],
                        ),
                        const SizedBox(height: 16),
                        luxuryLabel('Services'),
                        const SizedBox(height: 8),
                        ...services.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: GoogleFonts.jost(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Rs. ${entry.value}',
                                  style: GoogleFonts.jost(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Total
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.gold.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL',
                                style: GoogleFonts.jost(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: AppColors.gold,
                                ),
                              ),
                              Text(
                                'Rs. ${total.toStringAsFixed(2)}',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                docId.isEmpty
                                    ? null
                                    : () => _markAsFinished(docId),
                            icon: const Icon(Icons.done_all, size: 16),
                            label: Text(
                              'Mark as Finished',
                              style: GoogleFonts.jost(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.obsidian,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
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

  // ── Rejected list ─────────────────────────────────────────────────────────
  Widget _buildRejectedList() {
    if (_isLoadingRejected) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_rejectedReceipts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No rejected receipts.',
              style: GoogleFonts.jost(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () => _loadReceipts('rejected'),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rejectedReceipts.length,
        itemBuilder: (context, index) {
          final receipt = _rejectedReceipts[index];
          final docId = receipt['_id']?.toString() ?? '';
          final services =
              (receipt['services'] as Map?)?.map(
                (key, value) => MapEntry(key.toString(), value),
              ) ??
              {};

          return _buildCard(
            stripColor: AppColors.error,
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
                  horizontal: 16,
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
                  receipt['vehicleNumber'] ?? '-',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Mileage: ${receipt['currentMileage'] ?? '-'} km  •  ${receipt['createdAt']?.toString().split('T').first ?? '-'}',
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(
                          'Previous Oil Change',
                          receipt['previousOilChange'],
                        ),
                        const SizedBox(height: 8),
                        _infoRow(
                          'Next Service Date',
                          receipt['nextServiceDate'],
                        ),
                        const SizedBox(height: 16),
                        luxuryLabel('Services'),
                        const SizedBox(height: 8),
                        ...services.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: GoogleFonts.jost(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Rs. ${entry.value}',
                                  style: GoogleFonts.jost(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                docId.isEmpty
                                    ? null
                                    : () => _deleteReceipt(docId),
                            icon: const Icon(Icons.delete_forever, size: 16),
                            label: Text(
                              'Delete Receipt',
                              style: GoogleFonts.jost(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
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

  // ── Info row ──────────────────────────────────────────────────────────────
  Widget _infoRow(String label, dynamic value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.jost(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value?.toString() ?? '-',
          style: GoogleFonts.jost(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
