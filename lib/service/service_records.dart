import 'dart:convert';

import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/user/main_dashboard.dart';
import 'package:dr_cars_fyp/user/user_profile.dart';
import 'package:dr_cars_fyp/admin/ratings/rating.dart';
import 'package:flutter/material.dart';
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

  Future<List<Map<String, dynamic>>> _loadRecords() async {
    final currentUser = await _authService.getCurrentUser();
    final userId =
        currentUser?['uid']?.toString() ??
        currentUser?['id']?.toString() ??
        currentUser?['_id']?.toString() ??
        currentUser?['userId']?.toString();

    if (userId == null || userId.isEmpty) {
      return [];
    }

    final response = await http.get(
      Uri.parse(
        '${_authService.baseUrl}/service-records/user/${Uri.encodeComponent(userId)}',
      ),
    );

    if (response.statusCode != 200) {
      return [];
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    if (value is Map && value['\$date'] != null) {
      return DateTime.tryParse(value['\$date'].toString());
    }
    return DateTime.tryParse(value.toString());
  }

  Widget _buildServiceRecordsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadRecords(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return const Center(child: Text("No service records found."));
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: records.length,
          itemBuilder: (context, index) {
            final data = records[index];
            final date = _parseDate(data['date']);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['serviceType'] ?? 'Unknown Service',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (date != null)
                      Text("Date: ${date.day}/${date.month}/${date.year}"),
                    Text(
                      "Current Mileage: ${data['currentMileage'] ?? '-'} KM",
                    ),
                    Text(
                      "Service Mileage: ${data['serviceMileage'] ?? '-'} KM",
                    ),
                    Text("Service Provider: ${data['serviceProvider'] ?? '-'}"),
                    Text("Service Cost: Rs. ${data['serviceCost'] ?? '-'}"),
                    if (data['oilType'] != null)
                      Text("Oil Type: ${data['oilType']}"),
                    if (data['notes'] != null &&
                        data['notes'].toString().trim() != '')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text("Notes: ${data['notes']}"),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please log in first')));
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

        // Reset form & clear controllers
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

        setState(() {});

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Service record saved!')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving record: $e')));
      }
    }
  }

  Widget _buildAnimatedDropdown(
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged,
    String hint,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 64, 4, 167).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(2, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        isExpanded: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
          filled: true,
          fillColor: const Color.fromARGB(255, 255, 255, 255),
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        items:
            items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
        onChanged: onChanged,
        validator:
            (value) => (value == null || value.isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String hintText,
    String? suffixText,
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = true,
    InputDecoration? decoration,
    String? Function(String?)? validator,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 68, 8, 172).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(2, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: const Color.fromARGB(255, 255, 255, 255),
          suffixText: suffixText,
          prefixText: prefixText,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
        ),
        validator:
            required
                ? (value) => value == null || value.isEmpty ? 'Required' : null
                : null,
      ),
    );
  }

  Widget _buildAnimatedDateField({
    required BuildContext context,
    required String labelText,
    required String? dateText,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 45, 1, 122).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: labelText,
            filled: true,
            fillColor: const Color.fromARGB(255, 255, 255, 255),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          child: Text(
            dateText ?? 'Select date',
            style: TextStyle(
              color: dateText != null ? Colors.black : Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Service Records',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 72, 64, 122),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 153, 113, 253),
              Color.fromARGB(255, 0, 136, 248),
              Color.fromARGB(255, 76, 37, 249),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: MediaQuery.of(context).size.width > 600 ? 0.6 : 0.95,
            child: Card(
              elevation: 15,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Mileage',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildAnimatedTextField(
                          controller: _currentMileageController,
                          keyboardType: TextInputType.number,
                          hintText: 'Enter current mileage',
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            suffixText: 'KM',
                          ),
                          validator:
                              (value) => value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Type of Service',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildAnimatedDropdown(
                          _serviceTypes,
                          _selectedServiceType,
                          (val) => setState(() => _selectedServiceType = val),
                          'Select service type',
                        ),

                        if (_selectedServiceType == 'Oil Filter Change') ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Oil Type',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildAnimatedDropdown(
                            _oilTypes,
                            _selectedOilType,
                            (val) => setState(() => _selectedOilType = val),
                            'Select oil type',
                          ),
                        ],

                        const SizedBox(height: 16),
                        const Text(
                          'Date of Service',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildAnimatedDateField(
                          context: context,
                          labelText: 'Date of Service',
                          dateText:
                              _selectedDate != null
                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : null,
                          onTap: () => _selectDate(context),
                        ),

                        /*filled: true,
                              fillColor: Colors.grey[200],
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _selectedDate != null
                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : 'Select date',
                            ),
                          ),
                        ),*/
                        const SizedBox(height: 16),
                        const Text(
                          'Service Mileage',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildAnimatedTextField(
                          controller: _serviceMileageController,
                          keyboardType: TextInputType.number,
                          hintText: 'Enter service mileage',
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            suffixText: 'KM',
                          ),
                          validator:
                              (value) => value!.isEmpty ? 'Required' : null,
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Service Provider',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildAnimatedTextField(
                          controller: _serviceProviderController,
                          hintText: 'Enter provider name',
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                          validator:
                              (value) => value!.isEmpty ? 'Required' : null,
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Service Cost',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildAnimatedTextField(
                          controller: _serviceCostController,
                          keyboardType: TextInputType.number,
                          hintText: 'Enter service cost',
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            prefixText: 'Rs.',
                          ),
                          validator:
                              (value) => value!.isEmpty ? 'Required' : null,
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Additional Notes',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildAnimatedTextField(
                          controller: _notesController,
                          maxLines: 3,
                          hintText: 'Enter any additional notes',
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                        ),

                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveServiceRecord,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: const Text('Save'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        const Text(
                          'Saved Records:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Container(
                          height: 300, // adjust as needed
                          child: _buildServiceRecordsList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          if (index == 3)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RatingScreen()),
            );
          if (index == 4)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          const BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(
            icon: Image.asset('images/logo.png', height: 24),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.rate_review),
            label: '',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}
