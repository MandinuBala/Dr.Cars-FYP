import 'dart:convert';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/service/service_menu.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class RecieptPage extends StatefulWidget {
  final String vehicleNumber;
  final String previousOilChange;
  final String currentMileage;
  final String nextServiceDate;
  final Map<String, bool> servicesSelected;

  const RecieptPage({
    super.key,
    required this.vehicleNumber,
    required this.previousOilChange,
    required this.currentMileage,
    required this.nextServiceDate,
    required this.servicesSelected,
  });

  @override
  _RecieptPageState createState() => _RecieptPageState();
}

class _RecieptPageState extends State<RecieptPage> {
  final AuthService _authService = AuthService();
  final Map<String, TextEditingController> _priceControllers = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    widget.servicesSelected.forEach((service, selected) {
      if (selected) {
        _priceControllers[service] = TextEditingController();
      }
    });
  }

  @override
  void dispose() {
    _priceControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _sendReceipt() async {
    setState(() => isLoading = true);
    final currentUser = await _authService.getCurrentUser();
    final uid =
        currentUser?['uid']?.toString() ??
        currentUser?['id']?.toString() ??
        currentUser?['_id']?.toString() ??
        currentUser?['userId']?.toString();

    Map<String, String> finalPrices = {};
    _priceControllers.forEach((service, controller) {
      finalPrices[service] = controller.text.trim();
    });

    if (uid == null || uid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Unable to identify current user.',
              style: GoogleFonts.jost(color: Colors.white),
            ),
          ),
        );
      }
      setState(() => isLoading = false);
      return;
    }

    final userDoc = await _authService.getUserById(uid);
    final serviceCenterName =
        userDoc?['Service Center Name']?.toString() ??
        userDoc?['serviceCenterName']?.toString() ??
        userDoc?['name']?.toString() ??
        'Unknown';

    final response = await http.post(
      Uri.parse('${_authService.baseUrl}/service-receipts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'vehicleNumber': widget.vehicleNumber,
        'previousOilChange': widget.previousOilChange,
        'currentMileage': widget.currentMileage,
        'nextServiceDate': widget.nextServiceDate,
        'services': finalPrices,
        'status': 'not confirmed',
        'createdAt': DateTime.now().toIso8601String(),
        'serviceCenterId': uid,
        'Service Center Name': serviceCenterName,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Error: ${response.body}',
              style: GoogleFonts.jost(color: Colors.white),
            ),
          ),
        );
      }
      setState(() => isLoading = false);
      return;
    }

    if (mounted) {
      setState(() => isLoading = false);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            'Receipt saved successfully.',
            style: GoogleFonts.jost(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total
    double total = 0;
    _priceControllers.forEach((_, controller) {
      total += double.tryParse(controller.text.trim()) ?? 0;
    });

    return Scaffold(
      backgroundColor: AppColors.richBlack,
      appBar: AppBar(
        backgroundColor: AppColors.obsidian,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        title: Text(
          'Receipt — ${widget.vehicleNumber}',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.gold),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: AppColors.gold),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Service Info ──────────────────────────────────────────────
            Text(
              'Service Summary',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            goldDivider(),

            // Info cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGold),
              ),
              child: Column(
                children: [
                  _infoRow(
                    'Vehicle',
                    widget.vehicleNumber,
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    'Previous Oil Change',
                    widget.previousOilChange.isEmpty
                        ? '-'
                        : widget.previousOilChange,
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    'Current Mileage',
                    '${widget.currentMileage} km',
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    'Next Service Date',
                    widget.nextServiceDate,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Services & Prices ─────────────────────────────────────────
            Text(
              'Services & Pricing',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            goldDivider(),

            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'SERVICE',
                      style: GoogleFonts.jost(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'PRICE (RS.)',
                      style: GoogleFonts.jost(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: AppColors.gold,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),

            Container(height: 1, color: AppColors.borderGold),
            const SizedBox(height: 8),

            // Service rows
            ...widget.servicesSelected.entries
                .where((entry) => entry.value)
                .map(
                  (entry) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderGold),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.key,
                            style: GoogleFonts.jost(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _priceControllers[entry.key],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.end,
                            style: GoogleFonts.jost(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: GoogleFonts.jost(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceElevated,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.borderGold),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.borderGold),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.gold, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),

            const SizedBox(height: 8),

            // ── Total ─────────────────────────────────────────────────────
            StatefulBuilder(
              builder: (context, setStateLocal) {
                double runningTotal = 0;
                _priceControllers.forEach((_, controller) {
                  runningTotal +=
                      double.tryParse(controller.text.trim()) ?? 0;
                });

                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.gold.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL',
                        style: GoogleFonts.jost(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: AppColors.gold,
                        ),
                      ),
                      Text(
                        'Rs. ${runningTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Send Button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _sendReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.obsidian,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.obsidian,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'SEND RECEIPT',
                        style: GoogleFonts.jost(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppColors.obsidian,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.jost(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jost(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}