import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  final String viewType;
  
  const CameraScreen({
    Key? key,
    required this.viewType,
  }) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isBalanced = false;
  double _roll = 0.0;
  double _pitch = 0.0;
  XFile? _capturedImage;
  List<CameraDescription> cameras = [];
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeSensors();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('카메라 초기화 오류: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (cameras.length < 2) return;

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length;
      _isInitialized = false;
    });

    await _controller?.dispose();

    _controller = CameraController(
      cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('카메라 전환 오류: $e');
    }
  }

  void _initializeSensors() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _roll = atan2(-event.y, -event.z) * 180 / pi;
        _pitch = atan2(-event.x, sqrt(event.y * event.y + event.z * event.z)) * 180 / pi;
        _isBalanced = _roll.abs() < 3.0 && _pitch.abs() < 3.0;
      });
    });
  }

  Widget _buildGridLines() {
    return CustomPaint(
      size: Size.infinite,
      painter: GridPainter(),
    );
  }

  Widget _buildLevelIndicator() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isBalanced ? Colors.green.withOpacity(0.7) : Colors.red.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _isBalanced ? '수평 상태' : '기기를 수평으로 맞추세요',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelineText() {
    String guideText = '';
    switch (widget.viewType) {
      case 'FRONT':
        guideText = '• 정면을 바라보고 서주세요\n• 양팔을 45도 정도 벌려주세요\n• 전신이 모두 보이도록 해주세요';
        break;
      case 'SIDE':
        guideText = '• 옆으로 서서 한쪽 방향을 봐주세요\n• 팔은 자연스럽게 내려주세요\n• 전신이 모두 보이도록 해주세요';
        break;
      case 'BACK':
        guideText = '• 뒤를 보고 서주세요\n• 양팔을 45도 정도 벌려주세요\n• 전신이 모두 보이도록 해주세요';
        break;
    }

    return Positioned(
      top: 80,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '촬영 가이드',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansKR',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              guideText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'NotoSansKR',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      print('사진 촬영 오류: $e');
    }
  }

  void _retakePicture() {
    setState(() {
      _capturedImage = null;
    });
  }

  void _saveImage() {
    if (_capturedImage != null) {
      Navigator.pop(context, _capturedImage);
    }
  }

  Widget _buildPreviewScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Image.file(
              File(_capturedImage!.path),
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _retakePicture,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    '다시 찍기',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'NotoSansKR',
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _saveImage,
                  icon: const Icon(Icons.check, color: Colors.green),
                  label: const Text(
                    '저장',
                    style: TextStyle(
                      color: Colors.green,
                      fontFamily: 'NotoSansKR',
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

  Widget _buildCameraUI() {
    return Stack(
      children: [
        CameraPreview(_controller!),
        _buildGridLines(),
        _buildLevelIndicator(),
        _buildGuidelineText(),
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
              FloatingActionButton(
                backgroundColor: Colors.white,
                child: const Icon(Icons.camera_alt, color: Colors.black),
                onPressed: _takePicture,
              ),
              IconButton(
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                onPressed: _switchCamera,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_capturedImage != null) {
      return _buildPreviewScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildCameraUI(),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    // 수직선
    for (int i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 수평선
    for (int i = 1; i < 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 