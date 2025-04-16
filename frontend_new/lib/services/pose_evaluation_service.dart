import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import '../models/pose_type.dart';
import '../models/pose_classifier.dart';

class PoseEvaluationService extends ChangeNotifier {
  double? _score;
  String? _feedback;
  Map<String, double>? _angles;
  PoseType _poseType = PoseType.unknown;
  Map<String, double> _symmetryScores = {};
  Map<String, double> _alignmentScores = {};
  final _poseClassifier = PoseClassifier();

  double? get score => _score;
  String? get feedback => _feedback;
  Map<String, double>? get angles => _angles;
  PoseType get poseType => _poseType;
  Map<String, double> get symmetryScores => _symmetryScores;
  Map<String, double> get alignmentScores => _alignmentScores;

  void evaluatePose(Pose pose) {
    // 머신러닝 기반 자세 분류
    final classificationResult = _poseClassifier.classifyPose(pose);
    _poseType = classificationResult.poseType;
    _angles = classificationResult.angles;

    // 대칭성과 정렬 계산
    _calculateSymmetry(pose);
    _calculateAlignment(pose);
    
    // 점수 계산 및 피드백 생성
    _calculateScore();
    _generateFeedback();
    notifyListeners();
  }

  void _detectPoseType(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    // 모든 필요한 관절이 감지되었는지 확인
    if (leftHip == null || rightHip == null || 
        leftKnee == null || rightKnee == null ||
        leftAnkle == null || rightAnkle == null ||
        leftShoulder == null || rightShoulder == null) {
      _poseType = PoseType.unknown;
      return;
    }

    // 각 자세 유형에 대한 점수 계산
    final scores = <PoseType, double>{};
    
    // 스쿼트 점수 계산
    final hipAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    final kneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    final shoulderAngle = _calculateAngle(leftShoulder, rightShoulder, leftHip, rightHip);
    
    final squatScore = _calculatePoseScore(
      {
        'hip_angle': (hipAngle - 90.0).abs(),
        'knee_angle': (kneeAngle - 90.0).abs(),
        'shoulder_angle': (shoulderAngle - 180.0).abs(),
      },
      [10.0, 10.0, 15.0]  // 허용 오차 범위
    );
    scores[PoseType.squat] = squatScore;

    // 플랭크 점수 계산
    if (leftElbow != null && rightElbow != null && 
        leftWrist != null && rightWrist != null) {
      final elbowAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
      final hipAngle = _calculateAngle(leftShoulder, leftHip, leftAnkle);
      
      final plankScore = _calculatePoseScore(
        {
          'elbow_angle': (elbowAngle - 90.0).abs(),
          'hip_angle': (hipAngle - 180.0).abs(),
          'shoulder_angle': (shoulderAngle - 180.0).abs(),
        },
        [15.0, 15.0, 15.0]
      );
      scores[PoseType.plank] = plankScore;
    }

    // 런지 점수 계산
    final frontKneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    final backKneeAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);
    
    final lungeScore = _calculatePoseScore(
      {
        'front_knee_angle': (frontKneeAngle - 90.0).abs(),
        'back_knee_angle': (backKneeAngle - 90.0).abs(),
        'shoulder_angle': (shoulderAngle - 180.0).abs(),
      },
      [15.0, 15.0, 15.0]
    );
    scores[PoseType.lunge] = lungeScore;

    // 푸시업 점수 계산
    if (leftElbow != null && rightElbow != null) {
      final elbowAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
      
      final pushupScore = _calculatePoseScore(
        {
          'elbow_angle': (elbowAngle - 90.0).abs(),
          'shoulder_angle': (shoulderAngle - 180.0).abs(),
          'hip_angle': (hipAngle - 180.0).abs(),
        },
        [15.0, 15.0, 15.0]
      );
      scores[PoseType.pushup] = pushupScore;
    }

    // 브릿지 점수 계산
    final bridgeScore = _calculatePoseScore(
      {
        'hip_angle': (hipAngle - 90.0).abs(),
        'knee_angle': (kneeAngle - 90.0).abs(),
        'shoulder_angle': (shoulderAngle - 180.0).abs(),
      },
      [15.0, 15.0, 15.0]
    );
    scores[PoseType.bridge] = bridgeScore;

    // 가장 높은 점수를 가진 자세 유형 선택
    double maxScore = 0;
    PoseType detectedType = PoseType.unknown;

    scores.forEach((type, score) {
      if (score > maxScore) {
        maxScore = score;
        detectedType = type;
      }
    });

