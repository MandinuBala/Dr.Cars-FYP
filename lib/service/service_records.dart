// lib/service/service_records.dart
import 'dart:convert';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/user/main_dashboard.dart';
import 'package:dr_cars_fyp/admin/ratings/rating.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:dr_cars_fyp/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ServiceRecordsPage extends StatefulWidget {
  const ServiceRecordsPage({super.key});

  @override
  State<ServiceRecordsPage> createState() => _ServiceRecordsPageState();
}

class _ServiceRecordsPageState extends State<ServiceRecordsPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentMileageController =
      TextEditingController();
  final TextEditingController _serviceMileageController =
      TextEditingController();
  final TextEditingController _serviceProviderController =
      TextEditingController();
  final TextEditingController _serviceCostController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedServiceType;
  String? _selectedOilType;
  DateTime? _selectedDate;

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
    'Diagnostic testing',
  ];

  final List<String> _oilTypes = [
    'Synthetic',
    'Semi-Synthetic',
    'Conventional',
    'High Mileage',
  ];

  @override
  void dispose() {
    _currentMileageController.dispose();
    _serviceMileageController.dispose();
    _serviceProviderController.dispose();
    _serviceCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Logic unchanged ───────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _loadRecords() async {
    final currentUser = await _authService.getCurrentUser();
    final userId =
        currentUser?['uid']?.toString() ??
        currentUser?['id']?.toString() ??
        currentUser?['_id']?.toString() ??
        currentUser?['userId']?.toString();
    if (userId == null || userId.isEmpty) return [];
    final response = await http.get(
      Uri.parse(
        '${_authService.baseUrl}/service-records/user/${Uri.encodeComponent(userId)}',
      ),
    );
    if (response.statusCode != 200) return [];
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    if (value is Map && value['\$date'] != null)
      return DateTime.tryParse(value['\$date'].toString());
    return DateTime.tryParse(value.toString());
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.gold,
                onPrimary: AppColors.obsidian,
                surface: AppColors.surfaceDark,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveServiceRecord() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = await _authService.getCurrentUser();
      final userId =
          currentUser?['uid']?.toString() ??
          currentUser?['id']?.toString() ??
          currentUser?['_id']?.toString() ??
          currentUser?['userId']?.toString();
      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Please log in first',
              style: GoogleFonts.jost(color: Colors.white),
            ),
          ),
        );
        return;
      }
      try {
        final response = await http.post(
          Uri.parse('${_authService.baseUrl}/service-records'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'currentMileage': _currentMileageController.text.trim(),
            'serviceMileage': _serviceMileageController.text.trim(),
            'serviceProvider': _serviceProviderController.text.trim(),
            'serviceCost': _serviceCostController.text.trim(),
            'serviceType': _selectedServiceType,
            'oilType': _selectedOilType,
            'notes': _notesController.text.trim(),
            'date': _selectedDate?.toIso8601String(),
            'createdAt': DateTime.now().toIso8601String(),
          }),
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception(response.body);
        }
        _formKey.currentState!.reset();
        _currentMileageController.clear();
        _serviceMileageController.clear();
        _serviceProviderController.clear();
        _serviceCostController.clear();
        _notesController.clear();
        setState(() {
          _selectedServiceType = null;
          _selectedOilType = null;
          _selectedDate = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text(
                'Service record saved!',
                style: GoogleFonts.jost(color: Colors.white),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text(
                'Error saving record: $e',
                style: GoogleFonts.jost(color: Colors.white),
              ),
            ),
          );
        }
      }
    }
  }

  // ── Luxury text field ─────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? suffix,
    String? prefix,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.jost(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.jost(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          floatingLabelStyle: GoogleFonts.jost(
            color: AppColors.gold,
            fontSize: 12,
          ),
          suffixText: suffix,
          prefixText: prefix,
          suffixStyle: GoogleFonts.jost(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          prefixStyle: GoogleFonts.jost(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderGold),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderGold),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        validator:
            required
                ? (v) => (v == null || v.isEmpty) ? 'Required' : null
                : null,
      ),
    );
  }

  // ── Luxury dropdown ───────────────────────────────────────────────────────
  Widget _buildDropdown({
    required List<String> items,
    required String? selectedValue,
    required String label,
    required Function(String?) onChanged,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        style: GoogleFonts.jost(color: AppColors.textPrimary, fontSize: 14),
        dropdownColor: AppColors.surfaceElevated,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.gold,
        ),
        selectedItemBuilder:
            (context) =>
                items
                    .map(
                      (item) => Text(
                        item,
                        style: GoogleFonts.jost(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    )
                    .toList(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.jost(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          floatingLabelStyle: GoogleFonts.jost(
            color: AppColors.gold,
            fontSize: 12,
          ),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderGold),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderGold),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        items:
            items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: GoogleFonts.jost(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                .toList(),
        onChanged: onChanged,
        validator:
            required
                ? (v) => (v == null || v.isEmpty) ? 'Required' : null
                : null,
      ),
    );
  }

  // ── Saved records list ────────────────────────────────────────────────────
  Widget _buildSavedRecordsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadRecords(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          );
        }
        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return Center(
            child: Text(
              'No service records found.',
              style: GoogleFonts.jost(color: AppColors.textMuted, fontSize: 14),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final data = records[index];
            final date = _parseDate(data['date']);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGold),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['serviceType'] ?? 'Unknown Service',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    color: AppColors.borderGold,
                  ),
                  if (date != null)
                    _recordRow(
                      'Date',
                      '${date.day}/${date.month}/${date.year}',
                    ),
                  _recordRow(
                    'Current Mileage',
                    '${data['currentMileage'] ?? '-'} KM',
                  ),
                  _recordRow(
                    'Service Mileage',
                    '${data['serviceMileage'] ?? '-'} KM',
                  ),
                  _recordRow(
                    'Service Provider',
                    data['serviceProvider'] ?? '-',
                  ),
                  _recordRow(
                    'Service Cost',
                    'Rs. ${data['serviceCost'] ?? '-'}',
                  ),
                  if (data['oilType'] != null)
                    _recordRow('Oil Type', data['oilType']),
                  if (data['notes'] != null &&
                      data['notes'].toString().trim().isNotEmpty)
                    _recordRow('Notes', data['notes']),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _recordRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.jost(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.richBlack,
      appBar: AppBar(
        backgroundColor: AppColors.obsidian,
        foregroundColor: AppColors.textPrimary,
        iconTheme: const IconThemeData(color: AppColors.gold),
        title: Text(
          'Service Records',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Form section ───────────────────────────────────────
              Text(
                'New Service Record',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              goldDivider(),

              _buildTextField(
                controller: _currentMileageController,
                label: 'Current Mileage',
                suffix: 'KM',
                keyboardType: TextInputType.number,
              ),

              _buildDropdown(
                items: _serviceTypes,
                selectedValue: _selectedServiceType,
                label: 'Type of Service',
                onChanged: (val) => setState(() => _selectedServiceType = val),
              ),

              if (_selectedServiceType == 'Oil Filter Change')
                _buildDropdown(
                  items: _oilTypes,
                  selectedValue: _selectedOilType,
                  label: 'Oil Type',
                  onChanged: (val) => setState(() => _selectedOilType = val),
                ),

              // Date picker
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGold),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Date of Service'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: GoogleFonts.jost(
                          color:
                              _selectedDate == null
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        color: AppColors.gold,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              _buildTextField(
                controller: _serviceMileageController,
                label: 'Service Mileage',
                suffix: 'KM',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller: _serviceProviderController,
                label: 'Service Provider',
              ),
              _buildTextField(
                controller: _serviceCostController,
                label: 'Service Cost',
                prefix: 'Rs. ',
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                controller: _notesController,
                label: 'Additional Notes',
                maxLines: 3,
                required: false,
              ),

              const SizedBox(height: 8),

              // ── Action buttons ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveServiceRecord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.obsidian,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'SAVE',
                        style: GoogleFonts.jost(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.borderGold),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.jost(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Saved records ─────────────────────────────────────
              Text(
                'Saved Records',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              goldDivider(),

              _buildSavedRecordsList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 0),
    );
  }
}
