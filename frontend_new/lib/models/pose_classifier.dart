import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import 'pose_type.dart';

class ClassificationResult {
  final PoseType poseType;
  final Map<String, double> angles;

  ClassificationResult({
    required this.poseType,
    required this.angles,
  });
}

class PoseClassifier {
  // 자세 유형별 특징 벡터
  final Map<PoseType, List<double>> _poseFeatures = {
    PoseType.squat: [
      90.0,  // hip_angle
      90.0,  // knee_angle
      15.0,  // ankle_angle
      180.0, // shoulder_angle
    ],
    PoseType.plank: [
      180.0, // shoulder_angle
      90.0,  // elbow_angle
      180.0, // hip_angle
      180.0, // knee_angle
    ],
    PoseType.lunge: [
      90.0,  // front_knee_angle
      90.0,  // back_knee_angle
      180.0, // hip_angle
      180.0, // shoulder_angle
    ],
    PoseType.pushup: [
      180.0, // shoulder_angle
      90.0,  // elbow_angle
      180.0, // hip_angle
      180.0, // knee_angle
    ],
    PoseType.bridge: [
      90.0,  // hip_angle
      90.0,  // knee_angle
      180.0, // shoulder_angle
    ],
  };

  // 자세 유형별 가중치
  final Map<PoseType, List<double>> _poseWeights = {
    PoseType.squat: [0.3, 0.3, 0.2, 0.2],
    PoseType.plank: [0.3, 0.3, 0.2, 0.2],
    PoseType.lunge: [0.3, 0.3, 0.2, 0.2],
    PoseType.pushup: [0.3, 0.3, 0.2, 0.2],
    PoseType.bridge: [0.4, 0.4, 0.2],
  };

  // 자세 분류 수행
  ClassificationResult classifyPose(Pose pose) {
    // 관절 각도 계산
    final angles = _calculateAngles(pose);
    
    // 특징 벡터 생성
    final features = _extractFeatures(angles);
    
    // 각 자세 유형별 유사도 계산
    final scores = <PoseType, double>{};
    _poseFeatures.forEach((type, idealFeatures) {
      final score = _calculateSimilarity(features, idealFeatures, _poseWeights[type]!);
      scores[type] = score;
    });

    // 가장 높은 점수를 가진 자세 유형 선택
    double maxScore = 0;
    PoseType detectedType = PoseType.unknown;

    scores.forEach((type, score) {
      if (score > maxScore) {
        maxScore = score;
        detectedType = type;
      }
    });

    return ClassificationResult(
      poseType: maxScore >= 0.7 ? detectedType : PoseType.unknown,
      angles: angles,
    );
  }

  // 관절 각도 계산
  Map<String, double> _calculateAngles(Pose pose) {
    final angles = <String, double>{};

    // 어깨 각도
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder != null && rightShoulder != null && 
        leftHip != null && rightHip != null) {
      angles['shoulder_angle'] = _calculateShoulderAngle(leftShoulder, rightShoulder, leftHip, rightHip);
    }

    // 팔꿈치 각도
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (leftShoulder != null && leftElbow != null && leftWrist != null) {
      angles['left_elbow_angle'] = _calculateAngle(
        leftShoulder,
        leftElbow,
        leftWrist,
      );
    }

    if (rightShoulder != null && rightElbow != null && rightWrist != null) {
      angles['right_elbow_angle'] = _calculateAngle(
        rightShoulder,
        rightElbow,
        rightWrist,
      );
    }

    // 무릎 각도
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip != null && leftKnee != null && leftAnkle != null) {
      angles['left_knee_angle'] = _calculateAngle(
        leftHip,
        leftKnee,
        leftAnkle,
      );
    }

    if (rightHip != null && rightKnee != null && rightAnkle != null) {
      angles['right_knee_angle'] = _calculateAngle(
        rightHip,
        rightKnee,
        rightAnkle,
      );
    }

    return angles;
  }

  // 특징 벡터 추출
  List<double> _extractFeatures(Map<String, double> angles) {
    final features = <double>[];
    
    // 각도 정규화
    final normalizedAngles = angles.map((key, value) => 
      MapEntry(key, value / 180.0));  // 0~1 범위로 정규화

    // 자세 유형별 특징 추출
    features.add(normalizedAngles['shoulder_angle'] ?? 0);
    features.add(normalizedAngles['left_elbow_angle'] ?? 0);
    features.add(normalizedAngles['right_elbow_angle'] ?? 0);
    features.add(normalizedAngles['left_knee_angle'] ?? 0);
    features.add(normalizedAngles['right_knee_angle'] ?? 0);

    return features;
  }

  // 유사도 계산 (코사인 유사도)
  double _calculateSimilarity(
    List<double> features,
    List<double> idealFeatures,
    List<double> weights,
  ) {
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < features.length; i++) {
      final weight = weights[i];
      dotProduct += weight * features[i] * idealFeatures[i];
      normA += weight * features[i] * features[i];
      normB += weight * idealFeatures[i] * idealFeatures[i];
    }

    if (normA == 0 || normB == 0) return 0;
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  // 각도 계산
  double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final vector1 = Offset(b.x - a.x, b.y - a.y);
    final vector2 = Offset(c.x - b.x, c.y - b.y);

    final dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy;
    final magnitude1 = math.sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy);
    final magnitude2 = math.sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy);

    final cosTheta = dotProduct / (magnitude1 * magnitude2);
    final theta = math.acos(cosTheta.clamp(-1.0, 1.0));
    return theta * 180 / math.pi;
  }

  double _calculateShoulderAngle(PoseLandmark leftShoulder, PoseLandmark rightShoulder, PoseLandmark leftHip, PoseLandmark rightHip) {
    final vector1 = Offset(rightShoulder.x - leftShoulder.x, rightShoulder.y - leftShoulder.y);
    final vector2 = Offset(rightHip.x - leftHip.x, rightHip.y - leftHip.y);

    final dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy;
    final magnitude1 = math.sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy);
    final magnitude2 = math.sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy);

    final cosTheta = dotProduct / (magnitude1 * magnitude2);
    final theta = math.acos(cosTheta.clamp(-1.0, 1.0));
    return theta * 180 / math.pi;
  }
} 