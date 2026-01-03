import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String role;
  final String name;
  final String? profileImage;

  const ProfileScreen({
    super.key,
    required this.role,
    required this.name,
    this.profileImage, // ✅ now optional
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$role Profile")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (profileImage != null)
              CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage(profileImage!),
              )
            else
              const CircleAvatar(
                radius: 60,
                child: Icon(Icons.person, size: 50),
              ),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              role,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
