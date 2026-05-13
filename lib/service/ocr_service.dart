import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// ── Result models ────────────────────────────────────────────────────────────

class YearMonth {
  final int year;
  final int month;
  YearMonth({required this.year, required this.month});

  /// Returns the last day of this month as a DateTime
  DateTime toLastDay() => DateTime(year, month + 1, 0);

  String get formatted =>
      '$year-${month.toString().padLeft(2, '0')}';

  String get label {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${names[month]} $year';
  }
}

class OcrResult {
  final List<DateTime> fullDates;   // exact dates found
  final List<YearMonth> yearMonths; // year-month only (Sri Lankan licence header)

  OcrResult({required this.fullDates, required this.yearMonths});

  bool get hasAnyDate => fullDates.isNotEmpty || yearMonths.isNotEmpty;
}

// ── OCR Service ──────────────────────────────────────────────────────────────

class OcrService {
  static final _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract all text from image
  static Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final result = await _recognizer.processImage(inputImage);
    return result.text;
  }

  /// Main method — returns both full dates and year-month hints
  static OcrResult extractAllDates(String text) {
    final fullDates = <DateTime>{};
    final yearMonths = <String, YearMonth>{};

    const monthMap = {
      'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4,  'MAY': 5,  'JUN': 6,
      'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
    };

    // ── Pattern 1: DD/MM/YYYY  DD.MM.YYYY  DD-MM-YYYY ──
    final p1 = RegExp(r'\b(\d{1,2})[./\-](\d{1,2})[./\-](\d{4})\b');
    for (final m in p1.allMatches(text)) {
      final d  = int.tryParse(m.group(1)!);
      final mo = int.tryParse(m.group(2)!);
      final y  = int.tryParse(m.group(3)!);
      if (_valid(d, mo, y)) fullDates.add(DateTime(y!, mo!, d!));
    }

    // ── Pattern 2: YYYY-MM-DD  YYYY/MM/DD ──
    final p2 = RegExp(r'\b(\d{4})[./\-](\d{1,2})[./\-](\d{1,2})\b');
    for (final m in p2.allMatches(text)) {
      final y  = int.tryParse(m.group(1)!);
      final mo = int.tryParse(m.group(2)!);
      final d  = int.tryParse(m.group(3)!);
      if (_valid(d, mo, y)) fullDates.add(DateTime(y!, mo!, d!));
    }

    // ── Pattern 3: DD-Mon-YYYY  DD Mon YYYY (insurance format: 24-Jul-2026) ──
    final p3 = RegExp(
      r'\b(\d{1,2})[\s\-](JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[\s\-](\d{4})\b',
      caseSensitive: false,
    );
    for (final m in p3.allMatches(text)) {
      final d  = int.tryParse(m.group(1)!);
      final mo = monthMap[m.group(2)!.toUpperCase()];
      final y  = int.tryParse(m.group(3)!);
      if (_valid(d, mo, y)) fullDates.add(DateTime(y!, mo!, d!));
    }

    // ── Pattern 4: YYYY-MM  (Sri Lankan Revenue Licence header "2026-07") ──
    // Only capture standalone YYYY-MM not already part of a full date
    final p4 = RegExp(r'\b(20\d{2})-(0[1-9]|1[0-2])\b');
    for (final m in p4.allMatches(text)) {
      final y  = int.tryParse(m.group(1)!);
      final mo = int.tryParse(m.group(2)!);
      if (y != null && mo != null && y >= 2024 && y <= 2040) {
        final key = '$y-$mo';
        // Only add as yearMonth if we don't already have an exact date for this month
        final alreadyHaveExact = fullDates.any(
          (d) => d.year == y && d.month == mo,
        );
        if (!alreadyHaveExact) {
          yearMonths[key] = YearMonth(year: y, month: mo);
        }
      }
    }

    // Sort full dates — latest first (insurance: last date = expiry)
    final sorted = fullDates.toList()..sort((a, b) => b.compareTo(a));

    return OcrResult(
      fullDates: sorted,
      yearMonths: yearMonths.values.toList(),
    );
  }

  /// Legacy helper (used by existing code)
  static List<DateTime> extractDates(String text) =>
      extractAllDates(text).fullDates;

  static bool _valid(int? d, int? mo, int? y) {
    if (d == null || mo == null || y == null) return false;
    if (y < 2000 || y > 2050) return false;
    if (mo < 1 || mo > 12) return false;
    if (d < 1 || d > 31) return false;
    return true;
  }

  static void dispose() => _recognizer.close();
}