    // 최소 점수 기준 설정 (예: 70점)
    _poseType = maxScore >= 70 ? detectedType : PoseType.unknown;
  }

  double _calculatePoseScore(Map<String, double> angleDifferences, List<double> thresholds) {
    double totalScore = 0;
    int count = 0;

    angleDifferences.forEach((key, difference) {
      final threshold = thresholds[count];
      // 차이가 작을수록 점수가 높음
      final score = math.max(0, 100 - (difference / threshold * 100));
      totalScore += score;
      count++;
    });

    return count > 0 ? totalScore / count : 0;
  }

  void _calculateAngles(Pose pose) {
    _angles = {};

    // 기본 관절 각도 계산
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    // 자세 유형에 따른 각도 계산
    switch (_poseType) {
      case PoseType.squat:
        if (leftHip != null && leftKnee != null && leftAnkle != null) {
          _angles!['hip_angle'] = _calculateAngle(leftHip, leftKnee, leftAnkle);
          _angles!['knee_angle'] = _calculateAngle(leftHip, leftKnee, leftAnkle);
          _angles!['ankle_angle'] = _calculateAngle(leftKnee, leftAnkle, leftAnkle);
        }
        break;
      case PoseType.plank:
        if (leftShoulder != null && leftElbow != null && leftWrist != null) {
          _angles!['shoulder_angle'] = _calculateAngle(leftShoulder, leftElbow, leftWrist);
          _angles!['elbow_angle'] = _calculateAngle(leftShoulder, leftElbow, leftWrist);
        }
        break;
      // 다른 자세 유형에 대한 각도 계산 추가
      default:
        // 기본 각도 계산
        if (leftShoulder != null && rightShoulder != null && 
            leftHip != null && rightHip != null) {
          _angles!['shoulder_angle'] = _calculateAngle(
            leftShoulder,
            rightShoulder,
            leftHip,
            rightHip,
          );
        }
        // ... 기존 각도 계산 로직 유지
    }
  }

  void _calculateSymmetry(Pose pose) {
    _symmetryScores = {};
    
    // 좌우 대칭성 계산
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    if (leftShoulder != null && rightShoulder != null) {
      final shoulderSymmetry = 1.0 - (leftShoulder.y - rightShoulder.y).abs() / 100.0;
      _symmetryScores['shoulder'] = math.max(0, shoulderSymmetry);
    }

    if (leftHip != null && rightHip != null) {
      final hipSymmetry = 1.0 - (leftHip.y - rightHip.y).abs() / 100.0;
      _symmetryScores['hip'] = math.max(0, hipSymmetry);
    }

    if (leftKnee != null && rightKnee != null) {
      final kneeSymmetry = 1.0 - (leftKnee.y - rightKnee.y).abs() / 100.0;
      _symmetryScores['knee'] = math.max(0, kneeSymmetry);
    }
  }

  void _calculateAlignment(Pose pose) {
    _alignmentScores = {};
    
    // 중력선과의 정렬 계산
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftShoulder != null && rightShoulder != null && 
        leftHip != null && rightHip != null &&
        leftAnkle != null && rightAnkle != null) {
      // 어깨-엉덩이-발목 정렬
      final shoulderHipAlignment = _calculateAlignmentScore(
        leftShoulder, rightShoulder,
        leftHip, rightHip,
      );
      _alignmentScores['shoulder_hip'] = shoulderHipAlignment;

      final hipAnkleAlignment = _calculateAlignmentScore(
        leftHip, rightHip,
        leftAnkle, rightAnkle,
      );
      _alignmentScores['hip_ankle'] = hipAnkleAlignment;
    }
  }

  double _calculateAlignmentScore(
    PoseLandmark topLeft, PoseLandmark topRight,
    PoseLandmark bottomLeft, PoseLandmark bottomRight,
  ) {
    final topCenter = Offset(
      (topLeft.x + topRight.x) / 2,
      (topLeft.y + topRight.y) / 2,
    );
    final bottomCenter = Offset(
      (bottomLeft.x + bottomRight.x) / 2,
      (bottomLeft.y + bottomRight.y) / 2,
    );

    final verticalDistance = (bottomCenter.dy - topCenter.dy).abs();
    final horizontalDistance = (bottomCenter.dx - topCenter.dx).abs();
    
    // 수직 정렬이 잘 되어있을수록 점수가 높음
    return 1.0 - (horizontalDistance / verticalDistance).clamp(0.0, 1.0);
  }

  void _calculateScore() {
    if (_angles == null) {
      _score = 0;
      return;
    }

    double totalScore = 0;
    int count = 0;

    // 자세 유형별 이상적인 각도와 비교
    final idealAngles = _poseType.idealAngles;
    _angles!.forEach((key, angle) {
      if (idealAngles.containsKey(key)) {
        final difference = (angle - idealAngles[key]!).abs();
        totalScore += math.max(0, 100 - difference);
        count++;
      }
    });

    // 대칭성 점수 반영
    if (_symmetryScores.isNotEmpty) {
      final symmetryScore = _symmetryScores.values.reduce((a, b) => a + b) / 
                           _symmetryScores.length;
      totalScore += symmetryScore * 100;
      count++;
    }

    // 정렬 점수 반영
    if (_alignmentScores.isNotEmpty) {
      final alignmentScore = _alignmentScores.values.reduce((a, b) => a + b) / 
                            _alignmentScores.length;
      totalScore += alignmentScore * 100;
      count++;
    }

    _score = count > 0 ? totalScore / count : 0;
  }

  void _generateFeedback() {
    if (_angles == null || _score == null) {
      _feedback = '자세를 분석할 수 없습니다.';
      return;
    }

    final feedbacks = <String>[];
    feedbacks.add('현재 자세: ${_poseType.displayName}');

    // 자세 유형별 피드백
    switch (_poseType) {
      case PoseType.squat:
        _generateSquatFeedback(feedbacks);
        break;
      case PoseType.plank:
        _generatePlankFeedback(feedbacks);
        break;
      // 다른 자세 유형에 대한 피드백 추가
      default:
        _generateGeneralFeedback(feedbacks);
    }

    // 대칭성 피드백
    _symmetryScores.forEach((key, score) {
      if (score < 0.8) {
        feedbacks.add('${key}의 좌우 대칭이 좋지 않습니다.');
      }
    });

    // 정렬 피드백
    _alignmentScores.forEach((key, score) {
      if (score < 0.8) {
        feedbacks.add('${key}의 정렬이 좋지 않습니다.');
      }
    });

    if (feedbacks.isEmpty) {
      _feedback = '좋은 자세입니다!';
    } else {
      _feedback = feedbacks.join('\n');
    }
  }

  void _generateSquatFeedback(List<String> feedbacks) {
    if (_angles!.containsKey('hip_angle')) {
      final angle = _angles!['hip_angle']!;
      if (angle < 80) {
        feedbacks.add('엉덩이가 너무 낮습니다. 조금 더 일어나세요.');
      } else if (angle > 100) {
        feedbacks.add('엉덩이가 너무 높습니다. 조금 더 내려가세요.');
      }
    }

    if (_angles!.containsKey('knee_angle')) {
      final angle = _angles!['knee_angle']!;
      if (angle < 80) {
        feedbacks.add('무릎이 너무 구부러져 있습니다.');
      } else if (angle > 100) {
        feedbacks.add('무릎이 너무 펴져 있습니다.');
      }
    }
  }

  void _generatePlankFeedback(List<String> feedbacks) {
    if (_angles!.containsKey('shoulder_angle')) {
      final angle = _angles!['shoulder_angle']!;
      if (angle < 170) {
        feedbacks.add('어깨가 구부러져 있습니다. 어깨를 펴주세요.');
      }
    }

    if (_angles!.containsKey('elbow_angle')) {
      final angle = _angles!['elbow_angle']!;
      if (angle < 80) {
        feedbacks.add('팔꿈치가 너무 구부러져 있습니다.');
      } else if (angle > 100) {
        feedbacks.add('팔꿈치가 너무 펴져 있습니다.');
      }
    }
  }

  void _generateGeneralFeedback(List<String> feedbacks) {
    // 기본적인 피드백 생성
    if (_angles!.containsKey('shoulder_angle')) {
      final angle = _angles!['shoulder_angle']!;
      if (angle < 170) {
        feedbacks.add('어깨가 구부러져 있습니다. 어깨를 펴주세요.');
      } else if (angle > 190) {
        feedbacks.add('어깨가 너무 뒤로 젖혀져 있습니다. 자연스럽게 펴주세요.');
      }
    }
    // ... 기존 피드백 로직 유지
  }

  double _calculateAngle(PoseLandmark a, PoseLandmark b, PoseLandmark c, [PoseLandmark? d]) {
    if (d != null) {
      final vector1 = Offset(b.x - a.x, b.y - a.y);
      final vector2 = Offset(d.x - c.x, d.y - c.y);
      final dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy;
      final magnitude1 = math.sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy);
      final magnitude2 = math.sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy);
      final angle = math.acos(dotProduct / (magnitude1 * magnitude2));
      return angle * 180 / math.pi;
    } else {
      final vector1 = Offset(b.x - a.x, b.y - a.y);
      final vector2 = Offset(c.x - b.x, c.y - b.y);
      final dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy;
      final magnitude1 = math.sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy);
      final magnitude2 = math.sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy);
      final angle = math.acos(dotProduct / (magnitude1 * magnitude2));
      return angle * 180 / math.pi;
    }
  }
} 