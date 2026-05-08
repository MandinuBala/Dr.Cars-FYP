// lib/service/owner_info.dart
import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_service.dart';

class OwnerInfo extends StatefulWidget {
  final String vehicleNumber;
  final Map<String, dynamic>? vehicleData;
  final Map<String, dynamic>? userData;

  const OwnerInfo({
    super.key,
    required this.vehicleNumber,
    this.vehicleData,
    this.userData,
  });

  @override
  _OwnerInfoPageState createState() => _OwnerInfoPageState();
}

class _OwnerInfoPageState extends State<OwnerInfo> {
  final AuthService _authService = AuthService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController vehicleYearController = TextEditingController();
  final TextEditingController userIdController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  String? selectedBrand;
  String? selectedModel;

  final Map<String, List<String>> vehicleModels = {
    'Toyota': [
      'Corolla',
      'Camry',
      'RAV4',
      'Highlander',
      'Aqua',
      'Axio',
      'Vitz',
      'Allion',
      'Premio',
      'LandCruiser',
      'Hilux',
      'Prius',
      'Rush',
    ],
    'Nissan': [
      'Sunny',
      'X-Trail',
      'Juke',
      'Note',
      'Teana',
      'Skyline',
      'Patrol',
      'Navara',
      'Qashqai',
      'Murano',
      'Titan',
      'Frontier',
      'Sylphy',
      'Fairlady Z',
      'Armada',
      'Sentra',
      'Leaf',
      'GT-R',
    ],
    'Honda': [
      'Civic',
      'Accord',
      'CR-V',
      'Pilot',
      'Fit',
      'Vezel',
      'Grace',
      'Freed',
      'Insight',
      'HR-V',
      'BR-V',
      'Jazz',
      'City',
      'Legend',
      'Odyssey',
      'Shuttle',
      'Stepwgn',
      'Acty',
      'S660',
      'NSX',
    ],
    'Suzuki': [
      'Alto',
      'Wagon R',
      'Swift',
      'Dzire',
      'Baleno',
      'Ertiga',
      'Celerio',
      'S-Presso',
      'Vitara Brezza',
      'Grand Vitara',
      'Ciaz',
      'Ignis',
      'XL6',
      'Jimny',
      'Fronx',
      'Maruti 800',
      'Esteem',
      'Kizashi',
      'A-Star',
    ],
  };

  @override
  void initState() {
    super.initState();
    if (widget.vehicleData == null) {
      _fetchVehicleData();
    } else {
      _populateFields(widget.vehicleData!);
      _fetchUserData();
    }
    if (widget.userData != null) {
      _userDetails(widget.userData!);
    }
  }

  Future<void> _fetchVehicleData() async {
    final vehicle = await _authService.getVehicleByNumber(widget.vehicleNumber);
    if (vehicle != null) {
      _populateFields(vehicle);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Vehicle not found in database.',
              style: GoogleFonts.jost(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  void _populateFields(Map<String, dynamic> data) {
    setState(() {
      selectedBrand = data['selectedBrand'] ?? 'Toyota';
      selectedModel = data['selectedModel'] ?? vehicleModels['Toyota']?[0];
      vehicleYearController.text =
          data['year']?.toString() ?? data['manufactureYear']?.toString() ?? '';
      userIdController.text =
          data['uid']?.toString() ?? data['userId']?.toString() ?? '';
    });
  }

  Future<void> _fetchUserData() async {
    if (userIdController.text.isEmpty) return;
    final userDoc = await _authService.getUserById(userIdController.text);
    if (userDoc != null) {
      _userDetails(userDoc);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'User not found in database.',
              style: GoogleFonts.jost(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  void _userDetails(Map<String, dynamic> data) {
    setState(() {
      nameController.text = data['Name'] ?? data['name'] ?? '';
      addressController.text = data['Address'] ?? data['address'] ?? '';
      contactController.text = data['Contact'] ?? data['contact'] ?? '';
      emailController.text = data['Email'] ?? data['email'] ?? '';
    });
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final isVehicleExisting = widget.vehicleData != null;

    Map<String, dynamic> userData = {
      'Name': nameController.text.trim(),
      'Address': addressController.text.trim(),
      'Contact': contactController.text.trim(),
      'Email': emailController.text.trim(),
    };

    Map<String, dynamic> vehicleData = {
      'vehicleNumber': widget.vehicleNumber,
      'selectedBrand': selectedBrand,
      'selectedModel': selectedModel,
      'year': vehicleYearController.text.trim(),
      'uid': userIdController.text,
      'userId': userIdController.text,
      'mileage': '100000',
      'vehicleType': 'Car',
      'vehiclePhotoUrl': null,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    if (isVehicleExisting) {
      final String uid =
          widget.vehicleData?['uid']?.toString() ??
          widget.vehicleData?['userId']?.toString() ??
          '';
      if (uid.isNotEmpty) {
        await _authService.updateUserById(uid, userData);
        await _authService.upsertVehicleByUserId(uid, vehicleData);
      }
    } else {
      final createdUser = await _authService.createUserById({
        ...userData,
        'userType': 'Vehicle Owner',
        'createdAt': DateTime.now().toIso8601String(),
      });

      final newUID =
          createdUser['uid']?.toString() ??
          createdUser['id']?.toString() ??
          createdUser['_id']?.toString() ??
          '';

      userIdController.text = newUID;

      await _authService.upsertVehicleByUserId(newUID, {
        ...vehicleData,
        'uid': newUID,
        'userId': newUID,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    if (mounted) {
      setState(() => isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddService(vehicleNumber: widget.vehicleNumber),
        ),
      );
    }
  }

  // ── Luxury text field ─────────────────────────────────────────────────────
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isEmail = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
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
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Enter a valid email';
          }
          return null;
        },
      ),
    );
  }

  // ── Luxury dropdown ───────────────────────────────────────────────────────
  Widget _buildDropdownField(
    String label,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: items.contains(selectedValue) ? selectedValue : null,
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
                  (item) => DropdownMenuItem<String>(
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
        validator: (value) => value == null ? 'Please select $label' : null,
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
        iconTheme: const IconThemeData(color: AppColors.gold),
        title: Text(
          'Vehicle: ${widget.vehicleNumber}',
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
              // ── Logo ───────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceDark,
                    border: Border.all(
                      color: AppColors.gold.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset('images/logo.png', fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Owner Info ────────────────────────────────────────────
              Text(
                'Owner Information',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              goldDivider(),

              _buildTextField(nameController, 'Name'),
              _buildTextField(addressController, 'Address'),
              _buildTextField(contactController, 'Contact'),
              _buildTextField(emailController, 'Email', isEmail: true),

              // ── Vehicle Info ──────────────────────────────────────────
              Text(
                'Vehicle Information',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              goldDivider(),

              _buildTextField(vehicleYearController, 'Vehicle Year'),

              _buildDropdownField(
                'Brand',
                vehicleModels.keys.toList(),
                selectedBrand,
                (value) {
                  setState(() {
                    selectedBrand = value;
                    selectedModel = vehicleModels[selectedBrand]?.first;
                  });
                },
              ),

              if (selectedBrand != null)
                _buildDropdownField(
                  'Model',
                  vehicleModels[selectedBrand] ?? [],
                  selectedModel,
                  (value) {
                    setState(() => selectedModel = value);
                  },
                ),

              const SizedBox(height: 8),

              // ── Continue Button ───────────────────────────────────────
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
                  onPressed: isLoading ? null : _handleContinue,
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.obsidian,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            'CONTINUE',
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
      ),
    );
  }
}
