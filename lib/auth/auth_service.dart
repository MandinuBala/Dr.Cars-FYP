// lib/auth/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  String get baseUrl {
    if (_apiBaseUrlFromEnv.isNotEmpty) return _apiBaseUrlFromEnv;

    if (kIsWeb) return 'http://localhost:5000';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Physical Android devices should use host LAN IP by default.
        // For emulator use: --dart-define=API_BASE_URL=http://10.0.2.2:5000
        return 'http://192.168.1.21:5000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:5000';
      case TargetPlatform.fuchsia:
        return 'http://localhost:5000';
    }
  }

  Future<void> _persistCurrentUser(dynamic user, {String? token}) async {
    final prefs = await SharedPreferences.getInstance();

    if (token != null && token.isNotEmpty) {
      await prefs.setString('authToken', token);
    }

    if (user is Map<String, dynamic>) {
      final userId =
          user['uid']?.toString() ??
          user['id']?.toString() ??
          user['_id']?.toString() ??
          user['userId']?.toString();
      final userType =
          user['userType']?.toString() ?? user['User Type']?.toString();
      final email = user['email']?.toString() ?? user['Email']?.toString();

      if (userId != null && userId.isNotEmpty) {
        await prefs.setString('currentUserId', userId);
      }
      if (userType != null && userType.isNotEmpty) {
        await prefs.setString('currentUserType', userType);
      }
      if (email != null && email.isNotEmpty) {
        await prefs.setString('currentUserEmail', email);
      }
    }
  }

  // -------------------- LOGIN --------------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUserEmail', email);
      await prefs.setString(
        'currentUserType',
        data['userType']?.toString() ?? '',
      );

      // Try by email first, then by username
      Map<String, dynamic>? userData;

      final byEmail = await http.get(Uri.parse("$baseUrl/user/email/$email"));
      if (byEmail.statusCode == 200) {
        userData = jsonDecode(byEmail.body) as Map<String, dynamic>;
      } else {
        // input was a username, try username endpoint
        final byUsername = await http.get(
          Uri.parse("$baseUrl/user/username/$email"),
        );
        print("=== USERNAME FETCH STATUS: ${byUsername.statusCode} ===");
        print("=== USERNAME FETCH BODY: ${byUsername.body} ===");
        if (byUsername.statusCode == 200) {
          userData = jsonDecode(byUsername.body) as Map<String, dynamic>;
        }
      }

      if (userData != null) {
        await _persistCurrentUser(userData);
        print("=== PERSISTED: $userData ===");
      } else {
        print("=== COULD NOT FETCH USER AFTER LOGIN ===");
      }

      return {'userType': data['userType'] ?? ''};
    } else {
      throw Exception("Login failed: ${response.body}");
    }
  }

  // -------------------- FETCH USER BY EMAIL --------------------
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final response = await http.get(Uri.parse("$baseUrl/user/email/$email"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // -------------------- FETCH USER BY USERNAME --------------------
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final response = await http.get(
      Uri.parse("$baseUrl/user/username/$username"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["exists"] == true ? data : null;
    }
    return null;
  }

  // -------------------- CREATE USER --------------------
  Future<void> createUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse("$baseUrl/user"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(userData),
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to create user: ${response.body}");
    }
  }

  // -------------------- UPDATE USER --------------------
  Future<void> updateUser(
    String email,
    Map<String, dynamic> updatedData,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/user/$email"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(updatedData),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update user: ${response.body}");
    }
  }

  // -------------------- LOGOUT --------------------
  Future<void> logout() async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/logout"));
      if (response.statusCode != 200) {
        throw Exception("Logout failed: ${response.body}");
      }
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
      await prefs.remove('currentUserId');
      await prefs.remove('currentUserType');
      await prefs.remove('currentUserEmail');
    }
  }

  // -------------------- VEHICLE --------------------
  Future<Map<String, dynamic>?> getVehicleByUserId(String uid) async {
    final response = await http.get(Uri.parse("$baseUrl/vehicles/$uid"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // -------------------- GOOGLE LINK --------------------
  Future<Map<String, dynamic>> linkGoogleAccount(
    String email,
    String googleId,
    String password,
    String userType,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/google/link"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "googleId": googleId,
        "password": password,
        "userType": userType,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Google link failed: ${response.body}");
    }
  }

  // -------------------- GOOGLE PROFILE COMPLETION --------------------
  Future<Map<String, dynamic>> completeGoogleProfile(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/google/complete"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Google profile completion failed: ${response.body}");
    }
  }

  //--------------------- get current user ---------------------
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString('currentUserId');

    // ✅ Fallback: if no userId, try fetching by email
    if (userId == null || userId.isEmpty) {
      final email = prefs.getString('currentUserEmail');
      if (email == null || email.isEmpty) return null;

      final response = await http.get(Uri.parse("$baseUrl/user/email/$email"));
      if (response.statusCode != 200) return null;

      final data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      await _persistCurrentUser(data); // this will now save the userId
      return data;
    }

    final response = await http.get(Uri.parse("$baseUrl/users/$userId"));
    if (response.statusCode != 200) return null;

    final data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    await _persistCurrentUser(data);
    return data;
  }

  // -------------------- GOOGLE LOGIN --------------------
  Future<Map<String, dynamic>> googleLogin({
    required String googleId,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/google"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "googleId": googleId,
        "email": email,
        "name": name,
        "photoUrl": photoUrl,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _persistCurrentUser(
        data['user'] ?? data,
        token: data['token']?.toString(),
      );
      return data;
    } else {
      throw Exception("Google login failed: ${response.body}");
    }
  }

  // -------------------- FACEBOOK LOGIN --------------------
  Future<Map<String, dynamic>> facebookLogin({
    required String facebookId,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/facebook"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "facebookId": facebookId,
        "email": email,
        "name": name,
        "photoUrl": photoUrl,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _persistCurrentUser(
        data['user'] ?? data,
        token: data['token']?.toString(),
      );
      return data;
    } else {
      throw Exception("Facebook login failed: ${response.body}");
    }
  }

  Future<String?> getCurrentUserId() async {
    final user = await getCurrentUser();
    return user?['uid']?.toString() ??
        user?['id']?.toString() ??
        user?['_id']?.toString() ??
        user?['userId']?.toString();
  }

  Future<List<Map<String, dynamic>>> getServiceCentersByCity(
    String city,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/service-centers?city=${Uri.encodeComponent(city)}"),
    );

    if (response.statusCode != 200) {
      return [];
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>?> getVehicleByNumber(String vehicleNumber) async {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/vehicles/number/${Uri.encodeComponent(vehicleNumber)}",
      ),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    final response = await http.get(
      Uri.parse("$baseUrl/users/${Uri.encodeComponent(id)}"),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    return null;
  }

  Future<Map<String, dynamic>> createUserById(
    Map<String, dynamic> payload,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to create user: ${response.body}");
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<Map<String, dynamic>> updateUserById(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/users/${Uri.encodeComponent(id)}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update user: ${response.body}");
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<void> deleteUserById(String id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/users/${Uri.encodeComponent(id)}"),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete user: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> upsertVehicleByUserId(
    String uid,
    Map<String, dynamic> payload,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/vehicles/by-user/${Uri.encodeComponent(uid)}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to save vehicle: ${response.body}");
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/users/${Uri.encodeComponent(userId)}/password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "currentPassword": currentPassword,
        "newPassword": newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to change password: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getServiceCenterStatus(String email) async {
    final response = await http.get(
      Uri.parse("$baseUrl/service-center-status/${Uri.encodeComponent(email)}"),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to check status: ${response.body}");
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<void> resetPassword(String emailOrUsername) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"input": emailOrUsername}),
    );

    if (response.statusCode != 200) {
      throw Exception("Reset failed: ${response.body}");
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String username,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/user"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "username": username,
        "password": password,
        "userType": role,
        "createdAt": DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Sign up failed: ${response.body}");
    }
  }
}
