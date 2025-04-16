enum PoseType {
  squat,    // 스쿼트
  plank,    // 플랭크
  lunge,    // 런지
  pushup,   // 푸시업
  bridge,   // 브릿지
  unknown   // 미확인
}

extension PoseTypeExtension on PoseType {
  String get displayName {
    switch (this) {
      case PoseType.squat:
        return '스쿼트';
      case PoseType.plank:
        return '플랭크';
      case PoseType.lunge:
        return '런지';
      case PoseType.pushup:
        return '푸시업';
      case PoseType.bridge:
        return '브릿지';
      case PoseType.unknown:
        return '미확인';
    }
  }

  Map<String, double> get idealAngles {
    switch (this) {
      case PoseType.squat:
        return {
          'hip_angle': 90.0,
          'knee_angle': 90.0,
          'ankle_angle': 15.0,
          'shoulder_angle': 180.0,
        };
      case PoseType.plank:
        return {
          'shoulder_angle': 180.0,
          'elbow_angle': 90.0,
          'hip_angle': 180.0,
          'knee_angle': 180.0,
        };
      case PoseType.lunge:
        return {
          'front_knee_angle': 90.0,
          'back_knee_angle': 90.0,
          'hip_angle': 180.0,
          'shoulder_angle': 180.0,
        };
      case PoseType.pushup:
        return {
          'shoulder_angle': 180.0,
          'elbow_angle': 90.0,
          'hip_angle': 180.0,
          'knee_angle': 180.0,
        };
      case PoseType.bridge:
        return {
          'hip_angle': 90.0,
          'knee_angle': 90.0,
          'shoulder_angle': 180.0,
        };
      case PoseType.unknown:
        return {};
    }
  }

  List<String> get keyPoints {
    switch (this) {
      case PoseType.squat:
        return ['hip', 'knee', 'ankle', 'shoulder'];
      case PoseType.plank:
        return ['shoulder', 'elbow', 'hip', 'knee'];
      case PoseType.lunge:
        return ['front_knee', 'back_knee', 'hip', 'shoulder'];
      case PoseType.pushup:
        return ['shoulder', 'elbow', 'hip', 'knee'];
      case PoseType.bridge:
        return ['hip', 'knee', 'shoulder'];
      case PoseType.unknown:
        return [];
    }
  }
} 