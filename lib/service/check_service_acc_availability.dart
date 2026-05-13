// lib/service/check_service_acc_availability.dart
import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/auth/signin.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class CheckRequestStatusPage extends StatefulWidget {
  const CheckRequestStatusPage({super.key});

  @override
  State<CheckRequestStatusPage> createState() => _CheckRequestStatusPageState();
}

class _CheckRequestStatusPageState extends State<CheckRequestStatusPage> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  String? statusMessage;
  bool isApproved = false;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> checkStatus() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() => statusMessage = 'Please enter an email address.');
      return;
    }

    setState(() {
      isLoading = true;
      statusMessage = null;
      isApproved = false;
    });

    try {
      final result = await _authService.getServiceCenterStatus(email);
      final status = result['status']?.toString() ?? 'not-found';
      final username = result['username']?.toString() ?? '';

      if (status == 'approved' || status == 'accepted') {
        setState(() {
          isApproved = true;
          statusMessage =
              'Your account has been approved!\n\n'
              'Email: $email\n'
              'Username: ${username.isNotEmpty ? username : '(use your registered username)'}\n\n'
              'Use the password you created when submitting the request.\n'
              'If forgotten, use "Forgot Password" on the sign in screen.';
        });
      } else if (status == 'not-found') {
        setState(() {
          isApproved = false;
          statusMessage = 'No request found for this email.';
        });
      } else if (status == 'rejected') {
        setState(() {
          isApproved = false;
          statusMessage =
              'Your request has been rejected. Please contact support for more information.';
        });
      } else {
        setState(() {
          isApproved = false;
          statusMessage =
              'Your request is still pending. Please check again later.';
        });
      }
    } catch (e) {
      setState(() {
        isApproved = false;
        statusMessage = 'An error occurred while checking status.';
      });
    }

    setState(() => isLoading = false);
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
          'Check Request Status',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
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
              // ── Icon ─────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
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
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.manage_search,
                  color: AppColors.gold,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Check Account Status',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email to check your\nservice center account status',
                style: GoogleFonts.jost(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              goldDivider(),
              const SizedBox(height: 8),

              // ── Email field ───────────────────────────────────────
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.jost(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: 'Email Address',
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
                    Icons.email_outlined,
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
              const SizedBox(height: 20),

              // ── Check button ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : checkStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.obsidian,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
                            'CHECK STATUS',
                            style: GoogleFonts.jost(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: AppColors.obsidian,
                            ),
                          ),
                ),
              ),

              // ── Result card ───────────────────────────────────────
              if (statusMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isApproved ? AppColors.success : AppColors.borderGold,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isApproved
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            color:
                                isApproved ? AppColors.success : AppColors.gold,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isApproved ? 'Approved!' : 'Status',
                            style: GoogleFonts.jost(
                              color:
                                  isApproved
                                      ? AppColors.success
                                      : AppColors.gold,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        statusMessage!,
                        style: GoogleFonts.jost(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                      if (isApproved) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SignInScreen(),
                                  ),
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.obsidian,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'GO TO SIGN IN',
                              style: GoogleFonts.jost(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
