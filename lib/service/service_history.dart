import 'dart:convert';

import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/obd/OBD2.dart';
import 'package:dr_cars_fyp/user/main_dashboard.dart';
import 'package:dr_cars_fyp/map/mapscreen.dart';
import 'package:dr_cars_fyp/user/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dr_cars_fyp/l10n/app_strings.dart';
import 'package:dr_cars_fyp/providers/locale_provider.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dr_cars_fyp/widgets/app_bottom_nav.dart';

class ServiceHistorypage extends StatefulWidget {
  const ServiceHistorypage({super.key});

  @override
  State<ServiceHistorypage> createState() => _ServiceHistorypageState();
}

class _ServiceHistorypageState extends State<ServiceHistorypage> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFilter;
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _serviceRecords = [];
  bool _isLoading = true;
  int _selectedIndex = 3;

  final List<String> _serviceTypes = [
    'Full Service',
    'Oil Filter Change',
    'Tire pressure and rotation check',
    'Fluid level check',
    'Battery check and replacements',
    'Wiper blade replacement',
    'Light bulb check',
    'Brake system services',
    'Suspension and alignment services',
    'Exhaust system service',
    'Air conditioning services',
    'Electrical system services',
    'Car detailing (Interior and exterior cleaning, waxing)',
    'Tire sales and installation',
    'Pre-purchase inspections',
    'Diagnostic testing',
  ];
  static const Map<String, Map<String, String>> _serviceTypeTranslations = {
    'Full Service': {'si': 'සම්පූර්ණ සේවාව', 'ta': 'முழு சேவை'},
    'Oil Filter Change': {
      'si': 'තෙල් පෙරහන් මාරුව',
      'ta': 'எண்ணெய் வடிகட்டி மாற்றம்',
    },
    'Tire pressure and rotation check': {
      'si': 'ටයර් පීඩන පරීක්ෂාව',
      'ta': 'டயர் அழுத்த சோதனை',
    },
    'Fluid level check': {'si': 'තරල මට්ටම් පරීක්ෂාව', 'ta': 'திரவ அளவு சோதனை'},
    'Battery check and replacements': {
      'si': 'බැටරි පරීක්ෂාව',
      'ta': 'பேட்டரி சோதனை',
    },
    'Wiper blade replacement': {
      'si': 'වයිපර් තලය මාරුව',
      'ta': 'வைப்பர் மாற்றம்',
    },
    'Light bulb check': {'si': 'ලාම්පු පරීක්ෂාව', 'ta': 'விளக்கு சோதனை'},
    'Brake system services': {'si': 'බ්‍රේක් සේවාව', 'ta': 'பிரேக் சேவை'},
    'Suspension and alignment services': {
      'si': 'સસ්පෙන්ෂන් සේවාව',
      'ta': 'சஸ்பென்ஷன் சேவை',
    },
    'Exhaust system service': {
      'si': 'නික්මෙන් ගෑස් සේවාව',
      'ta': 'எக்ஸாஸ்ட் சேவை',
    },
    'Air conditioning services': {
      'si': 'ශීතකරණ සේවාව',
      'ta': 'குளிரூட்டல் சேவை',
    },
    'Electrical system services': {'si': 'විදුලි සේවාව', 'ta': 'மின் சேவை'},
    'Car detailing (Interior and exterior cleaning, waxing)': {
      'si': 'වාහන පිරිසිදු කිරීම',
      'ta': 'கார் சுத்தம்',
    },
    'Tire sales and installation': {'si': 'ටයර් විකිණීම', 'ta': 'டயர் விற்பனை'},
    'Pre-purchase inspections': {
      'si': 'මිලදී ගැනීමට පෙර පරීක්ෂාව',
      'ta': 'வாங்கும் முன் சோதனை',
    },
    'Diagnostic testing': {'si': 'රෝග නිර්ණය', 'ta': 'நோயறிதல் சோதனை'},
  };
  String _translateServiceType(String type, String lang) {
    if (lang == 'en') return type;
    return _serviceTypeTranslations[type]?[lang] ?? type;
  }

  @override
  void initState() {
    super.initState();
    _loadServiceRecords(); // load record to the page.
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is Map && value['\$date'] != null) {
      return DateTime.tryParse(value['\$date'].toString());
    }
    return DateTime.tryParse(value.toString());
  }

  Future<void> _loadServiceRecords() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = await _authService.getCurrentUser();
      final userId =
          currentUser?['uid']?.toString() ??
          currentUser?['id']?.toString() ??
          currentUser?['_id']?.toString() ??
          currentUser?['userId']?.toString();

      if (userId != null && userId.isNotEmpty) {
        final response = await http.get(
          Uri.parse(
            '${_authService.baseUrl}/service-records/user/${Uri.encodeComponent(userId)}',
          ),
        );

        final records = <Map<String, dynamic>>[];
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as List<dynamic>;
          records.addAll(
            decoded.map((doc) => Map<String, dynamic>.from(doc as Map)),
          );
        }

        setState(() {
          _serviceRecords = records;
          _isLoading = false;
        });

        if (_serviceRecords.isEmpty) {
          print('No service records found for user: $userId');
        }
      } else {
        print('User is null');
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      print('Error fetching service records: $e');
      print(stackTrace);
      setState(() => _isLoading = false);
    }
  }

  ////filter records
  List<Map<String, dynamic>> _getFilteredRecords() {
    //matche the search
    return _serviceRecords.where((record) {
      bool matchesSearch = true;
      bool matchesFilter = true;
      bool matchesDate = true;

      if (_searchController.text.isNotEmpty) {
        matchesSearch = record['serviceProvider']
            .toString()
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
      }

      if (_selectedFilter != null) {
        //filter matche
        matchesFilter = record['serviceType'] == _selectedFilter;
      }

      if (_selectedDate != null) {
        //date matche
        final recordDate = _parseDate(record['date']);
        if (recordDate == null) {
          return false;
        }
        matchesDate =
            recordDate.year == _selectedDate!.year &&
            recordDate.month == _selectedDate!.month &&
            recordDate.day == _selectedDate!.day;
      }

      return matchesSearch && matchesFilter && matchesDate;
    }).toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showRecordDetails(Map<String, dynamic> record, String lang) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppStrings.get('service_details', lang)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    AppStrings.get('service_type', lang),
                    record['serviceType'],
                  ),
                  _buildDetailRow(
                    AppStrings.get('date', lang),

                    (_parseDate(record['date'])?.toString().split(' ')[0]) ??
                        '-',
                  ),
                  _buildDetailRow(
                    AppStrings.get('current_mileage', lang),
                    '${record['currentMileage']} KM',
                  ),
                  _buildDetailRow(
                    AppStrings.get('service_mileage', lang),
                    '${record['serviceMileage']} KM',
                  ),
                  _buildDetailRow(
                    AppStrings.get('service_provider', lang),
                    record['serviceProvider'],
                  ),
                  if (record['serviceType'] == 'Oil Filter Change')
                    _buildDetailRow(
                      AppStrings.get('oil_type', lang),
                      record['oilType'] ?? '',
                    ),
                  if (record['notes'] != null && record['notes'].isNotEmpty)
                    _buildDetailRow(
                      AppStrings.get('notes', lang),
                      record['notes'],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.get('close', lang)),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, lang, _) {
        final filteredRecords = _getFilteredRecords();

        return Scaffold(
          backgroundColor: AppColors.richBlack,
          appBar: AppBar(
            title: Text(
              AppStrings.get('service_history', lang),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.obsidian,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppStrings.get('search_provider', lang),
                      border: InputBorder.none,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.gold,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          border: Border.all(color: AppColors.borderGold),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedFilter,
                            hint: Text(
                              AppStrings.get('select_service_type', lang),
                            ),
                            items:
                                _serviceTypes
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value:
                                            type, // ← keeps English value for database matching
                                        child: Text(
                                          _translateServiceType(type, lang),
                                        ), // ← shows translated label
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (value) =>
                                    setState(() => _selectedFilter = value),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            border: Border.all(color: AppColors.borderGold),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDate == null
                                    ? AppStrings.get('select_date', lang)
                                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppColors.gold,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.get('record_details', lang),
                    style: GoogleFonts.jost(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredRecords.isEmpty
                          ? Center(
                            child: Text(AppStrings.get('no_records', lang)),
                          )
                          : ListView.builder(
                            itemCount: filteredRecords.length,
                            itemBuilder: (context, index) {
                              final record = filteredRecords[index];
                              return GestureDetector(
                                onTap: () => _showRecordDetails(record, lang),
                                child: ServiceRecordCard(
                                  date:
                                      (_parseDate(
                                        record['date'],
                                      )?.toString().split(' ')[0]) ??
                                      '-',
                                  mileage: record['serviceMileage'].toString(),
                                  provider: record['serviceProvider'],
                                  serviceType: record['serviceType'],
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: AppBottomNav(currentIndex: 3),
        );
      },
    );
  }
}


class ServiceRecordCard extends StatelessWidget {
  final String date;
  final String mileage;
  final String provider;
  final String serviceType;

  const ServiceRecordCard({
    super.key,
    required this.date,
    required this.mileage,
    required this.provider,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGold),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: GoogleFonts.jost(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: AppColors.gold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                serviceType,
                style: GoogleFonts.jost(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.borderGold),
          const SizedBox(height: 10),
          Text(
            '$mileage KM',
            style: GoogleFonts.jost(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            provider,
            style: GoogleFonts.jost(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
