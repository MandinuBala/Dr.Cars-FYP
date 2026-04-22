import 'package:dr_cars_fyp/service/check_service_acc_availability.dart';
import 'package:dr_cars_fyp/auth/signup.dart';
import 'package:dr_cars_fyp/auth/signup_service.dart';
import 'package:flutter/material.dart';

class SignupSelection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('images/bg_removed_logo.png', height: 100),
            SizedBox(height: 20),
            Text(
              'Create an account as',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpPage()),
                );
              },
              child: Text('Vehicle Owner'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceCenterRequestScreen(),
                  ),
                );
              },
              child: Text('Service Center'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 100),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckRequestStatusPage(),
                  ),
                );
              },
              child: Text(
                "Check service center availability!!",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
