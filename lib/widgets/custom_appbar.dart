import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String role;
  final String name;
  final String? title; // ✅ Optional
  final List<Widget>? actions; // ✅ New parameter

  const CustomAppBar({
    super.key,
    required this.role,
    required this.name,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    // 🔥 Ensure "Principal" is shown as "Administrator"
    final displayRole = role == "Principal" ? "Administrator" : role;

    return AppBar(
      backgroundColor: Colors.blue,
      elevation: 4,
      title: Text(
        title ?? "$displayRole Dashboard",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        ...(actions ?? []), // ✅ Merge custom actions if provided
        CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(
            name.isNotEmpty ? name[0] : "?",
            style: const TextStyle(color: Colors.blue),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
