import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ServiceCenterRequestScreen extends StatefulWidget {
  const ServiceCenterRequestScreen({super.key});

  @override
  State<ServiceCenterRequestScreen> createState() =>
      _ServiceCenterRequestScreenState();
}

class _ServiceCenterRequestScreenState
    extends State<ServiceCenterRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _centerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _regCertController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSubmitting = false;
  String? _selectedCity;

  final List<String> _cities = [
    'Colombo',
    'Dehiwala',
    'Moratuwa',
    'Nugegoda',
    'Homagama',
    'Piliyandala',
    'Battaramulla',
    'Gampaha',
    'Negombo',
    'Ja-Ela',
    'Wattala',
    'Ragama',
    'Katunayake',
    'Kalutara',
    'Panadura',
    'Beruwala',
    'Horana',
    'Aluthgama',
    'Matugama',
    'Kandy',
    'Peradeniya',
    'Katugastota',
    'Gampola',
    'Nawalapitiya',
    'Matale',
    'Dambulla',
    'Ukuwela',
    'Rattota',
    'Nuwara Eliya',
    'Hatton',
    'Talawakele',
    'Nanu Oya',
    'Galle',
    'Unawatuna',
    'Ambalangoda',
    'Hikkaduwa',
    'Matara',
    'Weligama',
    'Akurassa',
    'Dikwella',
    'Hambantota',
    'Tangalle',
    'Tissamaharama',
    'Ambalantota',
    'Jaffna',
    'Point Pedro',
    'Chavakachcheri',
    'Nallur',
    'Kilinochchi',
    'Pallai',
    'Paranthan',
    'Mannar',
    'Thalaimannar',
    'Pesalai',
    'Vavuniya',
    'Cheddikulam',
    'Nedunkeni',
    'Mullaitivu',
    'Puthukkudiyiruppu',
    'Oddusuddan',
    'Batticaloa',
    'Eravur',
    'Kattankudy',
    'Ampara',
    'Kalmunai',
    'Sammanthurai',
    'Akkaraipattu',
    'Trincomalee',
    'Kinniya',
    'Mutur',
    'Kuchchaveli',
    'Kurunegala',
    'Pannala',
    'Nikaweratiya',
    'Kuliyapitiya',
    'Puttalam',
    'Wennappuwa',
    'Chilaw',
    'Anamaduwa',
    'Anuradhapura',
    'Kekirawa',
    'Medawachchiya',
    'Mihintale',
    'Polonnaruwa',
    'Hingurakgoda',
    'Medirigiriya',
    'Badulla',
    'Bandarawela',
    'Hali-Ela',
    'Diyatalawa',
    'Monaragala',
    'Wellawaya',
    'Bibile',
    'Buttala',
    'Ratnapura',
    'Balangoda',
    'Eheliyagoda',
    'Kuruwita',
    'Kegalle',
    'Mawanella',
    'Rambukkana',
    'Warakapola',
  ];

  Future<bool> _checkDuplicate(String field, String value) async {
    final response = await http.get(
      Uri.parse(
        "http://192.168.1.21:5000/api/service/check?field=$field&value=$value",
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['exists'] as bool;
    }

    return false;
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final centerName = _centerNameController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      final emailExists = await _checkDuplicate("Email", email);
      final usernameExists = await _checkDuplicate("Username", username);
      final centerExists = await _checkDuplicate(
        "serviceCenterName",
        centerName,
      );

      if (centerExists)
        return _showError("This service center name is already in use.");
      if (emailExists)
        return _showError("This email address is already in use.");
      if (usernameExists) return _showError("This username is already in use.");

      final response = await http.post(
        Uri.parse("http://192.168.1.21:5000/api/service/request"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "serviceCenterName": centerName,
          "email": email,
          "password": _passwordController.text,
          "ownerName": _ownerNameController.text.trim(),
          "nic": _nicController.text.trim(),
          "regNumber": _regCertController.text.trim(),
          "address": _addressController.text.trim(),
          "contact": _contactController.text.trim(),
          "notes": _notesController.text.trim(),
          "username": username,
          "city": _selectedCity,
        }),
      );

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text("Request Submitted"),
                content: const Text(
                  "Your request has been submitted. Please wait while the app admin reviews and approves your service center account.",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text("OK"),
                  ),
                ],
              ),
        );

        _formKey.currentState!.reset();
      } else {
        _showError("Submission failed: ${response.body}");
      }
    } catch (e) {
      _showError("Submission failed: $e");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool requiredField = true,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      obscureText: obscureText,
      validator:
          validator ??
          (value) {
            if (requiredField && (value == null || value.trim().isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final sortedCities = List<String>.from(_cities)..sort();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Service Center Account Request"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                label: "Service Center Name",
                controller: _centerNameController,
              ),
              _buildTextField(
                label: "E-mail Address",
                controller: _emailController,
              ),
              _buildTextField(
                label: "Username",
                controller: _usernameController,
              ),
              _buildTextField(
                label: "Password",
                controller: _passwordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: "Confirm Password",
                controller: _confirmPasswordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: "Owner Name",
                controller: _ownerNameController,
              ),
              _buildTextField(label: "NIC Number", controller: _nicController),
              _buildTextField(
                label: "Registration Certificate Number",
                controller: _regCertController,
              ),
              _buildTextField(
                label: "Service Center Address",
                controller: _addressController,
              ),
              _buildTextField(
                label: "Contact Information",
                controller: _contactController,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: DropdownButtonFormField<String>(
                  value: _selectedCity,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Service Center City",
                    border: OutlineInputBorder(),
                  ),
                  items:
                      sortedCities
                          .map(
                            (city) => DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            ),
                          )
                          .toList(),
                  validator:
                      (value) => value == null ? 'Please select a city' : null,
                  onChanged: (value) => setState(() => _selectedCity = value),
                ),
              ),
              _buildTextField(
                label: "Additional Notes",
                controller: _notesController,
                maxLines: 3,
                requiredField: false,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child:
                    _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Submit Request"),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Back to Home"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
