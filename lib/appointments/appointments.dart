import 'dart:convert';

import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/obd/OBD2.dart';
import 'package:dr_cars_fyp/service/service_history.dart';
import 'package:dr_cars_fyp/user/main_dashboard.dart';
import 'package:dr_cars_fyp/map/mapscreen.dart';
import 'package:dr_cars_fyp/user/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({Key? key}) : super(key: key);

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final AuthService _authService = AuthService();
  //  used this controller for save the vehicle number in the fire base
  final TextEditingController _vehicleNumberController =
      TextEditingController();
  bool _isLoading = true;

  final List<String> vehicleModels = [
    'Car',
    'Van',
    'Jeep',
    'Truck',
    'Motorcycle',
    'Three-Wheeler',
    'Bus',
  ];

  final List<String> serviceTypes = [
    'Full Service',
    'Oil and filter change',
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

  final List<String> branches = [
    // Western Province
    'Colombo',
    'Dehiwala',
    'Moratuwa',
    'Nugegoda',
    'Homagama',
    'Piliyandala',
    'Battaramulla',
    'Gampaha',
    'Negombo', 'Ja-Ela', 'Wattala', 'Ragama', 'Katunayake',
    'Kalutara',
    'Panadura',
    'Beruwala',
    'Horana',
    'Aluthgama',
    'Matugama',

    // Central Province
    'Kandy',
    'Peradeniya',
    'Katugastota',
    'Gampola',
    'Nawalapitiya',
    'Matale', 'Dambulla', 'Ukuwela', 'Rattota',
    'Nuwara Eliya', 'Hatton', 'Talawakele', 'Nanu Oya',

    // Southern Province
    'Galle', 'Unawatuna', 'Ambalangoda', 'Hikkaduwa',
    'Matara', 'Weligama', 'Akurassa', 'Dikwella',
    'Hambantota', 'Tangalle', 'Tissamaharama', 'Ambalantota',

    // Northern Province
    'Jaffna', 'Point Pedro', 'Chavakachcheri', 'Nallur',
    'Kilinochchi', 'Pallai', 'Paranthan',
    'Mannar', 'Thalaimannar', 'Pesalai',
    'Vavuniya', 'Cheddikulam', 'Nedunkeni',
    'Mullaitivu', 'Puthukkudiyiruppu', 'Oddusuddan',

    // Eastern Province
    'Batticaloa', 'Eravur', 'Kattankudy',
    'Ampara', 'Kalmunai', 'Sammanthurai', 'Akkaraipattu',
    'Trincomalee', 'Kinniya', 'Mutur', 'Kuchchaveli',

    // North Western Province
    'Kurunegala', 'Pannala', 'Nikaweratiya', 'Kuliyapitiya',
    'Puttalam', 'Wennappuwa', 'Chilaw', 'Anamaduwa',

    // North Central Province
    'Anuradhapura', 'Kekirawa', 'Medawachchiya', 'Mihintale',
    'Polonnaruwa', 'Hingurakgoda', 'Medirigiriya',

    // Uva Province
    'Badulla', 'Bandarawela', 'Hali-Ela', 'Diyatalawa',
    'Monaragala', 'Wellawaya', 'Bibile', 'Buttala',

    // Sabaragamuwa Province
    'Ratnapura', 'Balangoda', 'Eheliyagoda', 'Kuruwita',
    'Kegalle', 'Mawanella', 'Rambukkana', 'Warakapola',
  ];

  List<Map<String, dynamic>> _filteredServiceCenters = [];
  String? _selectedServiceCenterId;

  String? _selectedModel;
  List<String> _selectedServices = [];
  String? _selectedBranch;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _appointmentsCount = 0;

  String? _userPhoneNumber;
  String? _userId;

  List<DateTime> _unavailableDates = [];
  String? _selectedServiceCenterName; // Add this for display

  Future<void> _fetchAppointmentsForDate(DateTime date) async {
    try {
      // Convert date to start and end of day
      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await http.get(
        Uri.parse(
          '${_authService.baseUrl}/appointments/count?start=${Uri.encodeComponent(startOfDay.toIso8601String())}&end=${Uri.encodeComponent(endOfDay.toIso8601String())}',
        ),
      );

      int count = 0;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        count = (data['count'] as num?)?.toInt() ?? 0;
      }

      setState(() {
        _appointmentsCount = count;
      });
    } catch (e) {
      print('Error fetching appointments: $e');
      setState(() {
        _appointmentsCount = 0;
      });
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
      await _fetchAppointmentsForDate(pickedDate);
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() => _selectedTime = pickedTime);
    }
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUser();
    final uid =
        user?['uid']?.toString() ??
        user?['id']?.toString() ??
        user?['_id']?.toString() ??
        user?['userId']?.toString();

    if (uid != null && uid.isNotEmpty) {
      _userId = uid;
      final userDoc = await _authService.getUserById(uid);
      setState(() {
        _userPhoneNumber =
            userDoc?['Contact']?.toString() ?? userDoc?['contact']?.toString();
      });
    }
  }

  Future<void> _loadUnavailableDates() async {
    if (_selectedServiceCenterId == null) {
      setState(() => _unavailableDates = []);
      return;
    }

    try {
      final selectedCenter = _filteredServiceCenters.firstWhere(
        (center) => center['id'] == _selectedServiceCenterId,
      );
      String serviceCenterUid = selectedCenter['uid']?.toString() ?? '';
      setState(() => _selectedServiceCenterName = selectedCenter['name']);

      final response = await http.get(
        Uri.parse(
          '${_authService.baseUrl}/appointments/service-center/${Uri.encodeComponent(serviceCenterUid)}',
        ),
      );

      if (response.statusCode != 200) {
        return;
      }

      final appointmentsSnapshot = jsonDecode(response.body) as List<dynamic>;

      Map<String, int> dateCounts = {};

      for (var doc in appointmentsSnapshot) {
        final data = Map<String, dynamic>.from(doc as Map);
        final dateStr = data['date'];

        if (dateStr != null) {
          final date = DateTime.parse(dateStr);
          final dateKey =
              DateTime(date.year, date.month, date.day).toIso8601String();

          dateCounts[dateKey] = (dateCounts[dateKey] ?? 0) + 1;
        }
      }

      List<DateTime> unavailable = [];
      for (var entry in dateCounts.entries) {
        if (entry.value >= 5) {
          unavailable.add(DateTime.parse(entry.key));
        }
      }

      setState(() => _unavailableDates = unavailable);
    } catch (e) {
      print('Error loading unavailable dates from appointments: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadVehicleData();
    _loadUnavailableDates();
  }

  Future<void> _loadVehicleData() async {
    try {
      final user = await _authService.getCurrentUser();
      final uid =
          user?['uid']?.toString() ??
          user?['id']?.toString() ??
          user?['_id']?.toString() ??
          user?['userId']?.toString();

      if (uid != null && uid.isNotEmpty) {
        final vehicleDoc = await _authService.getVehicleByUserId(uid);

        if (vehicleDoc != null) {
          setState(() {
            _vehicleNumberController.text =
                vehicleDoc['vehicleNumber']?.toString() ??
                vehicleDoc['plateNumber']?.toString() ??
                '';
            _selectedModel = vehicleDoc['vehicleType']?.toString() ?? '';
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No vehicle information found. Please set up your vehicle first.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading vehicle data: $e')));
    }
  }

  /*Widget _buildAnimatedDropdown(
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

   Widget _buildAnimatedTimePicker({
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
  }*/

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAnimatedDropdown({
    required List<String> items,
    required String? selectedValue,
    required String hintText,
    required Function(String?) onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
        ),
        dropdownColor: Colors.white,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.deepPurple,
        ),
        items:
            items
                .map(
                  (item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                )
                .toList(),
        onChanged: onChanged,
        validator:
            (value) => (value == null || value.isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildMultiSelect() {
    return Wrap(
      spacing: 6.0,
      children:
          serviceTypes.map((service) {
            final isSelected = _selectedServices.contains(service);
            return FilterChip(
              label: Text(
                service,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              selected: isSelected,
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              selectedColor: const Color.fromARGB(255, 103, 101, 237),
              checkmarkColor: const Color.fromARGB(255, 216, 216, 216),
              elevation: 5,
              shadowColor: Colors.black,

              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedServices.add(service);
                  } else {
                    _selectedServices.remove(service);
                  }
                });
              },
            );
          }).toList(),
    );
  }

  Widget buildStyledDropdown({
    required List<String> items,
    required String? selectedValue,
    required String hintText,
    required ValueChanged<String?> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(25),
        child: DropdownButtonFormField<String>(
          value: selectedValue,
          onChanged: onChanged,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.deepPurple,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
          ),
          items:
              items.map((item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
          dropdownColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAnimatedDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _selectedDate ?? DateTime.now(),
          selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
          onDaySelected: (selectedDay, focusedDay) {
            bool isUnavailable = _unavailableDates.any(
              (d) =>
                  d.year == selectedDay.year &&
                  d.month == selectedDay.month &&
                  d.day == selectedDay.day,
            );
            setState(() => _selectedDate = selectedDay);
            if (_selectedServiceCenterName != null) {
              if (isUnavailable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "This date is fully booked for $_selectedServiceCenterName.",
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "This date is available for booking at $_selectedServiceCenterName.",
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 61, 168, 255),
                  const Color.fromARGB(255, 146, 129, 222),
                ],
              ),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple,
                  const Color.fromARGB(255, 204, 117, 219),
                ],
              ),
              shape: BoxShape.circle,
            ),
            selectedTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            todayTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            weekendTextStyle: TextStyle(color: Colors.deepOrangeAccent),
            outsideDaysVisible: false,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              color: Colors.deepPurple,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.deepPurple),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: Colors.deepPurple,
            ),
          ),

          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, date, _) {
              bool isUnavailable = _unavailableDates.any(
                (d) =>
                    d.year == date.year &&
                    d.month == date.month &&
                    d.day == date.day,
              );
              if (isUnavailable) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Full',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }
              return null;
            },
          ),
        ),
        if (_selectedDate != null && _appointmentsCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'There are $_appointmentsCount appointment(s) already scheduled for this date.',
                      style: TextStyle(color: Colors.orange[900], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedTimePicker() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(2, 5),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          onTap: _pickTime,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedTime == null
                      ? 'SELECT TIME'
                      : _selectedTime!.format(context),
                  style: TextStyle(
                    color: _selectedTime == null ? Colors.grey : Colors.black,
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.access_time, color: Colors.deepPurple),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    //required String hintText,
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    InputDecoration? decoration,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(2, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration:
            decoration ??
            InputDecoration(
              //hintText: hintText,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
            ),
        validator:
            (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 72, 64, 122),
        title: const Text(
          'Book Your Appointment',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 153, 113, 253), // light yellow
              Color.fromARGB(255, 0, 136, 248), // gold
              Color.fromARGB(255, 76, 37, 249), // vibrant orange
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: FractionallySizedBox(
                widthFactor: constraints.maxWidth > 600 ? 0.6 : 0.95,
                child: Card(
                  elevation: 10,
                  shadowColor: const Color.fromARGB(255, 74, 3, 198),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vehicle Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const Divider(
                            color: Color.fromARGB(255, 189, 7, 7),
                            thickness: 1.5,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Vehicle Number '),
                          _buildAnimatedTextField(
                            controller: _vehicleNumberController,

                            enabled: false,
                            decoration: InputDecoration(
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(
                                  color: Colors.deepPurple,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(
                                  color: Colors.deepPurpleAccent,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(
                                  color: Colors.purple,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                            ),
                          ),

                          const SizedBox(height: 16),
                          _buildLabel('Vehicle Model '),

                          DropdownButtonFormField<String>(
                            value: _selectedModel,
                            items:
                                vehicleModels
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(item),
                                      ),
                                    )
                                    .toList(),
                            onChanged: null,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Type of Service '),
                          _buildMultiSelect(),

                          const SizedBox(height: 16),

                          _buildLabel('City'),
                          _buildAnimatedDropdown(
                            items: branches..sort(),
                            hintText: 'Select City',
                            selectedValue: _selectedBranch,
                            onChanged: (value) async {
                              setState(() {
                                _selectedBranch = value;
                                _filteredServiceCenters = [];
                                _selectedServiceCenterId = null;
                              });

                              final centers = await _authService
                                  .getServiceCentersByCity(value ?? '');

                              setState(() {
                                _filteredServiceCenters =
                                    centers
                                        .map(
                                          (doc) => {
                                            'id':
                                                doc['_id']?.toString() ??
                                                doc['id']?.toString() ??
                                                doc['uid']?.toString() ??
                                                '',
                                            'name':
                                                doc['Service Center Name']
                                                    ?.toString() ??
                                                doc['serviceCenterName']
                                                    ?.toString() ??
                                                doc['name']?.toString() ??
                                                'Unknown',
                                            'uid':
                                                doc['uid']?.toString() ??
                                                doc['_id']?.toString() ??
                                                doc['id']?.toString() ??
                                                '',
                                          },
                                        )
                                        .toList();
                              });
                            },
                          ),

                          if (_filteredServiceCenters.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Select Service Center'),
                                DropdownButtonFormField<String>(
                                  value: _selectedServiceCenterId,
                                  items:
                                      _filteredServiceCenters.map((center) {
                                        return DropdownMenuItem<String>(
                                          value: center['id'],
                                          child: Text(center['name']),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setState(
                                      () => _selectedServiceCenterId = value,
                                    );
                                    _loadUnavailableDates(); // Update unavailable dates when service center changes
                                  },
                                  decoration: InputDecoration(
                                    hintText: "SELECT",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                  ),
                                ),
                              ],
                            ),

                          if (_filteredServiceCenters.isEmpty &&
                              _selectedBranch != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'No service centers available in this city.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),
                          _buildLabel('Preferred Date '),

                          _buildAnimatedDatePicker(),

                          const SizedBox(height: 16),

                          _buildLabel('Preferred Time '),
                          _buildAnimatedTimePicker(),
                          const SizedBox(height: 24),

                          Center(
                            child: SizedBox(
                              width: 180,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(180, 50),
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    9,
                                    23,
                                    111,
                                  ),
                                  shadowColor: Colors.purpleAccent,
                                  elevation: 8,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                onPressed: () async {
                                  if (_vehicleNumberController.text
                                          .trim()
                                          .isEmpty ||
                                      _selectedModel == null ||
                                      _selectedBranch == null ||
                                      _selectedDate == null ||
                                      _selectedTime == null ||
                                      _selectedServices.isEmpty ||
                                      _selectedServiceCenterId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please fill all required fields',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  if (_unavailableDates.any(
                                    (d) =>
                                        d.year == _selectedDate!.year &&
                                        d.month == _selectedDate!.month &&
                                        d.day == _selectedDate!.day,
                                  )) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'This date is fully booked. Please select another date.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  try {
                                    final selectedCenter =
                                        _filteredServiceCenters.firstWhere(
                                          (center) =>
                                              center['id'] ==
                                              _selectedServiceCenterId,
                                        );

                                    final response = await http.post(
                                      Uri.parse(
                                        '${_authService.baseUrl}/appointments',
                                      ),
                                      headers: {
                                        'Content-Type': 'application/json',
                                      },
                                      body: jsonEncode({
                                        'vehicleNumber':
                                            _vehicleNumberController.text
                                                .trim(),
                                        'vehicleModel': _selectedModel,
                                        'serviceTypes': _selectedServices,
                                        'branch': _selectedBranch,
                                        'date':
                                            _selectedDate!.toIso8601String(),
                                        'time': _selectedTime!.format(context),
                                        'timestamp':
                                            DateTime.now().toIso8601String(),
                                        'Contact': _userPhoneNumber,
                                        'userId': _userId,
                                        'serviceCenterUid':
                                            selectedCenter['uid'],
                                        'status': 'pending',
                                      }),
                                    );

                                    if (response.statusCode < 200 ||
                                        response.statusCode >= 300) {
                                      throw Exception(response.body);
                                    }

                                    /* await updateBookedDate(
                                      selectedCenter['uid'],
                                      _selectedDate!,
                                    );*/

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Appointment booked successfully!',
                                        ),
                                      ),
                                    );

                                    // Redirect to dashboard after short delay
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DashboardScreen(),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Schedule Appointment',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,

        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MapScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OBD2Page()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ServiceHistorypage()),
              );
              break;
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
              break;
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),
          BottomNavigationBarItem(
            icon: Image.asset('images/logo.png', height: 30),
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}
