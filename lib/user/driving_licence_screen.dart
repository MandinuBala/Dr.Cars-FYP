// lib/user/driving_licence_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:dr_cars_fyp/service/document_service.dart';
import 'package:dr_cars_fyp/service/ocr_service.dart';

// ── Model ────────────────────────────────────────────────────────────────────
class DrivingLicenceData {
  String fullName,
      licenceNumber,
      adminNumber,
      dateOfBirth,
      issueDate,
      expiryDate,
      address,
      bloodGroup,
      photoUrl;
  List<String> categories;

  DrivingLicenceData({
    this.fullName = '',
    this.licenceNumber = '',
    this.adminNumber = '',
    this.dateOfBirth = '',
    this.issueDate = '',
    this.expiryDate = '',
    this.address = '',
    this.bloodGroup = '',
    this.photoUrl = '',
    this.categories = const [],
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'licenceNumber': licenceNumber,
    'adminNumber': adminNumber,
    'dateOfBirth': dateOfBirth,
    'issueDate': issueDate,
    'expiryDate': expiryDate,
    'address': address,
    'bloodGroup': bloodGroup,
    'photoUrl': photoUrl,
    'categories': categories.join(','),
  };

  factory DrivingLicenceData.fromJson(Map<String, dynamic> j) =>
      DrivingLicenceData(
        fullName: j['fullName'] ?? '',
        licenceNumber: j['licenceNumber'] ?? '',
        adminNumber: j['adminNumber'] ?? '',
        dateOfBirth: j['dateOfBirth'] ?? '',
        issueDate: j['issueDate'] ?? '',
        expiryDate: j['expiryDate'] ?? '',
        address: j['address'] ?? '',
        bloodGroup: j['bloodGroup'] ?? '',
        photoUrl: j['photoUrl'] ?? '',
        categories:
            (j['categories'] as String?)
                ?.split(',')
                .where((s) => s.isNotEmpty)
                .toList() ??
            [],
      );

  bool get isExpired {
    if (expiryDate.isEmpty) return false;
    try {
      final p =
          expiryDate.contains('.')
              ? expiryDate.split('.').reversed.toList()
              : expiryDate.split('-');
      if (p.length < 3) return false;
      return DateTime(
        int.parse(p[0]),
        int.parse(p[1]),
        int.parse(p[2]),
      ).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }
}

const _allCats = [
  'A1',
  'A',
  'B1',
  'B',
  'B2',
  'C1',
  'C',
  'CE',
  'D1',
  'D',
  'DE',
  'G1',
  'G',
  'J',
  'H',
];

// ── Screen ───────────────────────────────────────────────────────────────────
class DrivingLicenceScreen extends StatefulWidget {
  final String userId, userName;
  const DrivingLicenceScreen({
    required this.userId,
    required this.userName,
    super.key,
  });
  @override
  State<DrivingLicenceScreen> createState() => _DLState();
}

class _DLState extends State<DrivingLicenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  DrivingLicenceData _d = DrivingLicenceData();
  bool _editing = false, _saving = false, _scanning = false;
  File? _photo;
  final _picker = ImagePicker();
  List<String> _selCats = [];

  late TextEditingController _cName,
      _cLic,
      _cAdmin,
      _cDob,
      _cAddr,
      _cIssue,
      _cExpiry,
      _cBlood;
  String get _key => 'dl_${widget.userId}';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _cName = TextEditingController();
    _cLic = TextEditingController();
    _cAdmin = TextEditingController();
    _cDob = TextEditingController();
    _cAddr = TextEditingController();
    _cIssue = TextEditingController();
    _cExpiry = TextEditingController();
    _cBlood = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [
      _cName,
      _cLic,
      _cAdmin,
      _cDob,
      _cAddr,
      _cIssue,
      _cExpiry,
      _cBlood,
    ])
      c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final r = p.getString(_key);
    if (r != null)
      _apply(DrivingLicenceData.fromJson(jsonDecode(r)));
    else {
      _cName.text = widget.userName;
      if (mounted) setState(() => _d.fullName = widget.userName);
    }
  }

  void _apply(DrivingLicenceData d) {
    if (!mounted) return;
    setState(() {
      _d = d;
      _cName.text = d.fullName;
      _cLic.text = d.licenceNumber;
      _cAdmin.text = d.adminNumber;
      _cDob.text = d.dateOfBirth;
      _cAddr.text = d.address;
      _cIssue.text = d.issueDate;
      _cExpiry.text = d.expiryDate;
      _cBlood.text = d.bloodGroup;
      _selCats = List.from(d.categories);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (_photo != null) {
        final u = await DocumentService.uploadPhoto(_photo!);
        _d.photoUrl = u ?? '';
      }
      final d = DrivingLicenceData(
        fullName: _cName.text.trim(),
        licenceNumber: _cLic.text.trim(),
        adminNumber: _cAdmin.text.trim(),
        dateOfBirth: _cDob.text.trim(),
        address: _cAddr.text.trim(),
        issueDate: _cIssue.text.trim(),
        expiryDate: _cExpiry.text.trim(),
        bloodGroup: _cBlood.text.trim(),
        categories: _selCats,
        photoUrl: _d.photoUrl,
      );
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(d.toJson()));
      if (mounted)
        setState(() {
          _d = d;
          _editing = false;
        });
      _snack('Saved ✓');
    } catch (e) {
      _snack('Save failed: $e', err: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _scanFront() async {
    final src = await _srcPicker('Scan FRONT of Licence');
    if (src == null) return;
    final p = await _picker.pickImage(
      source: src,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (p == null) return;
    setState(() => _scanning = true);
    try {
      final file = File(p.path);
      final text = await OcrService.extractText(file);
      final lic = RegExp(
        r'5[\.\s]+([A-Z]\d{5,8})',
        caseSensitive: false,
      ).firstMatch(text);
      final adm = RegExp(
        r'4d[\.\s]+([A-Z0-9]{6,15})',
        caseSensitive: false,
      ).firstMatch(text);
      final nam = RegExp(
        r'(?:1[,\s.]*2|2[,\s.]*1)[\.\s]+([A-Z][A-Z\s]{4,50})',
        caseSensitive: false,
      ).firstMatch(text);
      final adr = RegExp(
        r'8[\.\s]+([A-Z0-9][^\n]{3,60})',
        caseSensitive: false,
      ).firstMatch(text);
      final dob = RegExp(
        r'3[\.\s]+(\d{1,2}[./]\d{1,2}[./]\d{4})',
      ).firstMatch(text);
      final issue =
          RegExp(
            r'4a[\.\s]+(\d{1,2}[./]\d{1,2}[./]\d{4})',
            caseSensitive: false,
          ).firstMatch(text) ??
          RegExp(
            r'(?:issue|4a)[:\s.]+(\d{1,2}[./]\d{1,2}[./]\d{4})',
            caseSensitive: false,
          ).firstMatch(text);
      final expiry = RegExp(
        r'4b[\.\s]+(\d{1,2}[./]\d{1,2}[./]\d{4})',
        caseSensitive: false,
      ).firstMatch(text);
      final blood = RegExp(
        r'[Bb]lood\s*[Gg]roup\s*([ABO0]+[+-]?)',
      ).firstMatch(text);
      setState(() {
        if (lic != null) _cLic.text = lic.group(1)!.trim();
        if (adm != null) _cAdmin.text = adm.group(1)!.trim();
        if (nam != null) _cName.text = nam.group(1)!.trim();
        if (adr != null) _cAddr.text = adr.group(1)!.trim();
        if (dob != null) _cDob.text = dob.group(1)!.trim();
        if (issue != null) _cIssue.text = issue.group(1)!.trim();
        if (expiry != null) _cExpiry.text = expiry.group(1)!.trim();
        if (blood != null) _cBlood.text = blood.group(1)!.trim();
        _photo = file;
        _editing = true;
      });
      final n = [lic, nam, dob, expiry].where((m) => m != null).length;
      _snack(n > 0 ? 'Auto-filled $n fields' : 'Fill details manually below');
    } catch (e) {
      _snack('Scan failed: $e', err: true);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _scanBack() async {
    final src = await _srcPicker('Scan BACK of Licence');
    if (src == null) return;
    final p = await _picker.pickImage(
      source: src,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (p == null) return;
    setState(() => _scanning = true);
    try {
      final text = await OcrService.extractText(File(p.path));
      final found =
          _allCats
              .where(
                (c) => RegExp(
                  r'\b' + c + r'\b',
                  caseSensitive: false,
                ).hasMatch(text),
              )
              .toList();
      setState(() {
        _selCats = found.isNotEmpty ? found : _selCats;
        _editing = true;
      });
      _snack(
        found.isNotEmpty
            ? 'Categories: ${found.join(', ')}'
            : 'Select categories manually',
      );
    } catch (e) {
      _snack('Scan failed: $e', err: true);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _pickPhoto() async {
    final src = await _srcPicker('Photo');
    if (src == null) return;
    final p = await _picker.pickImage(source: src, imageQuality: 80);
    if (p != null) setState(() => _photo = File(p.path));
  }

  Future<ImageSource?> _srcPicker(
    String title,
  ) => showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder:
        (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.borderGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                title,
                style: GoogleFonts.jost(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.gold),
                title: Text(
                  'Camera',
                  style: GoogleFonts.jost(color: AppColors.textPrimary),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.gold),
                title: Text(
                  'Gallery',
                  style: GoogleFonts.jost(color: AppColors.textPrimary),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
  );

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: err ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(msg, style: GoogleFonts.jost(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.richBlack,
      appBar: AppBar(
        backgroundColor: AppColors.obsidian,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.gold),
        title: Text(
          'Driving Licence',
          style: GoogleFonts.jost(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          if (!_editing)
            TextButton(
              onPressed: () => setState(() => _editing = true),
              child: Text(
                'Edit',
                style: GoogleFonts.jost(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
        bottom:
            _editing
                ? null
                : TabBar(
                  controller: _tab,
                  indicatorColor: AppColors.gold,
                  labelColor: AppColors.gold,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: GoogleFonts.jost(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  tabs: const [Tab(text: 'FRONT'), Tab(text: 'BACK')],
                ),
      ),
      body:
          _editing
              ? SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _form(),
              )
              : TabBarView(
                controller: _tab,
                children: [_frontView(), _backView()],
              ),
    );
  }

  // ── FRONT VIEW ─────────────────────────────────────────────────────────────
  Widget _frontView() {
    final expired = _d.isExpired;
    final hasPhoto = _photo != null || _d.photoUrl.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0E3D2B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    expired ? AppColors.error : AppColors.gold.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    _flag(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DRIVING LICENCE',
                            style: GoogleFonts.jost(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'DEMOCRATIC SOCIALIST REPUBLIC OF SRI LANKA',
                            style: GoogleFonts.jost(
                              color: Colors.white54,
                              fontSize: 6.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (expired ? AppColors.error : Colors.green)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: expired ? AppColors.error : Colors.green,
                        ),
                      ),
                      child: Text(
                        expired ? 'EXPIRED' : 'VALID',
                        style: GoogleFonts.jost(
                          color: expired ? AppColors.error : Colors.green,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(color: Colors.white12, height: 24),

                // Photo + fields
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.5),
                        ),
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child:
                            hasPhoto
                                ? (_photo != null
                                    ? Image.file(_photo!, fit: BoxFit.cover)
                                    : Image.network(
                                      _d.photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _noPhoto(),
                                    ))
                                : _noPhoto(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _d.fullName.isEmpty
                                ? widget.userName.toUpperCase()
                                : _d.fullName.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.jost(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _row('5. LIC', _d.licenceNumber, gold: true),
                          _row('4d', _d.adminNumber),
                          _row('3. DOB', _d.dateOfBirth),
                          _row('4a. Issued', _d.issueDate),
                          _row(
                            '4b. Expires',
                            _d.expiryDate,
                            color: expired ? AppColors.error : AppColors.gold,
                          ),
                          if (_d.bloodGroup.isNotEmpty)
                            _row('Blood Group', _d.bloodGroup),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(color: Colors.white12, height: 20),
                if (_d.address.isNotEmpty)
                  Text(
                    '8. ${_d.address}',
                    style: GoogleFonts.jost(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '4c. Commissioner General of Motor Traffic',
                  style: GoogleFonts.jost(color: Colors.white24, fontSize: 7),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _btn(
                  Icons.document_scanner_outlined,
                  'Scan Front',
                  _scanning ? null : _scanFront,
                  loading: _scanning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _btn(
                  Icons.add_a_photo_outlined,
                  'Update Photo',
                  _pickPhoto,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── BACK VIEW ──────────────────────────────────────────────────────────────
  Widget _backView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0A2A1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'VEHICLE CATEGORIES',
                      style: GoogleFonts.jost(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    if (_d.adminNumber.isNotEmpty)
                      Text(
                        _d.adminNumber,
                        style: GoogleFonts.jost(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 20),

                if (_d.categories.isNotEmpty) ...[
                  Text(
                    'Authorised to drive:',
                    style: GoogleFonts.jost(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _d.categories
                            .map(
                              (cat) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A5C3D),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: GoogleFonts.jost(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                  if (_d.issueDate.isNotEmpty || _d.expiryDate.isNotEmpty)
                    Row(
                      children: [
                        Expanded(child: _dateBox('ISSUED', _d.issueDate)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dateBox('EXPIRES', _d.expiryDate, gold: true),
                        ),
                      ],
                    ),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            color: Colors.white24,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No categories added',
                            style: GoogleFonts.jost(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap Scan Back below',
                            style: GoogleFonts.jost(
                              color: Colors.white24,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Divider(color: Colors.white12, height: 20),
                Text(
                  'Dept of Motor Traffic · Sri Lanka',
                  style: GoogleFonts.jost(
                    color: AppColors.gold.withOpacity(0.4),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _btn(
                  Icons.flip_to_back_outlined,
                  'Scan Back',
                  _scanning ? null : _scanBack,
                  loading: _scanning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _btn(
                  Icons.edit_outlined,
                  'Edit Details',
                  () => setState(() => _editing = true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── EDIT FORM ──────────────────────────────────────────────────────────────
  Widget _form() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Licence Details',
            style: GoogleFonts.jost(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _editing = false),
            child: Text(
              'Cancel',
              style: GoogleFonts.jost(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      const Divider(color: AppColors.borderGold, height: 24),

      // Photo
      Center(
        child: GestureDetector(
          onTap: _pickPhoto,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold, width: 2),
              color: AppColors.surfaceElevated,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child:
                  _photo != null
                      ? Image.file(_photo!, fit: BoxFit.cover)
                      : (_d.photoUrl.isNotEmpty
                          ? Image.network(_d.photoUrl, fit: BoxFit.cover)
                          : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo,
                                color: AppColors.gold,
                                size: 28,
                              ),
                              Text(
                                'Photo',
                                style: GoogleFonts.jost(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          )),
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),

      _tf(_cName, '1,2. Full Name', 'As on licence'),
      _tf(_cLic, '5. Licence Number', 'e.g. B5211584'),
      _tf(_cAdmin, '4d. Admin Number', 'e.g. 200329612643'),
      _tf(_cDob, '3. Date of Birth', 'DD.MM.YYYY'),
      _tf(_cAddr, '8. Address', 'Permanent address', lines: 2),
      _tf(_cIssue, '4a. Issue Date', 'DD.MM.YYYY'),
      _tf(_cExpiry, '4b. Expiry Date', 'DD.MM.YYYY'),
      _tf(_cBlood, 'Blood Group', 'e.g. O+'),

      const SizedBox(height: 8),
      Text(
        '9. Categories',
        style: GoogleFonts.jost(
          color: AppColors.textSecondary,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            _allCats.map((cat) {
              final sel = _selCats.contains(cat);
              return GestureDetector(
                onTap:
                    () => setState(() {
                      if (sel)
                        _selCats.remove(cat);
                      else
                        _selCats.add(cat);
                    }),
                child: Container(
                  width: 52,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        sel
                            ? AppColors.gold.withOpacity(0.15)
                            : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: sel ? AppColors.gold : AppColors.borderGold,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.jost(
                      color: sel ? AppColors.gold : AppColors.textSecondary,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),

      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.obsidian,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child:
              _saving
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.obsidian,
                      strokeWidth: 2,
                    ),
                  )
                  : Text(
                    'Save Licence',
                    style: GoogleFonts.jost(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
        ),
      ),
    ],
  );

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _row(String label, String val, {bool gold = false, Color? color}) {
    if (val.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label  ',
            style: GoogleFonts.jost(
              color: Colors.white38,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
          Expanded(
            child: Text(
              val,
              style: GoogleFonts.jost(
                color: color ?? (gold ? AppColors.gold : Colors.white70),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox(String label, String val, {bool gold = false}) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jost(
            color: Colors.white38,
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          val.isEmpty ? '—' : val,
          style: GoogleFonts.jost(
            color: gold ? AppColors.gold : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _btn(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    bool loading = false,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGold),
      ),
      child:
          loading
              ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppColors.gold,
                    strokeWidth: 2,
                  ),
                ),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColors.gold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.jost(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
    ),
  );

  Widget _noPhoto() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.person_outline,
        color: Colors.white.withOpacity(0.2),
        size: 28,
      ),
      Text(
        'PHOTO',
        style: GoogleFonts.jost(
          color: Colors.white24,
          fontSize: 7,
          letterSpacing: 1,
        ),
      ),
    ],
  );

  Widget _flag() => Container(
    width: 30,
    height: 18,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(2),
      border: Border.all(color: Colors.white12),
    ),
    clipBehavior: Clip.antiAlias,
    child: Row(
      children: [
        Expanded(child: Container(color: const Color(0xFF8B0000))),
        Container(width: 4, color: const Color(0xFF00A550)),
        Container(width: 4, color: const Color(0xFFFF8C00)),
        Expanded(
          flex: 2,
          child: Container(
            color: const Color(0xFFFFD700),
            child: const Center(
              child: Text('🦁', style: TextStyle(fontSize: 7)),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tf(
    TextEditingController c,
    String label,
    String hint, {
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      maxLines: lines,
      style: GoogleFonts.jost(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.jost(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        floatingLabelStyle: GoogleFonts.jost(
          color: AppColors.gold,
          fontSize: 11,
        ),
        hintStyle: GoogleFonts.jost(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderGold),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderGold),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    ),
  );
}
