import 'dart:convert';

import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/service/service_menu.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
          const SnackBar(content: Text("Unable to identify current user.")),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
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
        const SnackBar(content: Text("Receipt saved successfully.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Receipt to- ${widget.vehicleNumber}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Previous Oil Change Date: ${widget.previousOilChange}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                "Current Mileage: ${widget.currentMileage}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                "Next Service Date: ${widget.nextServiceDate}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Table(
                border: TableBorder.all(),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[200]),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Service",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Price (Rs.)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...widget.servicesSelected.entries
                      .where((entry) => entry.value)
                      .map((entry) {
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(entry.key),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: _priceControllers[entry.key],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: "Enter Price",
                                ),
                              ),
                            ),
                          ],
                        );
                      })
                      .toList(),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _sendReceipt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            "Send the receipt",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
