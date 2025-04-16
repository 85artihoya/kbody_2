import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraService extends ChangeNotifier {
  CameraController? _controller;
  bool _isInitialized = false;
  String? _error;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  Future<void> initialize() async {
    _error = null;

    try {
      // 카메라 권한 요청
      final status = await Permission.camera.request();
      if (status.isDenied) {
        _error = '카메라 권한이 필요합니다';
        notifyListeners();
        return;
      }

      // 사용 가능한 카메라 목록 가져오기
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _error = '사용 가능한 카메라가 없습니다';
        notifyListeners();
        return;
      }

      // 후면 카메라 선택 (없으면 첫 번째 카메라)
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // 카메라 컨트롤러 초기화
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = '카메라 초기화에 실패했습니다: $e';
      notifyListeners();
    }
  }

  Future<String?> takePicture() async {
    if (_controller == null || !_isInitialized) {
      _error = '카메라가 준비되지 않았습니다';
      notifyListeners();
      return null;
    }

    try {
      // 사진 촬영
      final XFile image = await _controller!.takePicture();

      // 앱 내부 저장소에 이미지 저장
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'k_body_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = path.join(directory.path, fileName);
      await image.saveTo(savedPath);

      return savedPath;
    } catch (e) {
      _error = '사진 촬영에 실패했습니다: $e';
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
} 