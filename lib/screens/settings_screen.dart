import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final String role;

  const SettingsScreen({super.key, required this.role}); // ✅ fixed constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Center(
        child: Text(
          "$role Settings Page",
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
