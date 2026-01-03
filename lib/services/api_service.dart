import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = "https://sihbackend-hkqc.onrender.com";

  // ---------------------- LOGIN ----------------------
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/auth/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "username": email, // FastAPI OAuth2 expects 'username'
        "password": password,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception("Invalid email or password");
    } else {
      throw Exception("Login failed: ${response.statusCode} ${response.reasonPhrase}");
    }
  }
}