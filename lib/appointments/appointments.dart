// lib/appointments/appointments.dart
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
import 'package:dr_cars_fyp/l10n/app_strings.dart';
import 'package:dr_cars_fyp/providers/locale_provider.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dr_cars_fyp/widgets/app_bottom_nav.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({Key? key}) : super(key: key);

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final AuthService _authService = AuthService();
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

  static const Map<String, Map<String, String>> _serviceTypeTranslations = {
    'Full Service': {'si': 'සම්පූර්ණ සේවාව', 'ta': 'முழு சேவை'},
    'Oil Filter Change': {
      'si': 'තෙල් පෙරහන් මාරුව',
      'ta': 'எண்ணெய் வடிகட்டி மாற்றம்',
    },
    'Tire pressure and rotation check': {
      'si': 'ටයර් පීඩන පරීක්ෂාව',
      'ta': 'டயர் அழுத்த சோதனை',
    },
    'Fluid level check': {'si': 'තරල මට්ටම් පරීක්ෂාව', 'ta': 'திரவ அளவு சோதனை'},
    'Battery check and replacements': {
      'si': 'බැටරි පරීක්ෂාව',
      'ta': 'பேட்டரி சோதனை',
    },
    'Wiper blade replacement': {
      'si': 'වයිපර් තලය මාරුව',
      'ta': 'வைப்பர் மாற்றம்',
    },
    'Light bulb check': {'si': 'ලාම්පු පරීක්ෂාව', 'ta': 'விளக்கு சோதனை'},
    'Brake system services': {'si': 'බ්‍රේක් සේවාව', 'ta': 'பிரேக் சேவை'},
    'Suspension and alignment services': {
      'si': 'සසස්පෙන්ෂන් සේවාව',
      'ta': 'சஸ்பென்ஷன் சேவை',
    },
    'Exhaust system service': {
      'si': 'නික්මෙන් ගෑස් සේවාව',
      'ta': 'எக்ஸாஸ்ட் சேவை',
    },
    'Air conditioning services': {
      'si': 'ශීතකරණ සේවාව',
      'ta': 'குளிரூட்டல் சேவை',
    },
    'Electrical system services': {'si': 'විදුලි සේවාව', 'ta': 'மின் சேவை'},
    'Car detailing (Interior and exterior cleaning, waxing)': {
      'si': 'වාහන පිරිසිදු කිරීම',
      'ta': 'கார் சுத்தம்',
    },
    'Tire sales and installation': {'si': 'ටයර් විකිණීම', 'ta': 'டயர் விற்பனை'},
    'Pre-purchase inspections': {
      'si': 'මිලදී ගැනීමට පෙර පරීක්ෂාව',
      'ta': 'வாங்கும் முன் சோதனை',
    },
    'Diagnostic testing': {'si': 'රෝග නිර්ණය', 'ta': 'நோயறிதல் சோதனை'},
  };

  String _translateServiceType(String type, String lang) {
    if (lang == 'en') return type;
    return _serviceTypeTranslations[type]?[lang] ?? type;
  }

  final List<String> branches = [
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
  String? _selectedServiceCenterName;

  Future<void> _fetchAppointmentsForDate(DateTime date) async {
    try {
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
      setState(() => _appointmentsCount = count);
    } catch (e) {
      setState(() => _appointmentsCount = 0);
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.gold,
                onPrimary: AppColors.obsidian,
                surface: AppColors.surfaceDark,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          ),
    );
    if (pickedTime != null) setState(() => _selectedTime = pickedTime);
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
      if (response.statusCode != 200) return;

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
        if (entry.value >= 5) unavailable.add(DateTime.parse(entry.key));
      }
      setState(() => _unavailableDates = unavailable);
    } catch (e) {
      print('Error loading unavailable dates: $e');
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
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ── Luxury label ──────────────────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.jost(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
          color: AppColors.gold,
        ),
      ),
    );
  }

  // ── Unified dark dropdown ─────────────────────────────────────────────────
  Widget _buildDarkDropdown({
    required List<String> items,
    required String? selectedValue,
    required String hintText,
    required Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGold),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        isExpanded: true,
        style: GoogleFonts.jost(color: AppColors.textPrimary, fontSize: 14),
        dropdownColor: AppColors.surfaceElevated,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.gold,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.jost(color: AppColors.textMuted, fontSize: 14),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
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
        selectedItemBuilder:
            (context) =>
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
        onChanged: enabled ? onChanged : null,
        validator:
            (value) => (value == null || value.isEmpty) ? 'Required' : null,
      ),
    );
  }

  // ── Unified dark text field ───────────────────────────────────────────────
  Widget _buildDarkTextField({
    required TextEditingController controller,
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    InputDecoration? decoration,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.jost(color: AppColors.textPrimary, fontSize: 14),
        decoration:
            decoration ??
            InputDecoration(
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
              disabledBorder: OutlineInputBorder(
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
        validator:
            (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  // ── Service chips ─────────────────────────────────────────────────────────
  Widget _buildMultiSelect(String lang) {
    return Wrap(
      spacing: 6.0,
      runSpacing: 6.0,
      children:
          serviceTypes.map((service) {
            final isSelected = _selectedServices.contains(service);
            return FilterChip(
              label: Text(
                _translateServiceType(service, lang),
                style: GoogleFonts.jost(
                  color:
                      isSelected ? AppColors.obsidian : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isSelected,
              backgroundColor: AppColors.surfaceElevated,
              selectedColor: AppColors.gold,
              checkmarkColor: AppColors.obsidian,
              elevation: 0,
              side: BorderSide(
                color: isSelected ? AppColors.gold : AppColors.borderGold,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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

  // ── Calendar ──────────────────────────────────────────────────────────────
  Widget _buildCalendar() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGold),
          ),
          child: TableCalendar(
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor:
                        isUnavailable ? AppColors.error : AppColors.success,
                    content: Text(
                      isUnavailable
                          ? 'This date is fully booked for $_selectedServiceCenterName.'
                          : 'This date is available at $_selectedServiceCenterName.',
                      style: GoogleFonts.jost(color: Colors.white),
                    ),
                  ),
                );
              }
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.goldMuted,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: GoogleFonts.jost(
                color: AppColors.obsidian,
                fontWeight: FontWeight.bold,
              ),
              todayTextStyle: GoogleFonts.jost(
                color: AppColors.obsidian,
                fontWeight: FontWeight.bold,
              ),
              weekendTextStyle: GoogleFonts.jost(color: AppColors.error),
              defaultTextStyle: GoogleFonts.jost(color: AppColors.textPrimary),
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(4),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.cormorantGaramond(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: AppColors.gold,
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: AppColors.gold,
              ),
              headerPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.jost(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              weekendStyle: GoogleFonts.jost(
                color: AppColors.error,
                fontSize: 12,
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
                        style: GoogleFonts.jost(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Full',
                        style: GoogleFonts.jost(
                          color: AppColors.error,
                          fontSize: 8,
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
        ),
        if (_selectedDate != null && _appointmentsCount > 0)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'There are $_appointmentsCount appointment(s) already on this date.',
                    style: GoogleFonts.jost(
                      color: AppColors.warning,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Time picker ───────────────────────────────────────────────────────────
  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGold),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedTime == null
                  ? 'SELECT TIME'
                  : _selectedTime!.format(context),
              style: GoogleFonts.jost(
                color:
                    _selectedTime == null
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const Icon(Icons.access_time, color: AppColors.gold, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.richBlack,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppColors.richBlack,
          appBar: AppBar(
            backgroundColor: AppColors.obsidian,
            foregroundColor: AppColors.textPrimary,
            title: Text(
              AppStrings.get('book_appointment', lang),
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                size: 20,
                color: AppColors.gold,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Vehicle Details ───────────────────────────────────────
                Text(
                  AppStrings.get('vehicle_details', lang),
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                goldDivider(),

                _buildLabel(AppStrings.get('vehicle_number', lang)),
                _buildDarkTextField(
                  controller: _vehicleNumberController,
                  enabled: false,
                ),

                _buildLabel(AppStrings.get('vehicle_model', lang)),
                _buildDarkDropdown(
                  items: vehicleModels,
                  selectedValue: _selectedModel,
                  hintText: 'Select model',
                  onChanged: (_) {},
                  enabled: false,
                ),

                // ── Type of Service ───────────────────────────────────────
                _buildLabel(AppStrings.get('type_of_service', lang)),
                _buildMultiSelect(lang),
                const SizedBox(height: 16),

                // ── City ─────────────────────────────────────────────────
                _buildLabel(AppStrings.get('city', lang)),
                _buildDarkDropdown(
                  items: branches..sort(),
                  selectedValue: _selectedBranch,
                  hintText: AppStrings.get('select_city', lang),
                  onChanged: (value) async {
                    setState(() {
                      _selectedBranch = value;
                      _filteredServiceCenters = [];
                      _selectedServiceCenterId = null;
                    });
                    final centers = await _authService.getServiceCentersByCity(
                      value ?? '',
                    );
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
                                      doc['Service Center Name']?.toString() ??
                                      doc['serviceCenterName']?.toString() ??
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

                // ── Service Center ────────────────────────────────────────
                if (_filteredServiceCenters.isNotEmpty) ...[
                  _buildLabel(AppStrings.get('select_service_center', lang)),
                  _buildDarkDropdown(
                    items:
                        _filteredServiceCenters
                            .map((c) => c['name'].toString())
                            .toList(),
                    selectedValue:
                        (() {
                          if (_selectedServiceCenterId == null) return null;
                          final matches =
                              _filteredServiceCenters
                                  .where(
                                    (c) => c['id'] == _selectedServiceCenterId,
                                  )
                                  .toList();
                          return matches.isEmpty
                              ? null
                              : matches.first['name'].toString();
                        })(),
                    hintText: 'SELECT',
                    onChanged: (name) {
                      if (name == null) return;
                      final matches =
                          _filteredServiceCenters
                              .where((c) => c['name'] == name)
                              .toList();
                      if (matches.isEmpty) return;
                      setState(
                        () =>
                            _selectedServiceCenterId =
                                matches.first['id'].toString(),
                      );
                      _loadUnavailableDates();
                    },
                  ),
                ],

                if (_filteredServiceCenters.isEmpty && _selectedBranch != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      AppStrings.get('no_centers_city', lang),
                      style: GoogleFonts.jost(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),

                // ── Date ─────────────────────────────────────────────────
                _buildLabel(AppStrings.get('preferred_date', lang)),
                _buildCalendar(),
                const SizedBox(height: 16),

                // ── Time ─────────────────────────────────────────────────
                _buildLabel(AppStrings.get('preferred_time', lang)),
                _buildTimePicker(),
                const SizedBox(height: 24),

                // ── Submit ────────────────────────────────────────────────
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
                    onPressed: () async {
                      if (_vehicleNumberController.text.trim().isEmpty ||
                          _selectedModel == null ||
                          _selectedBranch == null ||
                          _selectedDate == null ||
                          _selectedTime == null ||
                          _selectedServices.isEmpty ||
                          _selectedServiceCenterId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.error,
                            content: Text(
                              AppStrings.get('fill_all_fields', lang),
                              style: GoogleFonts.jost(color: Colors.white),
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
                          SnackBar(
                            backgroundColor: AppColors.error,
                            content: Text(
                              AppStrings.get('date_fully_booked', lang),
                              style: GoogleFonts.jost(color: Colors.white),
                            ),
                          ),
                        );
                        return;
                      }

                      try {
                        final selectedCenter = _filteredServiceCenters
                            .firstWhere(
                              (center) =>
                                  center['id'] == _selectedServiceCenterId,
                            );
                        final response = await http.post(
                          Uri.parse('${_authService.baseUrl}/appointments'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'vehicleNumber':
                                _vehicleNumberController.text.trim(),
                            'vehicleModel': _selectedModel,
                            'serviceTypes': _selectedServices,
                            'branch': _selectedBranch,
                            'date': _selectedDate!.toIso8601String(),
                            'time': _selectedTime!.format(context),
                            'timestamp': DateTime.now().toIso8601String(),
                            'Contact': _userPhoneNumber,
                            'userId': _userId,
                            'serviceCenterUid': selectedCenter['uid'],
                            'status': 'pending',
                          }),
                        );

                        if (response.statusCode < 200 ||
                            response.statusCode >= 300) {
                          throw Exception(response.body);
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.success,
                            content: Text(
                              AppStrings.get('appointment_success', lang),
                              style: GoogleFonts.jost(color: Colors.white),
                            ),
                          ),
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DashboardScreen(),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    child: Text(
                      AppStrings.get('schedule_appointment', lang),
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
          bottomNavigationBar: AppBottomNav(currentIndex: 0),
        );
      },
    );
  }
}
