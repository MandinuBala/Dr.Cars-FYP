// lib/recipt_notification/recipt_notification_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dr_cars_fyp/l10n/app_strings.dart';
import 'package:dr_cars_fyp/providers/locale_provider.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // ── Badge tab builder ─────────────────────────────────────────────────────
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
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.jost(
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
        if (mounted)
          setState(() {
            _receipts = [];
            _isLoading = false;
          });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _receipts = [];
          _isLoading = false;
        });
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

  List<Map<String, dynamic>> _receiptsByStatus(String status) =>
      _receipts.where((r) => r['status'] == status).toList();

  Map<String, int> _statusCounts() {
    final counts = {
      'not confirmed': 0,
      'confirmed': 0,
      'rejected': 0,
      'finished': 0,
    };
    for (final receipt in _receipts) {
      final String status = (receipt['status'] ?? '').toString();
      if (counts.containsKey(status)) counts[status] = counts[status]! + 1;
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
      return Scaffold(
        backgroundColor: AppColors.richBlack,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, lang, _) {
        final counts = _statusCounts();

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor: AppColors.richBlack,
            appBar: AppBar(
              backgroundColor: AppColors.obsidian,
              foregroundColor: AppColors.textPrimary,
              title: Text(
                AppStrings.get('receipt_notifications', lang),
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: TabBar(
                  isScrollable: true,
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
                    _buildTabWithBadge(
                      AppStrings.get('pending', lang),
                      counts['not confirmed']!,
                    ),
                    _buildTabWithBadge(
                      AppStrings.get('confirmed', lang),
                      counts['confirmed']!,
                    ),
                    _buildTabWithBadge(
                      AppStrings.get('rejected', lang),
                      counts['rejected']!,
                    ),
                    _buildTabWithBadge(
                      AppStrings.get('finished', lang),
                      counts['finished']!,
                    ),
                  ],
                ),
              ),
            ),
            body: TabBarView(
              children: [
                _buildReceiptList('not confirmed', true, lang),
                _buildReceiptList('confirmed', false, lang),
                _buildReceiptList('rejected', false, lang),
                _buildReceiptList('finished', false, lang),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptList(String status, bool showActions, String lang) {
    final receipts = _receiptsByStatus(status);

    if (receipts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              AppStrings.get('no_records', lang),
              style: GoogleFonts.jost(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final receipt = receipts[index];
        final receiptId = receipt['_id']?.toString() ?? '';
        final services =
            (receipt['services'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value),
            ) ??
            {};

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
              title: Text(
                '${AppStrings.get('service_records', lang)} ${index + 1}: ${receipt['Service Center Name'] ?? '-'}',
                style: GoogleFonts.jost(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                '${AppStrings.get('current_mileage', lang)}: ${receipt['currentMileage']}',
                style: GoogleFonts.jost(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              iconColor: AppColors.gold,
              collapsedIconColor: AppColors.textSecondary,
              children: [
                // Gold divider
                Container(height: 1, color: AppColors.borderGold),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(
                        AppStrings.get('previous_oil_change', lang),
                        receipt['previousOilChange']?.toString() ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        AppStrings.get('next_service_date', lang),
                        receipt['nextServiceDate']?.toString() ?? '-',
                      ),
                      const SizedBox(height: 16),

                      // Services label
                      luxuryLabel(AppStrings.get('services', lang)),
                      const SizedBox(height: 8),

                      ...services.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: GoogleFonts.jost(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
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

                      // Total row
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
                              AppStrings.get('total', lang).toUpperCase(),
                              style: GoogleFonts.jost(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: AppColors.gold,
                              ),
                            ),
                            Text(
                              'Rs. ${_calculateTotal(Map<String, dynamic>.from(services))}',
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

                      // Action buttons
                      if (showActions)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await _updateStatus(receiptId, 'confirmed');
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                    return;
                                  }
                                  if (mounted) {
                                    Future.microtask(() {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Receipt confirmed.'),
                                        ),
                                      );
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.gold,
                                  foregroundColor: AppColors.obsidian,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  AppStrings.get('confirm', lang),
                                  style: GoogleFonts.jost(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  try {
                                    await _updateStatus(receiptId, 'rejected');
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                    return;
                                  }
                                  if (mounted) {
                                    Future.microtask(() {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Receipt rejected.'),
                                        ),
                                      );
                                    });
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(
                                    color: AppColors.error,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  AppStrings.get('reject', lang),
                                  style: GoogleFonts.jost(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (status == 'finished')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await _updateStatus(receiptId, 'done');
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                                return;
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Marked as done.'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.obsidian,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              AppStrings.get('done', lang),
                              style: GoogleFonts.jost(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                fontSize: 13,
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
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.jost(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
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
