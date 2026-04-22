import 'package:dr_cars_fyp/service/conformation_receipt.dart';
import 'package:dr_cars_fyp/service/service_menu.dart';
import 'package:flutter/material.dart';

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

  // ===================== VALIDATION =====================
  bool _validateAndProceed() {
    // At least one service must be checked
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
      _showError("Please select at least one service done.");
      return false;
    }

    // If oil changed, oil type must be selected
    if (_oilChanged && (oilType == null || oilType!.isEmpty)) {
      _showError("Please select the oil type for the oil change.");
      return false;
    }

    // Current mileage is required
    if (_currentMileageController.text.trim().isEmpty) {
      _showError("Please enter the current mileage.");
      return false;
    }

    // Mileage must be a valid number
    if (double.tryParse(_currentMileageController.text.trim()) == null) {
      _showError("Current mileage must be a valid number.");
      return false;
    }

    // Next service date is required
    if (_nextServiceDateController.text.trim().isEmpty) {
      _showError("Please select the next service date.");
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Service: ${widget.vehicleNumber}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.black),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Service Information Section ----
              const Text(
                "Service Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Previous oil change date (optional)
              TextField(
                controller: _previousOilChangeController,
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _previousOilChangeController.text =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: "Previous oil change date (optional)",
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  suffixIcon: Icon(Icons.calendar_today, color: Colors.black54),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 10),

              // Current mileage — REQUIRED
              TextField(
                controller: _currentMileageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Current Mileage *",
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  suffixText: "km",
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),

              // ---- Services Done Section ----
              const Text(
                "Services Done *",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Select at least one service",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),

              // Oil change row with type dropdown
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _oilChanged,
                        activeColor: Colors.black,
                        onChanged: (bool? value) {
                          setState(() {
                            _oilChanged = value!;
                            if (!_oilChanged) oilType = null;
                          });
                        },
                      ),
                      const Text('Oil Changed', style: TextStyle(fontSize: 15)),
                      const Spacer(),
                      DropdownButton<String>(
                        value: oilType,
                        hint: const Text('Select Type'),
                        items:
                            ['Synthetic', 'Semi-Synthetic', 'Mineral'].map((
                              String value,
                            ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged:
                            _oilChanged
                                ? (String? newValue) {
                                  setState(() => oilType = newValue);
                                }
                                : null, // disabled if oil change not checked
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),

              _buildCheckboxTile(
                "Air Filter Changed",
                _airFilterChanged,
                (v) => setState(() => _airFilterChanged = v ?? false),
              ),
              _buildCheckboxTile(
                "Oil Filter Changed",
                _oilFilterChanged,
                (v) => setState(() => _oilFilterChanged = v ?? false),
              ),
              _buildCheckboxTile(
                "Coolant Changed",
                _coolantChanged,
                (v) => setState(() => _coolantChanged = v ?? false),
              ),
              _buildCheckboxTile(
                "Brake Fluid Changed",
                _brakeFluidChanged,
                (v) => setState(() => _brakeFluidChanged = v ?? false),
              ),
              _buildCheckboxTile(
                "Oesterbox Oil Changed",
                _oesterboxOilChanged,
                (v) => setState(() => _oesterboxOilChanged = v ?? false),
              ),
              _buildCheckboxTile(
                "Differential Oil Changed",
                _differentialOilChanged,
                (v) => setState(() => _differentialOilChanged = v ?? false),
              ),
              _buildCheckboxTile(
                "Belt Inspection",
                _beltInspection,
                (v) => setState(() => _beltInspection = v ?? false),
              ),
              _buildCheckboxTile(
                "Battery Testing",
                _batteryTesting,
                (v) => setState(() => _batteryTesting = v ?? false),
              ),

              const SizedBox(height: 16),

              // Next service date — REQUIRED
              TextField(
                controller: _nextServiceDateController,
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 90)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setState(() {
                      _nextServiceDateController.text =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: "Next Service Date *",
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  suffixIcon: Icon(Icons.calendar_today, color: Colors.black54),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 24),

              // Proceed button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  onPressed: () {
                    if (!_validateAndProceed()) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => RecieptPage(
                              vehicleNumber: widget.vehicleNumber,
                              previousOilChange:
                                  _previousOilChangeController.text,
                              currentMileage: _currentMileageController.text,
                              nextServiceDate: _nextServiceDateController.text,
                              servicesSelected: {
                                if (_oilChanged)
                                  "Oil Changed (${oilType ?? 'N/A'})": true,
                                if (_airFilterChanged)
                                  "Air Filter Changed": true,
                                if (_oilFilterChanged)
                                  "Oil Filter Changed": true,
                                if (_coolantChanged) "Coolant Changed": true,
                                if (_brakeFluidChanged)
                                  "Brake Fluid Changed": true,
                                if (_oesterboxOilChanged)
                                  "Oesterbox Oil Changed": true,
                                if (_differentialOilChanged)
                                  "Differential Oil Changed": true,
                                if (_beltInspection) "Belt Inspection": true,
                                if (_batteryTesting) "Battery Testing": true,
                              },
                            ),
                      ),
                    );
                  },
                  child: const Text(
                    "Proceed to Receipt",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxTile(
    String title,
    bool value,
    Function(bool?) onChanged,
  ) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      activeColor: Colors.black,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
