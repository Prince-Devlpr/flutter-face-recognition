import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// import your login screen and attendance pages
import 'login_screen.dart';
import 'take_attendance_face.dart';
import 'take_attendance_manual.dart';
import '../storage/student_storage.dart'; // ✅ Hive-based storage

class TeacherDashboard extends StatefulWidget {
  final String name;
  final String className;

  const TeacherDashboard({
    super.key,
    required this.name,
    this.className = "Class 10A",
  });

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  int totalStudents = 0;
  int presentStudents = 0;
  int absentStudents = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClassStats(); // ✅ Load stats from Hive
  }

  /// ---------------- Hive-based fetch ----------------
  Future<void> _loadClassStats() async {
    final students = await StudentStorage().getAllStudents(); // Hive fetch
    totalStudents = students.length;
    presentStudents = students.where((s) => s['present'] == true).length;
    absentStudents = totalStudents - presentStudents;
    if (mounted) setState(() {});
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Hi! ${widget.name}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        bottom: _selectedIndex == 0
            ? TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: "Overview"),
                  Tab(text: "Analytics"),
                ],
              )
            : null,
      ),
      body: _buildPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Classes"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return TabBarView(
          controller: _tabController,
          children: [
            _buildOverview(),
            _buildAnalytics(),
          ],
        );
      case 1:
        return const Center(child: Text("Classes Page (coming soon)"));
      case 2:
        return const Center(child: Text("Reports Page (coming soon)"));
      case 3:
        return _buildProfile();
      default:
        return const Center(child: Text("Page not found"));
    }
  }

  Widget _buildOverview() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Quick Stats - ${widget.className}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.people, color: Colors.white),
            ),
            title: const Text("Total Students",
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              totalStudents.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.check_circle, color: Colors.white),
            ),
            title: const Text("Present",
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              presentStudents.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.cancel, color: Colors.white),
            ),
            title: const Text("Absent",
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              absentStudents.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Take Attendance",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TakeAttendanceFace()),
                  ).then((_) => _loadClassStats()); // ✅ reload after face attendance
                },
                icon: const Icon(Icons.face),
                label: const Text("Face"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TakeAttendanceManual()),
                  ).then((_) => _loadClassStats()); // ✅ reload after manual attendance
                },
                icon: const Icon(Icons.edit),
                label: const Text("Manual"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalytics() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Weekly Attendance",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(height: 200, child: _buildLineChart()),
        const SizedBox(height: 20),
        const Text("Subject-wise Attendance",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(height: 200, child: _buildBarChart()),
      ],
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, _) {
                switch (value.toInt()) {
                  case 1:
                    return const Text("Mon");
                  case 2:
                    return const Text("Tue");
                  case 3:
                    return const Text("Wed");
                  case 4:
                    return const Text("Thu");
                  case 5:
                    return const Text("Fri");
                }
                return const Text("");
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            spots: const [
              FlSpot(1, 40),
              FlSpot(2, 42),
              FlSpot(3, 41),
              FlSpot(4, 44),
              FlSpot(5, 43),
            ],
            color: Colors.blue,
            barWidth: 3,
            belowBarData:
                BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(
              x: 0,
              barRods: [BarChartRodData(toY: 90, color: Colors.blue, width: 20)]),
          BarChartGroupData(
              x: 1,
              barRods: [BarChartRodData(toY: 85, color: Colors.blue, width: 20)]),
          BarChartGroupData(
              x: 2,
              barRods: [BarChartRodData(toY: 88, color: Colors.blue, width: 20)]),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                switch (value.toInt()) {
                  case 0:
                    return const Text("Math");
                  case 1:
                    return const Text("Science");
                  case 2:
                    return const Text("English");
                }
                return const Text("");
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.person, size: 50, color: Colors.blue),
        ),
        const SizedBox(height: 16),
        Center(
            child: Text(widget.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        Text(
          widget.className,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.settings, color: Colors.blue),
          title: const Text("Settings"),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text("Logout"),
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }
}
