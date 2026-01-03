import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  final String userRole;

  const ReportsScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$userRole Reports'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: Icon(Icons.bar_chart,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text("Monthly Attendance Summary"),
                subtitle: const Text("Overview of attendance trends"),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Monthly summary coming soon!")),
                  );
                },
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: Icon(Icons.people,
                    color: Theme.of(context).colorScheme.secondary),
                title: const Text("Class-wise Reports"),
                subtitle: const Text("View reports for individual classes"),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Class-wise reports coming soon!")),
                  );
                },
              ),
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.download, color: Colors.green),
                title: const Text("Export Reports"),
                subtitle: const Text("Download attendance in Excel/PDF"),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.green),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Export feature coming soon!")),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
