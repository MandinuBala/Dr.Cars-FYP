import 'dart:convert';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/service/service_history.dart';
import 'package:dr_cars_fyp/settings/Settings.dart';
import 'package:dr_cars_fyp/map/mapscreen.dart';
import 'package:dr_cars_fyp/service/service_history.dart';
import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/user/main_dashboard.dart';
import 'package:dr_cars_fyp/obd/OBD2.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dr_cars_fyp/utils/vehicle_image_helper.dart';
import 'package:dr_cars_fyp/l10n/app_strings.dart';
import 'package:dr_cars_fyp/providers/locale_provider.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dr_cars_fyp/widgets/app_bottom_nav.dart';

int _selectedIndex = 4;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();
  String? selectedBrand;
  String? selectedModel;
  String? selectedType;
  TextEditingController mileageController = TextEditingController();
  TextEditingController yearController = TextEditingController();

  bool _isLoading = false;
  String? _vehiclePhotoUrl;
  bool _isInitialSetup = true;
  bool _isExpanded = false;
  String? _currentUserId;

  final Map<String, List<String>> vehicleModels = {
    'Toyota': [
      'Corolla',
      'Camry',
      'RAV4',
      'Highlander',
      'Aqua',
      'Axio',
      'Vitz',
      'Prius',
      'Crown',
      'Fortuner',
    ],
    'Nissan': [
      'Sunny',
      'X-Trail',
      'Juke',
      'Note',
      'Teana',
      'GT-R',
      'Sentra',
      'Patrol',
      '370Z',
    ],
    'Honda': [
      'Civic',
      'Accord',
      'CR-V',
      'Fit',
      'Vezel',
      'City',
      'Odyssey',
      'Freed',
    ],
    'Suzuki': [
      'Alto',
      'Wagon R',
      'Swift',
      'Baleno',
      'Vitara',
      'Ertiga',
      'Jimny',
      'Estilo',
    ],
    'Mazda': [
      'Mazda3',
      'Mazda6',
      'CX-3',
      'CX-5',
      'CX-9',
      'BT-50',
      'RX-8',
      'MX-5',
    ],
    'BMW': ['320i', 'X1', 'X3', 'X5', 'M3', 'Z4', '530e', '740i'],
    'Kia': [
      'Picanto',
      'Rio',
      'Sportage',
      'Seltos',
      'Sorento',
      'Cerato',
      'Stinger',
      'Carnival',
    ],
    'Hyundai': [
      'i10',
      'i20',
      'Elantra',
      'Tucson',
      'Santa Fe',
      'Accent',
      'Venue',
      'Creta',
    ],
  };

  final List<String> vehicleTypes = ['Car', 'SUV', 'Truck', 'Buses', 'Van'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Step 1: Read directly from SharedPreferences as the primary source
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString('currentUserId');

      print("DEBUG: cachedUserId from prefs = $cachedUserId");

      final user = await _authService.getCurrentUser();

      print("DEBUG: getCurrentUser returned = $user");

      if (user != null) {
        final uid =
            user['uid']?.toString() ??
            user['id']?.toString() ??
            user['_id']?.toString() ??
            user['userId']?.toString() ??
            cachedUserId; // fallback to cached

        print("DEBUG: resolved uid = $uid");

        if (uid != null && uid.isNotEmpty) {
          _currentUserId = uid;

          nameController.text =
              user['Name']?.toString() ?? user['name']?.toString() ?? '';
          emailController.text =
              user['Email']?.toString() ?? user['email']?.toString() ?? '';

          final vehicleDoc = await _authService.getVehicleByUserId(uid);
          if (vehicleDoc != null) {
            setState(() {
              _isInitialSetup = false;
              vehicleNumberController.text =
                  vehicleDoc['vehicleNumber']?.toString() ?? '';
              selectedBrand = vehicleDoc['selectedBrand']?.toString();
              selectedModel = vehicleDoc['selectedModel']?.toString();
              selectedType = vehicleDoc['vehicleType']?.toString();
              mileageController.text = vehicleDoc['mileage']?.toString() ?? '';
              yearController.text = vehicleDoc['year']?.toString() ?? '';
              _vehiclePhotoUrl = vehicleDoc['vehiclePhotoUrl']?.toString();
            });
          }
        }
      } else if (cachedUserId != null && cachedUserId.isNotEmpty) {
        // API failed but we still have the ID cached — use it
        print("DEBUG: user null but using cachedUserId = $cachedUserId");
        setState(() => _currentUserId = cachedUserId);
      } else {
        print("DEBUG: No user found anywhere — not logged in?");
      }
    } catch (e) {
      print("Error loading user/vehicle data: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile data')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  ();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.obsidian,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.home, color: AppColors.gold),
              onPressed: () => _navigateToDashboard(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.gold),
                onPressed: _loadUserData,
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: AppColors.gold),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child:
                    _isInitialSetup
                        ? _buildInitialSetupForm(lang)
                        : _buildVehiclePanel(lang),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavBar(),
        );
      },
    );
  }

  Widget _buildVehiclePanel(String lang) {
    return Column(
      children: [
        Card(
          elevation: 2,
          child: ExpansionTile(
            leading: VehicleImageHelper.buildFittedImage(
              brand: selectedBrand,
              model: selectedModel,
              photoUrl: _vehiclePhotoUrl,
              size: 50,
            ),
            title: Text(
              '${selectedBrand ?? ''} ${selectedModel ?? ''}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(vehicleNumberController.text),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Vehicle Type', selectedType ?? ''),
                    _buildInfoRow('Mileage', '${mileageController.text} km'),
                    _buildInfoRow('Year', yearController.text),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isInitialSetup = true;
                        });
                      },
                      child: Text(AppStrings.get('edit_vehicle', lang)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.obsidian,
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInitialSetupForm(String lang) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child:
                  _vehiclePhotoUrl != null
                      ? ClipOval(
                        child: Image.network(
                          _vehiclePhotoUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                      : Stack(
                        alignment: Alignment.center,
                        children: [
                          VehicleImageHelper.buildFittedImage(
                            brand: selectedBrand,
                            model: selectedModel,
                            size: 150,
                            backgroundColor: Colors.grey.shade100,
                          ),
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.3),
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
          SizedBox(height: 10),
          Text(
            AppStrings.get('vehicle_information_setup', lang),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _buildBrandDropdown(lang),
          _buildModelDropdown(lang),
          _buildTypeDropdown(lang),
          SizedBox(height: 20),
          _buildTextField(
            controller: vehicleNumberController,
            label: "Vehicle Number",
            hintText: "Enter vehicle number",
          ),
          _buildTextField(
            controller: mileageController,
            label: "Mileage (km)",
            hintText: "Enter mileage",
          ),
          _buildTextField(
            controller: yearController,
            label: "Manufacture Year",
            hintText: "Enter year",
          ),
          SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.obsidian,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: _isLoading ? null : () => _saveProfile(),
            child: Text(
              AppStrings.get('save_vehicle', lang),
              style: GoogleFonts.jost(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 1.5,
                color: AppColors.obsidian,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return AppBottomNav(currentIndex: 4);
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_currentUserId == null || _currentUserId!.isEmpty) {
          throw Exception("User not authenticated");
        }

        Map<String, dynamic> vehicleData = {
          'uid': _currentUserId,
          'vehicleNumber': vehicleNumberController.text,
          'selectedBrand': selectedBrand,
          'selectedModel': selectedModel,
          'vehicleType': selectedType,
          'mileage': int.tryParse(mileageController.text) ?? 0,
          'year': yearController.text,
          'vehiclePhotoUrl': _vehiclePhotoUrl,
          'lastUpdated': DateTime.now().toIso8601String(),
        };

        final response = await http.put(
          Uri.parse('${_authService.baseUrl}/vehicles/by-user/$_currentUserId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(vehicleData),
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('Failed to save vehicle data');
        }

        _showPopupMessage(
          context,
          "Success",
          "Vehicle information saved successfully!",
        );

        setState(() => _isInitialSetup = false);
      } catch (e) {
        print("Error saving vehicle info: $e");
        _showPopupMessage(
          context,
          "Error",
          "Failed to save vehicle data: ${e.toString()}",
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPopupMessage(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToDashboard(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DashboardScreen()),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildBrandDropdown(String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "Vehicle Brand",
          border: OutlineInputBorder(),
        ),
        value: selectedBrand,
        items:
            vehicleModels.keys
                .map(
                  (brand) => DropdownMenuItem(value: brand, child: Text(brand)),
                )
                .toList(),
        onChanged: (value) {
          setState(() {
            selectedBrand = value;
            selectedModel = null;
          });
        },
        hint: Text(AppStrings.get('select_brand', lang)),
      ),
    );
  }

  Widget _buildModelDropdown(String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "Vehicle Model",
          border: OutlineInputBorder(),
        ),
        value: selectedModel,
        items:
            (selectedBrand != null && vehicleModels[selectedBrand] != null)
                ? vehicleModels[selectedBrand]!
                    .map(
                      (model) =>
                          DropdownMenuItem(value: model, child: Text(model)),
                    )
                    .toList()
                : [],
        onChanged: (value) {
          setState(() {
            selectedModel = value;
          });
        },
        hint: Text(
          selectedBrand == null
              ? AppStrings.get('select_brand_first', lang)
              : AppStrings.get('select_model', lang),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown(String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "Vehicle Type",
          border: OutlineInputBorder(),
        ),
        value: selectedType,
        items:
            vehicleTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
        onChanged: (value) {
          setState(() {
            selectedType = value;
          });
        },
        hint: Text(AppStrings.get('select_type', lang)),
      ),
    );
  }
}
