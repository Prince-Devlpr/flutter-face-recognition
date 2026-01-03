import 'dart:io';
import 'package:camera/camera.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StudentStorage {
  static final StudentStorage _instance = StudentStorage._internal();
  factory StudentStorage() => _instance;
  StudentStorage._internal();

  static const String _boxName = "studentsBox";
  late Box _box;

  /// Initialize Hive (call this in main before runApp)
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  /// Load Hive box
  Future<void> _loadBox() async {
    _box = Hive.box(_boxName);
  }

  /// Add a new student
  Future<void> addStudent({
    required String name,
    required String rollNo,
    required String className,
    required XFile photo,
    List<double>? embedding,
  }) async {
    await _loadBox();
    _box.put(rollNo, {
      'name': name,
      'roll_no': rollNo,
      'class_name': className,
      'photo_path': photo.path,
      'embedding': embedding ?? [],
      'present': false,
    });
  }

  /// Get all students
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    await _loadBox();
    return _box.values.map<Map<String, dynamic>>((student) {
      return {
        ...student,
        'photo': File(student['photo_path']),
      };
    }).toList();
  }

  /// Get student by roll number
  Future<Map<String, dynamic>?> getStudentByRoll(String rollNo) async {
    await _loadBox();
    final student = _box.get(rollNo);
    if (student == null) return null;
    return {...student, 'photo': File(student['photo_path'])};
  }

  /// Update embedding
  Future<void> updateEmbedding(String rollNo, List<double> embedding) async {
    await _loadBox();
    final student = _box.get(rollNo);
    if (student != null) {
      student['embedding'] = embedding;
      await _box.put(rollNo, student);
    }
  }

  /// Update attendance
  Future<void> updateAttendance(String rollNo, bool present) async {
    await _loadBox();
    final student = _box.get(rollNo);
    if (student != null) {
      student['present'] = present;
      await _box.put(rollNo, student);
    }
  }

  /// Reset attendance for all students
  Future<void> resetAttendance() async {
    await _loadBox();
    for (var key in _box.keys) {
      final student = _box.get(key);
      student['present'] = false;
      await _box.put(key, student);
    }
  }

  /// Delete / Remove student
  Future<void> removeStudent(String rollNo) async {
    await _loadBox();
    await _box.delete(rollNo);
  }

  /// Check if embedding exists
  Future<bool> hasEmbedding(String rollNo) async {
    await _loadBox();
    final student = _box.get(rollNo);
    if (student == null) return false;
    final embedding = student['embedding'];
    return embedding != null && (embedding as List).isNotEmpty;
  }
}
