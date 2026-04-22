import 'dart:convert';
import 'package:dr_cars_fyp/service/service_history.dart';
import 'package:dr_cars_fyp/user/main_dashboard.dart';
import 'package:dr_cars_fyp/map/mapscreen.dart';
import 'package:dr_cars_fyp/user/user_profile.dart';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VehicleDashboardScreen extends StatefulWidget {
  const VehicleDashboardScreen({Key? key}) : super(key: key);

  @override
  _VehicleDashboardScreenState createState() => _VehicleDashboardScreenState();
}

class _VehicleDashboardScreenState extends State<VehicleDashboardScreen> {
  bool _isLoading = true;
  final AuthService _authService = AuthService();
  Map<String, dynamic>? vehicleData;
  String? vehicleType;
  String? vehicleBrand;
  String? vehicleModel;
  int _selectedIndex = 0;
  List<String> brandIndicatorImages = [];

  // Status mapping - can be updated from Firestore in a real implementation
  final Map<String, Map<String, dynamic>> statusInfo = {
    'Engine Status': {'value': 'Normal', 'color': Colors.green},
    'Fuel Level': {'value': '75%', 'color': Colors.green},
    'Engine Temp': {'value': '90°C', 'color': Colors.green},
    'Battery': {'value': '12.6V', 'color': Colors.green},
    'Parking Brake': {'value': 'Released', 'color': Colors.green},
    'Seatbelts': {'value': 'All Fastened', 'color': Colors.green},
    'ABS Status': {'value': 'Active', 'color': Colors.green},
    'Doors': {'value': 'All Closed', 'color': Colors.green},
    'Oil Level': {'value': 'Normal', 'color': Colors.green},
    'Tire Pressure': {'value': '35 PSI', 'color': Colors.green},
    'Brake System': {'value': 'Normal', 'color': Colors.green},
  };

  // Indicator explanations
  final Map<String, String> explanations = {
    'images/BMW/123.png':
        '🔋 Battery Warning:\n- Problem: Issue with battery or charging system.\n- Action: Check battery connections or have it inspected by a technician.',

    'images/BMW/ABS.png':
        '⚠️ ABS Warning:\n- Problem: ABS may not be functioning properly.\n- Action: Brakes will still work, but without anti-lock function. Get system checked soon.',

    'images/BMW/airbag waring.png':
        '🎈 Airbag Warning:\n- Problem: Airbag or SRS system malfunction.\n- Action: Have the airbag system inspected to ensure safety in a crash.',

    'images/BMW/breake.png':
        '🛑 Brake System Warning:\n- Problem: Issue with brake system or low brake fluid.\n- Action: Check brake fluid level and brake performance immediately.',

    'images/BMW/check engine.png':
        '🛠️ Check Engine Warning:\n- Problem: Engine or emissions system malfunction.\n- Action: Drive moderately and have the engine diagnosed as soon as possible.',

    'images/BMW/e brake.png':
        '⛔ Auto Brake Hold:\n- Problem: Automatic brake hold system is active.\n- Action: No action needed unless stuck; disables when accelerator is pressed.',

    'images/BMW/fog lights.png':
        '🌁 Fog Lights On:\n- Problem: Fog lights are active.\n- Action: Use only in foggy or low-visibility conditions.',

    'images/BMW/fuel low.png':
        '⛽ Low Fuel Warning:\n- Problem: Fuel level is low.\n- Action: Refuel the vehicle as soon as possible to avoid running out.',

    'images/BMW/glow.png':
        '🌡️ Diesel Pre-Heating:\n- Problem: Diesel glow plugs are warming up.\n- Action: Wait until the light turns off before starting the engine (for diesel engines).',

    'images/BMW/high heat.png':
        '🌡️ Engine Overheating:\n- Problem: Engine temperature is too high.\n- Action: Pull over safely, turn off engine, let it cool. Check coolant level.',

    'images/BMW/oil light.png':
        '🛢️ Oil Pressure Warning:\n- Problem: Low oil pressure.\n- Action: Stop engine immediately. Check and refill oil. Seek service if light remains on.',

    'images/BMW/seatbelt.png':
        '🔔 Seatbelt Reminder:\n- Problem: One or more seatbelts unfastened.\n- Action: Ensure all occupants fasten their seatbelts.',

    'images/BMW/tire presure waring.png':
        '🚨 Tire Pressure Warning:\n- Problem: One or more tires may be underinflated.\n- Action: Check all tires and inflate to recommended pressure.',

    'images/BMW/TRC.png':
        '🚗 Traction Control Warning:\n- Problem: Traction control is active or malfunctioning.\n- Action: Drive cautiously on slippery roads. If warning stays, check system.',

    'images/BMW/warning.png':
        '⚠️ General Warning:\n- Problem: Non-specific issue with the vehicle.\n- Action: Check iDrive system or consult user manual for details.',

    'images/BMW/window heater.png':
        '❄️ Rear Window Defroster:\n- Problem: Rear window defroster is on.\n- Action: No issue. Helps clear frost or condensation.',

    // Toyota indicators
    'images/Toyota/ABS.png':
        'ABS Warning: Indicates a problem with the Anti-lock Braking System.\n Action: Safely stop the vehicle and have it inspected by a qualified technician.',
    'images/Toyota/BATTERY CHECK.png':
        'Battery Warning: Issue with battery or charging system.\n Action: Check battery connections and voltage; recharge or replace battery if necessary.',
    'images/Toyota/DOORS OPEND.png':
        'Door Ajar Warning: One or more doors are not fully closed.\n Action: Stop the vehicle in a safe place and ensure all doors are properly closed.',
    'images/Toyota/ENGINE CHECK LIGHT.png':
        'Check Engine Warning: Engine malfunction detected.\n Action: Reduce vehicle speed and have the engine checked by a qualified technician.',
    'images/Toyota/HAND BREAK.png':
        'Parking Brake: Parking brake is currently engaged.\n Action: Release the parking brake before driving.',
    'images/Toyota/HAZARD.png':
        'Hazard Lights: Hazard warning lights are active.\n Action: Check the reason for hazard light activation (e.g., breakdown, emergency stop).',
    'images/Toyota/HEAD BEAM.png':
        'High Beam: High beam headlights are currently active.\n Action: Switch to low beams when approaching other vehicles or in well-lit areas.',
    'images/Toyota/LOW BEAM.png':
        'Low Beam: Low beam headlights are currently active.\n Action: Ensure headlights are properly adjusted for optimal visibility.',
    'images/Toyota/LOW FUEL.png':
        'Low Fuel Warning: Fuel level is low, refuel soon.\n Action: Refuel at the nearest gas station to avoid running out of fuel.',
    'images/Toyota/seat bealts.png':
        'Seatbelt Reminder: One or more seatbelts are not fastened.\n Action: Ensure all passengers fasten their seatbelts for safety.',
    'images/Toyota/WATER HEAT.png':
        'Engine Temperature Warning: Engine is overheating.\n Action: Turn off the engine and allow it to cool down. Check coolant level and radiator for leaks.',
    'images/Toyota/WINDSCREEN WASHER LIQUID LOW.png':
        'Washer Fluid Warning: Windshield washer fluid is low.\n Action: Refill windshield washer fluid reservoir as soon as possible.',
  };

