import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import '../storage/student_storage.dart';
import 'Administrator_dashboard.dart'; // For FaceNetService

class TakeAttendanceFace extends StatefulWidget {
  const TakeAttendanceFace({super.key});

  @override
  State<TakeAttendanceFace> createState() => _TakeAttendanceFaceState();
}

class _TakeAttendanceFaceState extends State<TakeAttendanceFace> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 1;
  bool _isCameraInitialized = false;

  late FaceDetector _faceDetector;
  final FaceNetService _faceNetService = FaceNetService();
  List<Map<String, dynamic>> students = [];

  int totalStudents = 0;
  int presentStudents = 0;
  int absentStudents = 0;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    _faceNetService.loadModel().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ FaceNet model loaded")),
      );
    });

    _loadStudents();
    _requestCameraPermission();
  }

  Future<void> _loadStudents() async {
    students = await StudentStorage().getAllStudents();
    totalStudents = students.length;
    presentStudents = students.where((s) => s['present'] == true).length;
    absentStudents = totalStudents - presentStudents;
    setState(() {});
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      _initCamera();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Camera permission denied"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // safety: if selected index is out of range, reset to 0
    if (_selectedCameraIndex >= _cameras.length) {
      _selectedCameraIndex = 0;
    }

    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    setState(() => _isCameraInitialized = true);
  }

  Future<void> _captureAndDetectFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      final XFile picture = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(picture.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No face detected!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final img.Image? capturedImage = img.decodeImage(await picture.readAsBytes());
      if (capturedImage == null) return;

      List<String> foundStudents = [];

      for (var face in faces) {
        final rect = face.boundingBox;
        final faceCrop = img.copyCrop(
          capturedImage,
          x: rect.left.toInt().clamp(0, capturedImage.width - 1),
          y: rect.top.toInt().clamp(0, capturedImage.height - 1),
          width: rect.width.toInt().clamp(1, capturedImage.width),
          height: rect.height.toInt().clamp(1, capturedImage.height),
        );

        final embedding = await _faceNetService.getEmbedding(faceCrop);
        if (embedding == null) continue;

        double bestSim = 0;
        Map<String, dynamic>? bestStudent;

        for (var student in students) {
          final studentEmbedding = student['embedding'] as List<double>? ?? [];
          if (studentEmbedding.isEmpty) continue;

          final similarity = _cosineSimilarity(studentEmbedding, embedding);
          if (similarity > bestSim) {
            bestSim = similarity;
            bestStudent = student;
          }
        }

        if (bestSim >= 0.6 && bestStudent != null) {
          await StudentStorage().updateAttendance(bestStudent['roll_no'], true);
          bestStudent['present'] = true; // update local copy
          foundStudents.add(bestStudent['name'] ?? "Unknown");
        }
      }

      await _updateAttendanceStats();

      if (foundStudents.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("🎉 Found & marked present: ${foundStudents.join(", ")}"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ No matching student found"),
            backgroundColor: Colors.orange,
          ),
        );
      }

      setState(() {});
    } catch (e) {
      debugPrint("❌ Error capturing/detecting face: $e");
    }
  }

  Future<void> _updateAttendanceStats() async {
    students = await StudentStorage().getAllStudents();
    presentStudents = students.where((s) => s['present'] == true).length;
    absentStudents = totalStudents - presentStudents;
    setState(() {});
  }

  void _submitAttendance() async {
    await _updateAttendanceStats();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Attendance submitted ✅\nPresent: $presentStudents, Absent: $absentStudents"),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _switchCamera() async {
    if (_cameras.length < 2) return;
    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });
    await _cameraController?.dispose();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Face Attendance"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCard("Total", totalStudents, Colors.blue),
                _statCard("Present", presentStudents, Colors.green),
                _statCard("Absent", absentStudents, Colors.red),
              ],
            ),
          ),
          if (_isCameraInitialized)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(0, 5),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _captureAndDetectFace,
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text("Capture & Detect Face"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(240, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _submitAttendance,
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text("Submit Attendance"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(240, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, Color color) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 100,
        child: Column(
          children: [
            Text(
              "$value",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 5),
            Text(label,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  // --- Added cosine similarity helper ---
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a.length != b.length) {
      // If lengths differ, compute up to min length (safer than throwing)
      final minLen = min(a.length, b.length);
      double dot = 0;
      double normA = 0;
      double normB = 0;
      for (int i = 0; i < minLen; i++) {
        dot += a[i] * b[i];
        normA += a[i] * a[i];
        normB += b[i] * b[i];
      }
      if (normA == 0 || normB == 0) return 0.0;
      return dot / (sqrt(normA) * sqrt(normB));
    } else {
      double dot = 0;
      double normA = 0;
      double normB = 0;
      for (int i = 0; i < a.length; i++) {
        dot += a[i] * b[i];
        normA += a[i] * a[i];
        normB += b[i] * b[i];
      }
      if (normA == 0 || normB == 0) return 0.0;
      return dot / (sqrt(normA) * sqrt(normB));
    }
  }
}
