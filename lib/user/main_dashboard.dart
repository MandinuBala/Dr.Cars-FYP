import 'dart:async';
import 'dart:convert';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/service/service_history.dart';
import 'package:dr_cars_fyp/admin/dashboard/vehicle_dashboard.dart';
import 'package:dr_cars_fyp/appointments/appointment_notification.dart';
import 'package:dr_cars_fyp/map/mapscreen.dart';
import 'package:dr_cars_fyp/user/user_profile.dart';
import 'package:dr_cars_fyp/recipt_notification/recipt_notification_page.dart';
import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/obd/OBD2.dart';
import 'package:dr_cars_fyp/service/service_records.dart';
import 'package:dr_cars_fyp/appointments/appointments.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;

const Color kAppBarColor = Colors.black;
const Color kAccentOrange = Color.fromARGB(255, 255, 99, 32);
const Color kBlueTint = Color.fromARGB(255, 243, 72, 33);
const Color kVehicleCardBg = Color(0xFFFAF7F7);
const Color kErrorRed = Colors.red;
const Color kIconBgOpacityBlue = Color.fromRGBO(0, 0, 255, .1);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  String userName = "Loading...";
  int _selectedIndex = 0;
  Map<String, dynamic>? vehicleData;
  bool isLoading = true;
  String? errorMessage;
  String? _vehicleImageUrl;
  bool _hasVehicleInfo = false;
  bool _checkingVehicleInfo = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchVehicleData();
    _checkVehicleSetup();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        setState(() => userName = "User");
        return;
      }
      setState(() {
        userName =
            user['Name']?.toString() ?? user['name']?.toString() ?? "User";
      });
    } catch (e) {
      setState(() => userName = "User");
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<void> _fetchVehicleData() async {
    try {
      final user = await _authService.getCurrentUser();
      final uid =
          user?['uid']?.toString() ??
          user?['id']?.toString() ??
          user?['_id']?.toString() ??
          user?['userId']?.toString();

      if (uid == null || uid.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = "Could not identify user";
        });
        return;
      }

      final vehicleDoc = await _authService.getVehicleByUserId(uid);
      if (vehicleDoc != null) {
        vehicleData = vehicleDoc;
        _vehicleImageUrl = vehicleData?['vehiclePhotoUrl'];
      } else {
        errorMessage =
            "No vehicle data found. Please add your vehicle in your profile.";
      }
    } catch (e) {
      errorMessage = "Failed to load vehicle data.";
      debugPrint("Error fetching vehicle data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkVehicleSetup() async {
    setState(() => _checkingVehicleInfo = true);
    try {
      final user = await _authService.getCurrentUser();
      final uid =
          user?['uid']?.toString() ??
          user?['id']?.toString() ??
          user?['_id']?.toString() ??
          user?['userId']?.toString();
      if (uid != null && uid.isNotEmpty) {
        final vehicleDoc = await _authService.getVehicleByUserId(uid);
        _hasVehicleInfo = vehicleDoc != null;
      }
    } catch (e) {
      debugPrint("Error checking vehicle setup: $e");
    }
    setState(() => _checkingVehicleInfo = false);
  }

  int getNextMaintenanceMileage(int current) => ((current ~/ 5000) + 1) * 5000;

  Future<Map<String, int>> _loadNotificationCounts() async {
    try {
      final vehicleNumber = vehicleData?['vehicleNumber']?.toString();
      if (vehicleNumber == null || vehicleNumber.isEmpty) {
        return {'receipts': 0, 'appointments': 0};
      }

      final receiptsResponse = await http.get(
        Uri.parse(
          '${_authService.baseUrl}/service-receipts/vehicle/${Uri.encodeComponent(vehicleNumber)}',
        ),
      );
      int receiptsCount = 0;
      if (receiptsResponse.statusCode == 200) {
        final decoded = jsonDecode(receiptsResponse.body) as List<dynamic>;
        receiptsCount =
            decoded
                .where(
                  (item) =>
                      ((item as Map<String, dynamic>)['status'] ??
                                  item['Status'])
                              ?.toString()
                              .toLowerCase() ==
                          'not confirmed' ||
                      ((item)['status'] ?? item['Status'])
                              ?.toString()
                              .toLowerCase() ==
                          'finished',
                )
                .length;
      }

      final appointmentsResponse = await http.get(
        Uri.parse(
          '${_authService.baseUrl}/appointments/vehicle/${Uri.encodeComponent(vehicleNumber)}',
        ),
      );
      int appointmentsCount = 0;
      if (appointmentsResponse.statusCode == 200) {
        final decoded = jsonDecode(appointmentsResponse.body) as List<dynamic>;
        appointmentsCount =
            decoded
                .where(
                  (item) =>
                      ((item as Map<String, dynamic>)['status'] ??
                                  item['Status'])
                              ?.toString()
                              .toLowerCase() ==
                          'accepted' ||
                      ((item)['status'] ?? item['Status'])
                              ?.toString()
                              .toLowerCase() ==
                          'rejected',
                )
                .length;
      }

      return {'receipts': receiptsCount, 'appointments': appointmentsCount};
    } catch (e) {
      debugPrint("Error loading notification counts: $e");
      return {'receipts': 0, 'appointments': 0};
    }
  }

  Widget _buildVehicleDashboardButton() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VehicleDashboardScreen()),
            ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: kIconBgOpacityBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.dashboard_customize,
                  color: Color.fromARGB(255, 243, 96, 33),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Dashboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'View real-time vehicle metrics and status',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartVehicleDashboardButton() {
    if (_checkingVehicleInfo) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_hasVehicleInfo) {
      return Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.orange,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Up Your Vehicle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Complete your vehicle profile to access the dashboard',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      );
    }
    return _buildVehicleDashboardButton();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = MediaQuery.of(context).size.width;
    final text = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'images/logo.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back',
                      style: text.bodyLarge?.copyWith(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (vehicleData?['vehicleNumber'] != null)
              FutureBuilder<Map<String, int>>(
                future: _loadNotificationCounts(),
                builder: (_, snap) {
                  if (!snap.hasData) return const SizedBox();
                  final counts = snap.data ?? {};
                  final receiptsCount = counts['receipts'] ?? 0;
                  final appointmentsCount = counts['appointments'] ?? 0;
                  final totalCount = receiptsCount + appointmentsCount;

                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder:
                                (_) => BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 4,
                                    sigmaY: 4,
                                  ),
                                  child: Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    backgroundColor: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            "Select Notification Type",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Divider(),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.receipt_long,
                                            ),
                                            title: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  "Receipt Notifications",
                                                ),
                                                if (receiptsCount > 0)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: kErrorRed,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '$receiptsCount',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) =>
                                                          const ReceiptNotificationPage(),
                                                ),
                                              );
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.calendar_today,
                                            ),
                                            title: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  "Appointment Notifications",
                                                ),
                                                if (appointmentsCount > 0)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: kErrorRed,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '$appointmentsCount',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) =>
                                                          const AppointmentNotificationPage(),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                          );
                        },
                      ),
                      if (totalCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: kErrorRed,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              '$totalCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Your Vehicle',
              style: text.headlineSmall?.copyWith(fontSize: 32),
            ),
            const SizedBox(height: 10),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  errorMessage!,
                  style: text.bodyLarge?.copyWith(color: kErrorRed),
                ),
              )
            else if (vehicleData == null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text("No vehicle data available", style: text.bodyLarge),
              )
            else
              Container(
                width: w,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child:
                          _vehicleImageUrl != null
                              ? Image.network(
                                _vehicleImageUrl!,
                                width: w,
                                height: 250,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Image.asset(
                                      'images/dashcar.png',
                                      width: w,
                                      height: 250,
                                      fit: BoxFit.cover,
                                    ),
                              )
                              : Image.asset(
                                'images/dashcar.png',
                                width: w,
                                height: 250,
                                fit: BoxFit.cover,
                              ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${vehicleData!['year'] ?? 'Year not specified'}",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${vehicleData!['selectedBrand'] ?? ''} ${vehicleData!['selectedModel'] ?? ''}",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '⚙️ ${vehicleData!['mileage'] ?? '0'} KM',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '🚗 ${vehicleData!['vehicleType'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (vehicleData!['vehicleNumber'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '🚗 ${vehicleData!['vehicleNumber']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AppointmentsPage(),
                        ),
                      ),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text(
                    'Make an Appointment',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ServiceRecordsPage()),
                      ),
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Add a Service Record',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Upcoming maintenance', style: text.titleMedium),
            ),
            InkWell(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ServiceRecordsPage()),
                  ),
              child: ListTile(
                title: Text(
                  vehicleData != null
                      ? "${vehicleData!['selectedBrand']} ${vehicleData!['selectedModel']} (${vehicleData!['year']})"
                      : '',
                ),
                subtitle: Text(
                  vehicleData != null
                      ? 'Next maintenance at: ${getNextMaintenanceMileage(int.tryParse(vehicleData!['mileage'].toString()) ?? 0)} KM'
                      : '',
                ),
                trailing: const Icon(Icons.build, color: Colors.orange),
              ),
            ),

            _buildSmartVehicleDashboardButton(),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: kAccentOrange,
        unselectedItemColor:
            theme.brightness == Brightness.light
                ? Colors.black
                : Colors.white70,
        currentIndex: _selectedIndex,
        onTap: (i) {
          if (i == _selectedIndex) return;
          setState(() => _selectedIndex = i);
          Widget target = widget;
          switch (i) {
            case 1:
              target = MapScreen();
              break;
            case 2:
              target = const OBD2Page();
              break;
            case 3:
              target = const ServiceHistorypage();
              break;
            case 4:
              target = const ProfileScreen();
              break;
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => target),
          );
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),
          BottomNavigationBarItem(
            icon: Image.asset('images/logo.png', width: 30, height: 30),
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}
