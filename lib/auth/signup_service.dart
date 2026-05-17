import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _showPassword = false;
  bool _showConfirmPassword = false;
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

  @override
  void dispose() {
    _centerNameController.dispose();
    _emailController.dispose();
    _ownerNameController.dispose();
    _nicController.dispose();
    _regCertController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<bool> _checkDuplicate(String field, String value) async {
    final response = await http.get(
      Uri.parse(
        'https://drcars-fyp-production.up.railway.app/api/service/check?field=$field&value=$value',
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
      final emailExists = await _checkDuplicate('Email', email);
      final usernameExists = await _checkDuplicate('Username', username);
      final centerExists = await _checkDuplicate(
        'serviceCenterName',
        centerName,
      );

      if (centerExists)
        return _showError('This service center name is already in use.');
      if (emailExists)
        return _showError('This email address is already in use.');
      if (usernameExists) return _showError('This username is already in use.');

      final response = await http.post(
        Uri.parse(
          'https://drcars-fyp-production.up.railway.app/api/service/request',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'serviceCenterName': centerName,
          'email': email,
          'password': _passwordController.text,
          'ownerName': _ownerNameController.text.trim(),
          'nic': _nicController.text.trim(),
          'regNumber': _regCertController.text.trim(),
          'address': _addressController.text.trim(),
          'contact': _contactController.text.trim(),
          'notes': _notesController.text.trim(),
          'username': username,
          'city': _selectedCity,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  backgroundColor: AppColors.surfaceDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.borderGold),
                  ),
                  title: Text(
                    'Request Submitted',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  content: Text(
                    'Your request has been submitted. Please wait while the app admin reviews and approves your service center account.',
                    style: GoogleFonts.jost(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.obsidian,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'OK',
                          style: GoogleFonts.jost(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
          );
          _formKey.currentState!.reset();
        }
      } else {
        _showError('Submission failed: ${response.body}');
      }
    } catch (e) {
      _showError('Submission failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (mounted) setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(message, style: GoogleFonts.jost(color: Colors.white)),
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        goldDivider(),
      ],
    );
  }

  // ── Luxury text field ─────────────────────────────────────────────────────
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    bool isPassword = false,
    bool isConfirmPassword = false,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    final isObscure =
        isPassword
            ? !_showPassword
            : isConfirmPassword
            ? !_showConfirmPassword
            : false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        maxLines: isPassword || isConfirmPassword ? 1 : maxLines,
        style: GoogleFonts.jost(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.jost(color: AppColors.textMuted, fontSize: 14),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          prefixIcon: Icon(icon, color: AppColors.gold, size: 20),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed:
                        () => setState(() => _showPassword = !_showPassword),
                  )
                  : isConfirmPassword
                  ? IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed:
                        () => setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        ),
                  )
                  : null,
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
            validator ??
            (required
                ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
                : null),
      ),
    );
  }

  // ── City dropdown ─────────────────────────────────────────────────────────
  Widget _buildCityDropdown() {
    final sortedCities = List<String>.from(_cities)..sort();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGold),
        ),
        child: DropdownButtonFormField<String>(
          value: _selectedCity,
          isExpanded: true,
          style: GoogleFonts.jost(color: AppColors.textPrimary, fontSize: 14),
          dropdownColor: AppColors.surfaceElevated,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.gold,
          ),
          selectedItemBuilder:
              (context) =>
                  sortedCities
                      .map(
                        (city) => Text(
                          city,
                          style: GoogleFonts.jost(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      )
                      .toList(),
          decoration: InputDecoration(
            hintText: 'Select City',
            hintStyle: GoogleFonts.jost(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.location_city_outlined,
              color: AppColors.gold,
              size: 20,
            ),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items:
              sortedCities
                  .map(
                    (city) => DropdownMenuItem(
                      value: city,
                      child: Text(
                        city,
                        style: GoogleFonts.jost(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          validator: (value) => value == null ? 'Please select a city' : null,
          onChanged: (value) => setState(() => _selectedCity = value),
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
        iconTheme: const IconThemeData(color: AppColors.gold),
        centerTitle: true,
        title: Text(
          'Service Center Request',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
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
              // ── Service Center Info ───────────────────────────────
              _sectionHeader('Service Center Details'),

              _buildTextField(
                label: 'Service Center Name',
                controller: _centerNameController,
                icon: Icons.store_outlined,
              ),
              _buildTextField(
                label: 'Email Address',
                controller: _emailController,
                icon: Icons.email_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: 'Username',
                controller: _usernameController,
                icon: Icons.alternate_email,
              ),
              _buildTextField(
                label: 'Password',
                controller: _passwordController,
                icon: Icons.lock_outline,
                isPassword: true,
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
                label: 'Confirm Password',
                controller: _confirmPasswordController,
                icon: Icons.lock_outline,
                isConfirmPassword: true,
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

              // ── Owner Info ────────────────────────────────────────
              _sectionHeader('Owner Details'),

              _buildTextField(
                label: 'Owner Name',
                controller: _ownerNameController,
                icon: Icons.person_outline,
              ),
              _buildTextField(
                label: 'NIC Number',
                controller: _nicController,
                icon: Icons.badge_outlined,
              ),
              _buildTextField(
                label: 'Registration Certificate Number',
                controller: _regCertController,
                icon: Icons.description_outlined,
              ),

              // ── Location ──────────────────────────────────────────
              _sectionHeader('Location'),

              _buildTextField(
                label: 'Service Center Address',
                controller: _addressController,
                icon: Icons.location_on_outlined,
              ),
              _buildCityDropdown(),
              _buildTextField(
                label: 'Contact Information',
                controller: _contactController,
                icon: Icons.phone_outlined,
              ),

              // ── Notes ─────────────────────────────────────────────
              _sectionHeader('Additional Notes'),

              _buildTextField(
                label: 'Additional Notes (optional)',
                controller: _notesController,
                icon: Icons.notes_outlined,
                maxLines: 3,
                required: false,
              ),

              const SizedBox(height: 8),

              // ── Submit Button ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.obsidian,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.obsidian,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            'SUBMIT REQUEST',
                            style: GoogleFonts.jost(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: AppColors.obsidian,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Back link ─────────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Back to Home',
                    style: GoogleFonts.jost(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
