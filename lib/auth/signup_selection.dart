import 'package:dr_cars_fyp/service/check_service_acc_availability.dart';
import 'package:dr_cars_fyp/auth/signup.dart';
import 'package:dr_cars_fyp/auth/signup_service.dart';
import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/l10n/app_strings.dart';
import 'package:dr_cars_fyp/providers/locale_provider.dart';

class SignupSelection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('images/bg_removed_logo.png', height: 100),
                const SizedBox(height: 20),
                Text(
                  AppStrings.get('create_account_as', lang),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                    );
                  },
                  child: Text(AppStrings.get('vehicle_owner', lang)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceCenterRequestScreen(),
                      ),
                    );
                  },
                  child: Text(AppStrings.get('service_center', lang)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 100),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckRequestStatusPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Check service center availability!!",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
