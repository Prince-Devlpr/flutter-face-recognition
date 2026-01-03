import 'dart:io';
import 'dart:ui' as ui;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  final FaceDetector _detector;

  FaceDetectorService()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.fast,
            enableLandmarks: false,
            enableContours: false,
            enableClassification: false,
          ),
        );

  /// Returns the bounding box of the largest face in the image file,
  /// or null if no face detected. Box coordinates are in image pixel space.
  Future<ui.Rect?> detectLargestFaceRect(File imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final faces = await _detector.processImage(inputImage);
    if (faces.isEmpty) return null;

    // choose largest face by area
    faces.sort((a, b) {
      final aArea = a.boundingBox.width * a.boundingBox.height;
      final bArea = b.boundingBox.width * b.boundingBox.height;
      return bArea.compareTo(aArea);
    });
    return faces.first.boundingBox;
  }

  void close() => _detector.close();
}
