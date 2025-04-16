import 'package:flutter/foundation.dart';
import 'pose_type.dart';

class PoseAnalysisResult {
  final String id;
  final DateTime timestamp;
  final PoseType poseType;
  final double score;
  final Map<String, double> angles;
  final Map<String, double> symmetryScores;
  final Map<String, double> alignmentScores;
  final String feedback;
  final String? imagePath;

  PoseAnalysisResult({
    required this.id,
    required this.timestamp,
    required this.poseType,
    required this.score,
    required this.angles,
    required this.symmetryScores,
    required this.alignmentScores,
    required this.feedback,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'poseType': poseType.toString(),
      'score': score,
      'angles': angles,
      'symmetryScores': symmetryScores,
      'alignmentScores': alignmentScores,
      'feedback': feedback,
      'imagePath': imagePath,
    };
  }

  factory PoseAnalysisResult.fromJson(Map<String, dynamic> json) {
    return PoseAnalysisResult(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      poseType: PoseType.values.firstWhere(
        (e) => e.toString() == json['poseType'],
        orElse: () => PoseType.unknown,
      ),
      score: json['score'],
      angles: Map<String, double>.from(json['angles']),
      symmetryScores: Map<String, double>.from(json['symmetryScores']),
      alignmentScores: Map<String, double>.from(json['alignmentScores']),
      feedback: json['feedback'],
      imagePath: json['imagePath'],
    );
  }
} 