import 'dart:convert';

import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/obd/OBD2.dart';
import 'package:dr_cars_fyp/user/main_dashboard.dart';
import 'package:dr_cars_fyp/map/mapscreen.dart';
import 'package:dr_cars_fyp/user/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  void _showRecordDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Service Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Service Type', record['serviceType']),
                  _buildDetailRow(
                    'Date',
                    (_parseDate(record['date'])?.toString().split(' ')[0]) ??
                        '-',
                  ),
                  _buildDetailRow(
                    'Current Mileage',
                    '${record['currentMileage']} KM',
                  ),
                  _buildDetailRow(
                    'Service Mileage',
                    '${record['serviceMileage']} KM',
                  ),
                  _buildDetailRow(
                    'Service Provider',
                    record['serviceProvider'],
                  ),
                  if (record['serviceType'] == 'Oil Filter Change')
                    _buildDetailRow('Oil Type', record['oilType'] ?? ''),
                  if (record['notes'] != null && record['notes'].isNotEmpty)
                    _buildDetailRow('Notes', record['notes']),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
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
    final filteredRecords = _getFilteredRecords();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Service History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 72, 64, 122),
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
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by service provider',
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedFilter,
                        hint: const Text('Select Service Type'),
                        items:
                            _serviceTypes
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) => setState(() => _selectedFilter = value),
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
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate == null
                                ? 'Select Date'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Record Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredRecords.isEmpty
                      ? const Center(child: Text('No service records found'))
                      : ListView.builder(
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return GestureDetector(
                            onTap: () => _showRecordDetails(record),
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
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          if (index == _selectedIndex) return;
          setState(() => _selectedIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MapScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => OBD2Page()),
            );
          } else if (index == 3) {
            // Already here
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          const BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),
          BottomNavigationBarItem(
            icon: Image.asset('images/logo.png', height: 24),
            label: '',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.history), label: ''),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              Text(
                serviceType,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$mileage KM',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            provider,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
