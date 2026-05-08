// lib/service/add_service.dart
import 'package:dr_cars_fyp/service/conformation_receipt.dart';
import 'package:dr_cars_fyp/service/service_menu.dart';
import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AddService extends StatefulWidget {
  final String vehicleNumber;

  const AddService({required this.vehicleNumber, super.key});

  @override
  _AddServiceState createState() => _AddServiceState();
}

class _AddServiceState extends State<AddService> {
  final TextEditingController _previousOilChangeController =
      TextEditingController();
  final TextEditingController _currentMileageController =
      TextEditingController();
  final TextEditingController _nextServiceDateController =
      TextEditingController();

  String? oilType;

  bool _oilChanged = false;
  bool _airFilterChanged = false;
  bool _oilFilterChanged = false;
  bool _coolantChanged = false;
  bool _brakeFluidChanged = false;
  bool _oesterboxOilChanged = false;
  bool _differentialOilChanged = false;
  bool _beltInspection = false;
  bool _batteryTesting = false;

  // ── Validation ────────────────────────────────────────────────────────────
  bool _validateAndProceed() {
    final anyServiceSelected =
        _oilChanged ||
        _airFilterChanged ||
        _oilFilterChanged ||
        _coolantChanged ||
        _brakeFluidChanged ||
        _oesterboxOilChanged ||
        _differentialOilChanged ||
        _beltInspection ||
        _batteryTesting;

    if (!anyServiceSelected) {
      _showError('Please select at least one service done.');
      return false;
    }
    if (_oilChanged && (oilType == null || oilType!.isEmpty)) {
      _showError('Please select the oil type for the oil change.');
      return false;
    }
    if (_currentMileageController.text.trim().isEmpty) {
      _showError('Please enter the current mileage.');
      return false;
    }
    if (double.tryParse(_currentMileageController.text.trim()) == null) {
      _showError('Current mileage must be a valid number.');
      return false;
    }
    if (_nextServiceDateController.text.trim().isEmpty) {
      _showError('Please select the next service date.');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(
          message,
          style: GoogleFonts.jost(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Reusable luxury checkbox tile ─────────────────────────────────────────
  Widget _buildCheckboxTile(
    String title,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: value
            ? AppColors.gold.withOpacity(0.08)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value ? AppColors.gold.withOpacity(0.4) : AppColors.borderGold,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: GoogleFonts.jost(
            fontSize: 14,
            color: value ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: value ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        value: value,
        activeColor: AppColors.gold,
        checkColor: AppColors.obsidian,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Date picker field ─────────────────────────────────────────────────────
  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required bool required,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        style: GoogleFonts.jost(color: AppColors.textPrimary, fontSize: 14),
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: firstDate ?? DateTime(2000),
            lastDate: lastDate ?? DateTime(2101),
            builder: (context, child) => Theme(
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
          if (picked != null) {
            setState(() {
              controller.text =
                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
            });
          }
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.jost(
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
          suffixIcon:
              const Icon(Icons.calendar_today, color: AppColors.gold, size: 18),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Text field ────────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.jost(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.jost(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          suffixText: suffix,
          suffixStyle: GoogleFonts.jost(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
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
        centerTitle: true,
        title: Text(
          'Add Service: ${widget.vehicleNumber}',
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
            // ── Service Information ───────────────────────────────────────
            Text(
              'Service Information',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            goldDivider(),

            _buildDateField(
              controller: _previousOilChangeController,
              label: 'Previous Oil Change Date (optional)',
              required: false,
              lastDate: DateTime.now(),
            ),

            _buildTextField(
              controller: _currentMileageController,
              label: 'Current Mileage *',
              suffix: 'km',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 8),

            // ── Services Done ─────────────────────────────────────────────
            Text(
              'Services Done',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select at least one service',
              style: GoogleFonts.jost(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            goldDivider(),

            // Oil change with type dropdown
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: _oilChanged
                    ? AppColors.gold.withOpacity(0.08)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _oilChanged
                      ? AppColors.gold.withOpacity(0.4)
                      : AppColors.borderGold,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Checkbox(
                      value: _oilChanged,
                      activeColor: AppColors.gold,
                      checkColor: AppColors.obsidian,
                      onChanged: (bool? value) {
                        setState(() {
                          _oilChanged = value!;
                          if (!_oilChanged) oilType = null;
                        });
                      },
                    ),
                    Text(
                      'Oil Changed',
                      style: GoogleFonts.jost(
                        fontSize: 14,
                        color: _oilChanged
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: _oilChanged
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    // Oil type dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderGold),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: oilType,
                          hint: Text(
                            'Oil Type',
                            style: GoogleFonts.jost(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          dropdownColor: AppColors.surfaceElevated,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.gold,
                            size: 18,
                          ),
                          style: GoogleFonts.jost(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                          items: ['Synthetic', 'Semi-Synthetic', 'Mineral']
                              .map((String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ))
                              .toList(),
                          onChanged: _oilChanged
                              ? (String? newValue) {
                                  setState(() => oilType = newValue);
                                }
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _buildCheckboxTile('Air Filter Changed', _airFilterChanged,
                (v) => setState(() => _airFilterChanged = v ?? false)),
            _buildCheckboxTile('Oil Filter Changed', _oilFilterChanged,
                (v) => setState(() => _oilFilterChanged = v ?? false)),
            _buildCheckboxTile('Coolant Changed', _coolantChanged,
                (v) => setState(() => _coolantChanged = v ?? false)),
            _buildCheckboxTile('Brake Fluid Changed', _brakeFluidChanged,
                (v) => setState(() => _brakeFluidChanged = v ?? false)),
            _buildCheckboxTile('Oesterbox Oil Changed', _oesterboxOilChanged,
                (v) => setState(() => _oesterboxOilChanged = v ?? false)),
            _buildCheckboxTile('Differential Oil Changed',
                _differentialOilChanged,
                (v) => setState(() => _differentialOilChanged = v ?? false)),
            _buildCheckboxTile('Belt Inspection', _beltInspection,
                (v) => setState(() => _beltInspection = v ?? false)),
            _buildCheckboxTile('Battery Testing', _batteryTesting,
                (v) => setState(() => _batteryTesting = v ?? false)),

            const SizedBox(height: 8),

            // ── Next Service Date ─────────────────────────────────────────
            _buildDateField(
              controller: _nextServiceDateController,
              label: 'Next Service Date *',
              required: true,
              firstDate: DateTime.now(),
              lastDate: DateTime(2101),
            ),

            const SizedBox(height: 8),

            // ── Proceed Button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.obsidian,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (!_validateAndProceed()) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecieptPage(
                        vehicleNumber: widget.vehicleNumber,
                        previousOilChange: _previousOilChangeController.text,
                        currentMileage: _currentMileageController.text,
                        nextServiceDate: _nextServiceDateController.text,
                        servicesSelected: {
                          if (_oilChanged)
                            'Oil Changed (${oilType ?? 'N/A'})': true,
                          if (_airFilterChanged) 'Air Filter Changed': true,
                          if (_oilFilterChanged) 'Oil Filter Changed': true,
                          if (_coolantChanged) 'Coolant Changed': true,
                          if (_brakeFluidChanged) 'Brake Fluid Changed': true,
                          if (_oesterboxOilChanged)
                            'Oesterbox Oil Changed': true,
                          if (_differentialOilChanged)
                            'Differential Oil Changed': true,
                          if (_beltInspection) 'Belt Inspection': true,
                          if (_batteryTesting) 'Battery Testing': true,
                        },
                      ),
                    ),
                  );
                },
                child: Text(
                  'PROCEED TO RECEIPT',
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
}