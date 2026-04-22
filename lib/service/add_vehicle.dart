import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/auth/auth_service.dart';
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

  Future<void> _handleContinue() async {
    String vehicleNumber = vehicleController.text.trim();

    if (vehicleNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a vehicle number.")),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add New",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset('images/bg_removed_logo.png', height: 100),
            const SizedBox(height: 30),
            const Text(
              "Add a vehicle",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "Enter the vehicle number",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: vehicleController,
              decoration: const InputDecoration(
                labelText: "Vehicle Number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: isLoading ? null : _handleContinue,
                child:
                    isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          "Continue",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
