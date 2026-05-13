// lib/service/add_vehicle.dart
import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/owner_info.dart';

class AddVehicle extends StatefulWidget {
  const AddVehicle({super.key});

  @override
  State<AddVehicle> createState() => _AddVehicleState();
}

class _AddVehicleState extends State<AddVehicle> {
  final TextEditingController vehicleController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isLoading = false;

  @override
  void dispose() {
    vehicleController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    String vehicleNumber = vehicleController.text.trim();

    if (vehicleNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Please enter a vehicle number.',
            style: GoogleFonts.jost(color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final vehicleData = await _authService.getVehicleByNumber(vehicleNumber);

      if (vehicleData != null) {
        final uid =
            vehicleData['uid']?.toString() ?? vehicleData['userId']?.toString();
        Map<String, dynamic>? userData;

        if (uid != null && uid.isNotEmpty) {
          userData = await _authService.getUserById(uid);
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => OwnerInfo(
                    vehicleNumber: vehicleNumber,
                    vehicleData: vehicleData,
                    userData: userData,
                  ),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OwnerInfo(vehicleNumber: vehicleNumber),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Error: $e',
              style: GoogleFonts.jost(color: Colors.white),
            ),
          ),
        );
      }
    }

    if (mounted) setState(() => isLoading = false);
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
          'Add New Vehicle',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo ─────────────────────────────────────────────
              Container(
                width: 100,
                height: 100,
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
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'images/bg_removed_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Add a Vehicle',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the vehicle registration number',
                style: GoogleFonts.jost(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              goldDivider(),
              const SizedBox(height: 8),

              // ── Input ─────────────────────────────────────────────
              TextField(
                controller: vehicleController,
                style: GoogleFonts.jost(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Vehicle Number',
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
                  prefixIcon: const Icon(
                    Icons.directions_car_outlined,
                    color: AppColors.gold,
                    size: 20,
                  ),
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
                    borderSide: const BorderSide(
                      color: AppColors.gold,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Continue Button ───────────────────────────────────
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
            ],
          ),
        ),
      ),
    );
  }
}
