// lib/admin/dashboard/vehicle_dashboard.dart
import 'package:dr_cars_fyp/user/main_dashboard.dart';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dr_cars_fyp/utils/vehicle_image_helper.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dr_cars_fyp/widgets/app_bottom_nav.dart';
import 'package:dr_cars_fyp/admin/dashboard/warning_database.dart';

class VehicleDashboardScreen extends StatefulWidget {
  const VehicleDashboardScreen({Key? key}) : super(key: key);

  @override
  _VehicleDashboardScreenState createState() => _VehicleDashboardScreenState();
}

class _VehicleDashboardScreenState extends State<VehicleDashboardScreen> {
  bool _isLoading = true;
  final AuthService _authService = AuthService();
  Map<String, dynamic>? vehicleData;
  String? vehicleBrand;
  String? vehicleModel;
  List<String> brandIndicatorImages = [];

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  Future<void> _loadVehicleData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = await _authService.getCurrentUser();
      if (!mounted) return;
      if (currentUser != null) {
        final uid =
            currentUser['uid']?.toString() ??
            currentUser['id']?.toString() ??
            currentUser['_id']?.toString() ??
            currentUser['userId']?.toString() ??
            '';

        if (uid.isEmpty) {
          if (mounted) Navigator.pop(context);
          return;
        }

        final vehicleDataFromApi = await _authService.getVehicleByUserId(uid);
        if (!mounted) return;

        if (vehicleDataFromApi != null) {
          setState(() {
            vehicleData = vehicleDataFromApi;
            vehicleBrand = vehicleData!['selectedBrand']?.toString();
            vehicleModel = vehicleData!['selectedModel']?.toString();
          });
          _loadIndicatorImages();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.error,
                content: Text(
                  'No vehicle found. Please set up your vehicle in your profile.',
                  style: GoogleFonts.jost(color: Colors.white),
                ),
              ),
            );
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Error loading vehicle data.',
              style: GoogleFonts.jost(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadIndicatorImages() {
    // Use the brand set from the database.
    // BMW → BMW images, Toyota → Toyota images,
    // all others → universal Toyota images.
    final images =
        WarningDatabase.brandIndicatorSets[vehicleBrand] ??
        WarningDatabase.brandIndicatorSets['Toyota']!;
    setState(() => brandIndicatorImages = images);
  }

  // ── Open YouTube ──────────────────────────────────────────────────────────
  Future<void> _openYouTube(String query) async {
    final uri = Uri.parse(
      'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fallback: try in-app browser
      try {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text(
                'Could not open YouTube. Please check your browser app.',
                style: GoogleFonts.jost(color: Colors.white),
              ),
            ),
          );
        }
      }
    }
  }

  // ── Warning dialog ────────────────────────────────────────────────────────
  void _showWarningDialog(String imagePath) {
    final info = WarningDatabase.warnings[imagePath];
    final title =
        WarningDatabase.indicatorTitles[imagePath] ??
        imagePath.split('/').last.replaceAll('.png', '');
    final severityStyle = WarningDatabase.getSeverityStyle(
      info?.severity ?? 'info',
    );
    final severityColor = severityStyle['color'] as Color;

    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderGold),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.1),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Severity header ───────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.12),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: severityColor.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          severityStyle['icon'] as String,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          severityStyle['label'] as String,
                          style: GoogleFonts.jost(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: severityColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Scrollable body ───────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon + title
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.borderGold,
                                  ),
                                ),
                                child: Image.asset(
                                  imagePath,
                                  errorBuilder:
                                      (_, __, ___) => Icon(
                                        Icons.warning_amber_rounded,
                                        color: severityColor,
                                        size: 32,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  info?.title ?? title,
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (info != null) ...[
                            const SizedBox(height: 16),

                            // What this means
                            _dialogSectionLabel('WHAT THIS MEANS'),
                            const SizedBox(height: 6),
                            Text(
                              info.description,
                              style: GoogleFonts.jost(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Immediate actions
                            _dialogSectionLabel('WHAT TO DO RIGHT NOW'),
                            const SizedBox(height: 8),
                            ...info.driverActions.map(
                              (a) => _bulletItem(a, severityColor),
                            ),

                            // DIY steps or professional note
                            if (info.isDIYFixable &&
                                info.diySteps.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _dialogSectionLabel('HOW TO FIX IT YOURSELF'),
                              const SizedBox(height: 8),
                              ...info.diySteps.asMap().entries.map(
                                (e) => _numberedStep(e.key + 1, e.value),
                              ),
                            ] else if (!info.isDIYFixable) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.error.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.engineering,
                                      color: AppColors.error,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'This issue requires professional diagnosis. '
                                        'Do not attempt to repair without proper tools and knowledge.',
                                        style: GoogleFonts.jost(
                                          fontSize: 12,
                                          color: AppColors.error,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            // YouTube button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    () => _openYouTube(info.youtubeQuery),
                                icon: const Icon(
                                  Icons.play_circle_outline,
                                  size: 20,
                                ),
                                label: Text(
                                  'Watch How-To Video on YouTube',
                                  style: GoogleFonts.jost(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF0000),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            Text(
                              'No detailed information available for this indicator yet.',
                              style: GoogleFonts.jost(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Close button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(
                                  color: AppColors.borderGold,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Close',
                                style: GoogleFonts.jost(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _dialogSectionLabel(String text) => Text(
    text,
    style: GoogleFonts.jost(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
      color: AppColors.gold,
    ),
  );

  Widget _bulletItem(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.jost(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _numberedStep(int n, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold.withOpacity(0.4)),
          ),
          child: Center(
            child: Text(
              '$n',
              style: GoogleFonts.jost(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: GoogleFonts.jost(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ── Indicator tile ────────────────────────────────────────────────────────
  Widget _buildIndicatorTile(String imagePath) {
    final info = WarningDatabase.warnings[imagePath];
    final title =
        WarningDatabase.indicatorTitles[imagePath] ??
        imagePath.split('/').last.replaceAll('.png', '');
    final severityColor =
        info != null
            ? (WarningDatabase.getSeverityStyle(info.severity)['color']
                    as Color)
                .withOpacity(0.5)
            : AppColors.borderGold;

    return GestureDetector(
      onTap: () => _showWarningDialog(imagePath),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: severityColor),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderGold),
                ),
                child: Image.asset(
                  imagePath,
                  height: 40,
                  width: 40,
                  errorBuilder:
                      (_, __, ___) => Icon(
                        Icons.warning_amber_rounded,
                        size: 40,
                        color: severityColor,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.jost(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'TAP TO LEARN',
                style: GoogleFonts.jost(
                  fontSize: 9,
                  color: AppColors.gold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
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
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.gold),
        title: Text(
          'Dashboard Warnings',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.gold),
            onPressed: _loadVehicleData,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Vehicle card ──────────────────────────────────
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGold),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.borderGold),
                            ),
                            child: ClipOval(
                              child: VehicleImageHelper.buildFittedImage(
                                brand: vehicleBrand,
                                model: vehicleModel,
                                photoUrl: vehicleData?['vehiclePhotoUrl'],
                                size: 56,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$vehicleBrand $vehicleModel',
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  vehicleData?['vehicleNumber'] ?? '',
                                  style: GoogleFonts.jost(
                                    fontSize: 12,
                                    color: AppColors.gold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  'Showing ${vehicleBrand ?? ''} dashboard indicators',
                                  style: GoogleFonts.jost(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Info banner ───────────────────────────────────
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: AppColors.gold,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tap any warning light to learn what it means, '
                              'what to do immediately, and how to fix it.',
                              style: GoogleFonts.jost(
                                fontSize: 12,
                                color: AppColors.gold,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Severity legend ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          _legendDot(const Color(0xFFCF4D6F), 'Critical'),
                          _legendDot(const Color(0xFFE07B39), 'Serious'),
                          _legendDot(AppColors.gold, 'Moderate'),
                          _legendDot(const Color(0xFF4CAF7D), 'Info'),
                        ],
                      ),
                    ),

                    // ── Section header ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dashboard Indicators',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.gold.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '${brandIndicatorImages.length} lights',
                              style: GoogleFonts.jost(
                                fontSize: 11,
                                color: AppColors.gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Indicator grid ────────────────────────────────
                    brandIndicatorImages.isEmpty
                        ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No indicators available for $vehicleBrand',
                              style: GoogleFonts.jost(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        )
                        : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.0,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                              ),
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: brandIndicatorImages.length,
                          itemBuilder:
                              (_, i) =>
                                  _buildIndicatorTile(brandIndicatorImages[i]),
                        ),
                  ],
                ),
              ),
      bottomNavigationBar: AppBottomNav(currentIndex: 0),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: GoogleFonts.jost(fontSize: 10, color: AppColors.textSecondary),
      ),
    ],
  );
}
