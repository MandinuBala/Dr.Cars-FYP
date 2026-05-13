// lib/service/service_info_screen.dart
import 'dart:convert';

import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Error loading records: $e',
              style: GoogleFonts.jost(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.richBlack,
      appBar: AppBar(
        backgroundColor: AppColors.obsidian,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.gold),
        title: Text(
          'History: ${widget.vehicleNumber}',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.gold),
            onPressed: _loadRecords,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
              : _records.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.history,
                      size: 56,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No finished service records found',
                      style: GoogleFonts.jost(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'for ${widget.vehicleNumber}',
                      style: GoogleFonts.jost(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                color: AppColors.gold,
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

                    double total = 0;
                    services.forEach((_, value) {
                      total += double.tryParse(value.toString()) ?? 0;
                    });

                    final createdAtText =
                        data['createdAt']?.toString().split('T').first ?? '-';

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
                              // ── Green left strip ──────────────────────
                              Container(width: 4, color: AppColors.success),

                              // ── Card content ──────────────────────────
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Service Date: $createdAtText',
                                            style: GoogleFonts.jost(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.success
                                                  .withOpacity(0.1),
                                              border: Border.all(
                                                color: AppColors.success,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'FINISHED',
                                              style: GoogleFonts.jost(
                                                color: AppColors.success,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      Container(
                                        height: 1,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        color: AppColors.borderGold,
                                      ),

                                      _infoRow(
                                        'Previous Oil Change',
                                        data['previousOilChange'],
                                      ),
                                      const SizedBox(height: 6),
                                      _infoRow(
                                        'Next Service Date',
                                        data['nextServiceDate'],
                                      ),
                                      const SizedBox(height: 6),
                                      _infoRow(
                                        'Current Mileage',
                                        '${data['currentMileage'] ?? '-'} km',
                                      ),

                                      const SizedBox(height: 16),
                                      luxuryLabel('Services Done'),
                                      const SizedBox(height: 8),

                                      ...services.entries.map(
                                        (entry) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '• ${entry.key}',
                                                  style: GoogleFonts.jost(
                                                    fontSize: 13,
                                                    color:
                                                        AppColors.textSecondary,
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
                                          color: AppColors.gold.withOpacity(
                                            0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: AppColors.gold.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
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
                                              style:
                                                  GoogleFonts.cormorantGaramond(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.gold,
                                                  ),
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
    );
  }

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
