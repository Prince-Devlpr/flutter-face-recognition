import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  // Token methods
  static Future<void> saveToken(String token) async {
    await _storage.write(key: "jwt_token", value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: "jwt_token");
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: "jwt_token");
  }

  // Teacher name methods
  static Future<void> saveTeacherName(String name) async {
    await _storage.write(key: "teacher_name", value: name);
  }

  static Future<String?> getTeacherName() async {
    return await _storage.read(key: "teacher_name");
  }

  static Future<void> deleteTeacherName() async {
    await _storage.delete(key: "teacher_name");
  }
}