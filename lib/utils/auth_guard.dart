import 'package:flutter/material.dart';
import '../screens/teacher_dashboard.dart';
import '../screens/principal_dashboard.dart'; // you can rename to administrator_dashboard.dart if needed
import '../services/api_service.dart';

class AuthGuard {
  static final ApiService _apiService = ApiService();

  // Fetch user role from backend and redirect accordingly
  static Future<void> redirectUser(BuildContext context) async {
    try {
      // Backend endpoint to get current user info
      final userData = await _apiService._request(
        endpoint: "me", // should return user info including role
        requiresAuth: true,
      );

      if (userData == null || userData["role"] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch user data.")),
        );
        return;
      }

      final role = userData["role"];
      if (role == "Teacher") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TeacherDashboard()),
        );
      } else if (role == "Administrator") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdministratorDashboard()), // rename screen if desired
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unauthorized access!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}
