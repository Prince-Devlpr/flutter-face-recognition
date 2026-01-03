import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../storage/student_storage.dart';
import 'login_screen.dart';

// ---------------- FaceNet Service ----------------
class FaceNetService {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/models/mobile_face_net.tflite');
      print("✅ MobileFaceNet loaded");
    } catch (e) {
      print("❌ Failed to load model: $e");
      _interpreter = null;
    }
  }

  List<double> getEmbedding(img.Image faceImg) {
    if (_interpreter == null) return List<double>.filled(192, 0.0);

    final resized = img.copyResize(faceImg, width: 112, height: 112);

    var input = List.generate(
      1,
      (_) => List.generate(
        112,
        (y) => List.generate(
          112,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              (pixel.r - 128) / 128.0,
              (pixel.g - 128) / 128.0,
              (pixel.b - 128) / 128.0,
            ];
          },
        ),
      ),
    );

    var output = List.generate(1, (_) => List.filled(192, 0.0));
    try {
      _interpreter!.run(input, output);
    } catch (e) {
      print("❌ Error running interpreter: $e");
      return List<double>.filled(192, 0.0);
    }

    return List<double>.from(output[0]);
  }
}

class AdministratorDashboard extends StatefulWidget {
  final String name;
  const AdministratorDashboard({super.key, required this.name});

  @override
  State<AdministratorDashboard> createState() => _AdministratorDashboardState();
}

class _AdministratorDashboardState extends State<AdministratorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  final FaceNetService _faceNetService = FaceNetService();
  final List<Map<String, dynamic>> schoolStats = [
    {"title": "Total Students", "count": 1250, "icon": Icons.people},
    {"title": "Teachers", "count": 45, "icon": Icons.school},
    {"title": "Present Today", "count": 1180, "icon": Icons.check_circle},
    {"title": "Absent Today", "count": 70, "icon": Icons.cancel},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _faceNetService.loadModel();
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ---------------- Generate embedding ----------------
  Future<List<double>> generateFaceVector(XFile imageFile) async {
    if (_faceNetService._interpreter == null) {
      return List<double>.filled(192, 0.0);
    }

    final inputImage = InputImage.fromFilePath(imageFile.path);
    final options = FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      performanceMode: FaceDetectorMode.accurate,
    );
    final faceDetector = FaceDetector(options: options);

    final List<Face> faces = await faceDetector.processImage(inputImage);
    faceDetector.close();

    if (faces.isEmpty) return List<double>.filled(192, 0.0);

    final bytes = await File(imageFile.path).readAsBytes();
    img.Image? baseImage = img.decodeImage(bytes);
    if (baseImage == null) return List<double>.filled(192, 0.0);

    final face = faces.first.boundingBox;

    final cropped = img.copyCrop(
      baseImage,
      x: face.left.toInt().clamp(0, baseImage.width - 1),
      y: face.top.toInt().clamp(0, baseImage.height - 1),
      width: face.width.toInt().clamp(1, baseImage.width),
      height: face.height.toInt().clamp(1, baseImage.height),
    );

    return _faceNetService.getEmbedding(cropped);
  }

  // ---------------- Add Student Dialog ----------------
  Future<void> _openAddStudentDialog() async {
    final nameController = TextEditingController();
    final rollController = TextEditingController();
    final classController = TextEditingController();
    XFile? capturedImage;
    bool embeddingValid = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Add Student"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: "Student Name"),
                  ),
                  TextField(
                    controller: rollController,
                    decoration: const InputDecoration(labelText: "Roll No"),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: classController,
                    decoration: const InputDecoration(labelText: "Class"),
                  ),
                  const SizedBox(height: 12),

                  // ✅ Show embedding success message
                  if (embeddingValid) ...[
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 32),
                    const SizedBox(height: 4),
                    const Text(
                      "Embedding Successful",
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                  ],

                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final photo =
                          await picker.pickImage(source: ImageSource.camera);
                      if (photo != null) {
                        capturedImage = photo;
                        embeddingValid = false;
                        setStateDialog(() {});

                        final embedding =
                            await generateFaceVector(capturedImage!);
                        embeddingValid = embedding.any((v) => v != 0.0);

                        setStateDialog(() {});
                      }
                    },
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text("Capture Photo"),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context)),
              ElevatedButton(
                child: const Text("Save Student"),
                onPressed: () async {
                  if (nameController.text.isEmpty ||
                      rollController.text.isEmpty ||
                      classController.text.isEmpty ||
                      capturedImage == null ||
                      !embeddingValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            "Please fill all fields & capture valid photo ❗"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final embedding = await generateFaceVector(capturedImage!);

                  await StudentStorage().addStudent(
                    name: nameController.text,
                    rollNo: rollController.text,
                    className: classController.text,
                    photo: capturedImage!,
                    embedding: embedding,
                  );

                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Student ${nameController.text} added successfully ✅"),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ],
          );
        });
      },
    );
  }

  // ---------------- Remove Student ----------------
  Future<void> _removeStudent(String rollNo, String name) async {
    await StudentStorage().removeStudent(rollNo);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Student $name removed successfully ❌"),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ---------------- Build UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance App - Admin"),
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
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              backgroundColor: Colors.blue,
              onPressed: _openAddStudentDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Students"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  // ---------------- Page Builder ----------------
  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return TabBarView(
          controller: _tabController,
          children: [_buildOverview(), _buildAnalytics()],
        );
      case 1:
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: StudentStorage().getAllStudents(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final students = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.person, size: 40, color: Colors.blue),
                    title: Text(student['name']),
                    subtitle: Text(
                      "Roll: ${student['roll_no']} | Class: ${student['class_name']}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeStudent(
                          student['roll_no'], student['name']),
                    ),
                  ),
                );
              },
            );
          },
        );
      case 2:
        return const Center(child: Text("Reports Page (coming soon)"));
      case 3:
        return _buildProfile();
      default:
        return const Center(child: Text("Page not found"));
    }
  }

  Widget _buildOverview() {
    return ListView.builder(
      itemCount: schoolStats.length,
      itemBuilder: (context, index) {
        final stat = schoolStats[index];
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Icon(stat["icon"], color: Colors.blue),
            ),
            title: Text(stat["title"],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              stat["count"].toString(),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalytics() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("School Attendance Trend",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(height: 200, child: _buildLineChart()),
        const SizedBox(height: 20),
        const Text("Grade-wise Attendance",
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
              FlSpot(1, 1200),
              FlSpot(2, 1180),
              FlSpot(3, 1195),
              FlSpot(4, 1170),
              FlSpot(5, 1210),
            ],
            color: Colors.blue,
            barWidth: 3,
            belowBarData: BarAreaData(
                show: true, color: Colors.blueAccent.withOpacity(0.2)),
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
              barRods: [BarChartRodData(toY: 92, color: Colors.blue, width: 20)]),
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
                    return const Text("8th");
                  case 1:
                    return const Text("9th");
                  case 2:
                    return const Text("10th");
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
          child: const Icon(Icons.admin_panel_settings,
              size: 50, color: Colors.blue),
        ),
        const SizedBox(height: 16),
        Center(
            child: Text(widget.name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold))),
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
      ],
    );
  }
}
