import 'package:flutter/material.dart';
import '../storage/student_storage.dart';
import 'dart:io';

class TakeAttendanceManual extends StatefulWidget {
  const TakeAttendanceManual({super.key});

  @override
  _TakeAttendanceManualState createState() => _TakeAttendanceManualState();
}

class _TakeAttendanceManualState extends State<TakeAttendanceManual> {
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    students = await StudentStorage().getAllStudents();
    setState(() {});
  }

  void _toggleAttendance(int index, bool value) async {
    final student = students[index];
    await StudentStorage().updateAttendance(student['roll_no'], value);
    student['present'] = value;
    setState(() {});
  }

  void _saveAttendance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Attendance saved successfully!")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    int presentCount =
        students.where((s) => s['present'] == true).length;
    int absentCount = students.length - presentCount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Manual Attendance"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  elevation: 2,
                  child: SwitchListTile(
                    title: Text(
                      student['name'] ?? "Unknown",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Roll No: ${student['roll_no'] ?? "N/A"}",
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black54),
                        ),
                        Text(
                          student['present'] ? "Present" : "Absent",
                          style: TextStyle(
                            color: student['present']
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    activeColor: Colors.blue,
                    inactiveThumbColor: Colors.white,
                    value: student['present'] ?? false,
                    onChanged: (val) => _toggleAttendance(index, val),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Chip(
                  label: Text("Present: $presentCount",
                      style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.green,
                ),
                Chip(
                  label: Text("Absent: $absentCount",
                      style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.red,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _saveAttendance,
              child: const Text(
                "Save Attendance",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