  // Indicator title mapping
  final Map<String, String> indicatorTitles = {
    // BMW
    'images/BMW/check engine.png': 'Engine Status',
    'images/BMW/fuel low.png': 'Fuel Level',
    'images/BMW/oil light.png': 'Oil Level',
    'images/BMW/high heat.png': 'Engine Temp',
    'images/BMW/tire presure waring.png': 'Tire Pressure',
    'images/BMW/breake.png': 'Brake System',
    'images/BMW/ABS.png': 'ABS Status',
    'images/BMW/seatbelt.png': 'Seatbelts',
    'images/BMW/123.png': 'Battery Warning',
    'images/BMW/airbag waring.png': 'Airbag Warning',
    'images/BMW/e brake.png': 'Auto Brake Hold',
    'images/BMW/fog lights.png': 'Fog Lights',
    'images/BMW/glow.png': 'Diesel Preheat',
    'images/BMW/TRC.png': 'Traction Control',
    'images/BMW/warning.png': 'Warning',
    'images/BMW/window heater.png': 'Window Defroster',

    // Toyota
    'images/Toyota/ENGINE CHECK LIGHT.png': 'Engine Status',
    'images/Toyota/LOW FUEL.png': 'Fuel Level',
    'images/Toyota/WATER HEAT.png': 'Engine Temp',
    'images/Toyota/BATTERY CHECK.png': 'Battery',
    'images/Toyota/HAND BREAK.png': 'Parking Brake',
    'images/Toyota/seat bealts.png': 'Seatbelts',
    'images/Toyota/ABS.png': 'ABS Status',
    'images/Toyota/DOORS OPEND.png': 'Doors',
    'images/Toyota/HAZARD.png': 'Hazard Lights',
    'images/Toyota/HEAD BEAM.png': 'High Beam',
    'images/Toyota/LOW BEAM.png': 'Low Beam',
    'images/Toyota/WINDSCREEN WASHER LIQUID LOW.png': 'Washer Fluid',
  };

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  Future<void> _loadVehicleData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = await _authService.getCurrentUser();
      // get user from your backend/session
      if (currentUser != null) {
        final uid = currentUser['uid']; // adapt to your backend field

        // Fetch vehicle data via API
        final vehicleDataFromApi = await _authService.getVehicleByUserId(uid);

        if (vehicleDataFromApi != null) {
          setState(() {
            vehicleData = vehicleDataFromApi;
            vehicleType = vehicleData!['vehicleType'];
            vehicleBrand = vehicleData!['selectedBrand'];
            vehicleModel = vehicleData!['selectedModel'];
          });

          // Load all indicator images for the selected brand
          await _loadIndicatorImages();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No vehicle information found. Please set up your vehicle first.',
              ),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print("Error loading vehicle data: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading vehicle data')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadIndicatorImages() async {
    // Clear previous list
    brandIndicatorImages = [];

    if (vehicleBrand == null) return;

    try {
      // Load all images from the brand's folder
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map<String, dynamic>.from(
        jsonDecode(manifestContent) as Map,
      );

      final imagePaths =
          manifestMap.keys
              .where(
                (String key) =>
                    key.contains('images/${vehicleBrand}/') &&
                    key.endsWith('.png'),
              )
              .toList();

      setState(() {
        brandIndicatorImages = imagePaths;
      });

      print(
        "Loaded ${brandIndicatorImages.length} indicators for $vehicleBrand",
      );
    } catch (e) {
      print("Error loading indicator images: $e");
      // Fallback to hardcoded paths if needed
      _loadFallbackImages();
    }
  }

  void _loadFallbackImages() {
    // Fallback images if dynamic loading fails
    if (vehicleBrand?.toLowerCase() == 'bmw') {
      brandIndicatorImages = [
        'images/BMW/check engine.png',
        'images/BMW/fuel low.png',
        'images/BMW/oil light.png',
        'images/BMW/high heat.png',
        'images/BMW/tire presure waring.png',
        'images/BMW/breake.png',
        'images/BMW/ABS.png',
        'images/BMW/seatbelt.png',
        'images/BMW/123.png',
        'images/BMW/airbag waring.png',
        'images/BMW/e brake.png',
        'images/BMW/fog lights.png',
        'images/BMW/glow.png',
        'images/BMW/TRC.png',
        'images/BMW/warning.png',
        'images/BMW/window heater.png',
      ];
    } else if (vehicleBrand?.toLowerCase() == 'toyota') {
      brandIndicatorImages = [
        'images/Toyota/ENGINE CHECK LIGHT.png',
        'images/Toyota/LOW FUEL.png',
        'images/Toyota/WATER HEAT.png',
        'images/Toyota/BATTERY CHECK.png',
        'images/Toyota/HAND BREAK.png',
        'images/Toyota/seat bealts.png',
        'images/Toyota/ABS.png',
        'images/Toyota/DOORS OPEND.png',
        'images/Toyota/HAZARD.png',
        'images/Toyota/HEAD BEAM.png',
        'images/Toyota/LOW BEAM.png',
        'images/Toyota/WINDSCREEN WASHER LIQUID LOW.png',
      ];
    }
  }

  Widget _buildVehicleInfo() {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  vehicleData?['vehiclePhotoUrl'] != null
                      ? NetworkImage(vehicleData!['vehiclePhotoUrl'])
                      : AssetImage('images/logo.png') as ImageProvider,
              radius: 30,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$vehicleBrand $vehicleModel',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    vehicleData?['vehicleNumber'] ?? 'Unknown',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    'Type: $vehicleType | Year: ${vehicleData?['year']}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTileWithImage(
    String imagePath,
    String title,
    String value,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        _showIndicatorInfo(imagePath, title);
      },
      child: Card(
        elevation: 5,
        shadowColor: const Color.fromARGB(255, 74, 3, 198),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                imagePath,
                height: 60,
                width: 60,
                errorBuilder: (context, error, stackTrace) {
                  print("Error loading image $imagePath: $error");
                  return Icon(Icons.error_outline, size: 60, color: Colors.red);
                },
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIndicatorInfo(String imagePath, String title) {
    final String explanation =
        explanations[imagePath] ??
        'No additional information available for this indicator.';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                imagePath,
                height: 80,
                width: 80,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.error_outline, size: 80, color: Colors.red);
                },
              ),
              SizedBox(height: 16),
              Text(
                explanation,
                style: TextStyle(fontSize: 18, height: 1.3),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close', style: TextStyle(fontSize: 18)),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildAllIndicatorTiles() {
    List<Widget> widgets = [];

    if (brandIndicatorImages.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "No indicator images found for $vehicleBrand",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ];
    }

    for (String imagePath in brandIndicatorImages) {
      // Get title from mapping or use fallback
      String title =
          indicatorTitles[imagePath] ??
          imagePath.split('/').last.replaceAll('.png', '').replaceAll('_', ' ');

      // Get status from mapping or use default
      Map<String, dynamic> status =
          statusInfo[title] ?? {'value': 'Normal', 'color': Colors.green};

      widgets.add(
        _buildDashboardTileWithImage(
          imagePath,
          title,
          status['value'],
          status['color'],
        ),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vehicle Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 72, 64, 122),
        foregroundColor: Colors.white,
        elevation: 0,

        iconTheme: IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadVehicleData();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVehicleInfo(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dashboard Indicators',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${brandIndicatorImages.length} indicators',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: EdgeInsets.all(16),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: _buildAllIndicatorTiles(),
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
          setState(() {
            _selectedIndex = index;
          });

          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MapScreen()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ServiceHistorypage()),
            );
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 24),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map, size: 24),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('images/logo.png', height: 24),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history, size: 24),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 24),
            label: '',
          ),
        ],
      ),
    );
  }
}
