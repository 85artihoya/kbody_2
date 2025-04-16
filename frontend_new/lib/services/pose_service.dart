import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseService extends ChangeNotifier {
  final _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );
  List<Pose>? _poses;
  String? _error;

  List<Pose>? get poses => _poses;
  String? get error => _error;

  Future<void> detectPose(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      _poses = await _poseDetector.processImage(inputImage);
      notifyListeners();
    } catch (e) {
      _error = '포즈 분석에 실패했습니다: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _poseDetector.close();
    super.dispose();
  }
} 