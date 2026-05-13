import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:dr_cars_fyp/service/document_service.dart';
import 'package:dr_cars_fyp/service/ocr_service.dart';
import 'package:dr_cars_fyp/service/document_notification_service.dart';

class DocumentScanScreen extends StatefulWidget {
  final String userId;
  final String vehiclePlate;
  final VoidCallback onSaved;

  const DocumentScanScreen({
    required this.userId,
    required this.vehiclePlate,
    required this.onSaved,
    super.key,
  });

  @override
  State<DocumentScanScreen> createState() => _DocumentScanScreenState();
}

class _DocumentScanScreenState extends State<DocumentScanScreen> {
  File? _photo;
  bool _isScanning = false;
  bool _isSaving = false;
  List<DateTime> _detectedDates = [];
  List<YearMonth> _detectedYearMonths = [];
  DateTime? _selectedExpiry;

  String _docType = 'license';
  String _docLabel = 'Vehicle License';
  final _numberCtrl = TextEditingController();
  late final TextEditingController _labelCtrl;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: _docLabel);
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return;

    setState(() {
      _photo = File(picked.path);
      _isScanning = true;
      _detectedDates = [];
      _detectedYearMonths = [];
      _selectedExpiry = null;
    });

    try {
      final text = await OcrService.extractText(_photo!);
      final result = OcrService.extractAllDates(text);

      if (!mounted) return;
      setState(() {
        _detectedDates = result.fullDates;
        _detectedYearMonths = result.yearMonths;

        // Auto-select best candidate:
        // For insurance → latest full date (end of period)
        // For licence   → year-month → last day of that month
        if (result.fullDates.isNotEmpty) {
          _selectedExpiry = result.fullDates.first; // latest
        } else if (result.yearMonths.isNotEmpty) {
          // Sri Lankan revenue licence: use last day of detected month
          _selectedExpiry = result.yearMonths.first.toLastDay();
        }
      });
    } catch (e) {
      _showSnack('OCR failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _pickDateManually() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedExpiry ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.gold,
                onPrimary: AppColors.obsidian,
                surface: AppColors.surfaceDark,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null) setState(() => _selectedExpiry = picked);
  }

  Future<void> _save() async {
    if (_selectedExpiry == null) {
      _showSnack('Please select an expiry date', error: true);
      return;
    }
    if (_photo == null) {
      _showSnack('Please take or select a photo first', error: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final photoUrl = await DocumentService.uploadPhoto(_photo!);
      final success = await DocumentService.addDocument({
        'userId': widget.userId,
        'type': _docType,
        'label': _docLabel,
        'documentNumber': _numberCtrl.text.trim(),
        'vehiclePlate': widget.vehiclePlate,
        'expiryDate': _selectedExpiry!.toIso8601String(),
        'photoUrl': photoUrl ?? '',
      });

      if (success) {
        final docs = await DocumentService.getDocuments(widget.userId);
        await DocumentNotificationService.scheduleAll(docs);
        widget.onSaved();
        _showSnack('Document saved! Notifications scheduled ✓');
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack('Failed to save. Try again.', error: true);
      }
    } catch (e) {
      _showSnack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? AppColors.error : AppColors.success,
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
          'Add Document',
          style: GoogleFonts.cormorantGaramond(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Document Type'),
            const SizedBox(height: 10),
            Row(
              children: [
                _typeChip('license', 'Vehicle License', Icons.badge),
                const SizedBox(width: 10),
                _typeChip('insurance', 'Insurance', Icons.shield),
              ],
            ),

            const SizedBox(height: 20),
            _sectionTitle('Document Label'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _labelCtrl,
              style: GoogleFonts.jost(color: AppColors.textPrimary),
              onChanged: (v) => _docLabel = v,
              decoration: _inputDeco('e.g. Third Party Insurance'),
            ),

            const SizedBox(height: 20),
            _sectionTitle('Document Number (optional)'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _numberCtrl,
              style: GoogleFonts.jost(color: AppColors.textPrimary),
              decoration: _inputDeco('e.g. WP-28908562'),
            ),

            const SizedBox(height: 24),
            _sectionTitle('Scan Document Photo'),
            const SizedBox(height: 12),
            _photoSection(),

            const SizedBox(height: 20),

            // ── OCR Results ──────────────────────────────────────────────
            if (_isScanning)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.gold),
                    SizedBox(height: 12),
                    Text(
                      'Scanning document...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else if (_detectedDates.isNotEmpty ||
                _detectedYearMonths.isNotEmpty) ...[
              _sectionTitle('Detected Dates — Select Expiry'),
              const SizedBox(height: 6),

              // ── Insurance hint ──
              if (_docType == 'insurance' && _detectedDates.length > 1)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                  ),
                  child: Text(
                    'For insurance, select the LAST date (end of coverage period)',
                    style: GoogleFonts.jost(
                      color: AppColors.gold,
                      fontSize: 12,
                    ),
                  ),
                ),

              // ── Year-month tiles (Sri Lankan Revenue Licence) ──
              ..._detectedYearMonths.map((ym) => _yearMonthTile(ym)),

              // ── Full date tiles ──
              ..._detectedDates.map((date) => _dateTile(date)),
            ] else if (_photo != null && !_isScanning) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No dates detected. Set the date manually below.',
                        style: GoogleFonts.jost(
                          color: Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Expiry date picker ───────────────────────────────────────
            _sectionTitle('Expiry Date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDateManually,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _selectedExpiry != null
                            ? AppColors.gold
                            : AppColors.borderGold,
                    width: _selectedExpiry != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color:
                          _selectedExpiry != null
                              ? AppColors.gold
                              : AppColors.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedExpiry != null
                          ? _fmt(_selectedExpiry!)
                          : 'Tap to set expiry date',
                      style: GoogleFonts.jost(
                        color:
                            _selectedExpiry != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedExpiry != null)
                      Text(
                        'tap to change',
                        style: GoogleFonts.jost(
                          color: AppColors.gold,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isSaving || _photo == null) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.obsidian,
                  elevation: 0,
                  disabledBackgroundColor: AppColors.gold.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    _isSaving
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: AppColors.obsidian,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          'Save Document & Schedule Notifications',
                          style: GoogleFonts.jost(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Year-month tile (Sri Lankan Revenue Licence) ─────────────────────────
  Widget _yearMonthTile(YearMonth ym) {
    final asDate = ym.toLastDay();
    final isSelected =
        _selectedExpiry != null &&
        _selectedExpiry!.year == asDate.year &&
        _selectedExpiry!.month == asDate.month;

    return GestureDetector(
      onTap: () => setState(() => _selectedExpiry = asDate),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.gold.withOpacity(0.15)
                  : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.borderGold,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.gold : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valid until: ${ym.label}',
                    style: GoogleFonts.jost(
                      color:
                          isSelected ? AppColors.gold : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Expiry set to last day: ${_fmt(asDate)}',
                    style: GoogleFonts.jost(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Revenue Licence',
                style: GoogleFonts.jost(
                  color: AppColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Full date tile ────────────────────────────────────────────────────────
  Widget _dateTile(DateTime date) {
    final isSelected = _selectedExpiry == date;
    return GestureDetector(
      onTap: () => setState(() => _selectedExpiry = date),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.gold.withOpacity(0.15)
                  : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.borderGold,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.gold : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              _fmt(date),
              style: GoogleFonts.jost(
                color: isSelected ? AppColors.gold : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Photo section ─────────────────────────────────────────────────────────
  Widget _photoSection() {
    if (_photo == null) {
      return Row(
        children: [
          Expanded(
            child: _photoBtn(Icons.camera_alt, 'Camera', ImageSource.camera),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _photoBtn(
              Icons.photo_library,
              'Gallery',
              ImageSource.gallery,
            ),
          ),
        ],
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _photo!,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap:
                () => setState(() {
                  _photo = null;
                  _detectedDates = [];
                  _detectedYearMonths = [];
                  _selectedExpiry = null;
                }),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoBtn(IconData icon, String label, ImageSource src) {
    return GestureDetector(
      onTap: () => _pickAndScan(src),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGold),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.gold, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.jost(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String type, String label, IconData icon) {
    final selected = _docType == type;
    return Expanded(
      child: GestureDetector(
        onTap:
            () => setState(() {
              _docType = type;
              _docLabel = label;
              _labelCtrl.text = label;
            }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                selected
                    ? AppColors.gold.withOpacity(0.15)
                    : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.borderGold,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.gold : AppColors.textMuted,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.jost(
                  color: selected ? AppColors.gold : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
    t,
    style: GoogleFonts.jost(
      color: AppColors.textSecondary,
      fontSize: 12,
      letterSpacing: 0.8,
    ),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.jost(color: AppColors.textMuted, fontSize: 14),
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  String _fmt(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}
