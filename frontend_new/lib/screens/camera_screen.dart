import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/pose_analysis_screen.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';

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
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.single,
    ),
  );
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _showGrid = true;
  bool _isBalanced = false;
  double _horizontalBalance = 0.0;
  double _verticalBalance = 0.0;
  XFile? _capturedImage;
  List<CameraDescription> cameras = [];
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (!await _checkPermissions()) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카메라를 찾을 수 없습니다.')),
        );
      }
      return;
    }

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize();

    try {
      await _initializeControllerFuture;
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카메라 초기화 실패: $e')),
        );
      }
    }
  }

  Future<bool> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('카메라 권한이 필요합니다.')),
          );
        }
        return false;
      }
    }
    return true;
  }

  Future<String?> _takePicture() async {
    try {
      await _initializeControllerFuture;

      final image = await _controller.takePicture();
      final imageFile = File(image.path);

      // 포즈 감지
      final inputImage = InputImage.fromFilePath(image.path);
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('포즈를 감지할 수 없습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      return image.path;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사진 촬영 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  void _updateBalance() {
    // TODO: 실제 균형 상태 계산 로직 구현
    setState(() {
      _horizontalBalance = 0.0; // -1.0 ~ 1.0
      _verticalBalance = 0.0; // -1.0 ~ 1.0
      _isBalanced = _horizontalBalance.abs() < 0.1 && _verticalBalance.abs() < 0.1;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.viewType} 촬영'),
        backgroundColor: const Color(0xFF4A55E7),
      ),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          _buildGuideOverlay(),
          _buildControls(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final imagePath = await _takePicture();
          if (imagePath != null && mounted) {
            Navigator.pop(context, imagePath);
          }
        },
        backgroundColor: const Color(0xFF4A55E7),
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Widget _buildGuideOverlay() {
    return CustomPaint(
      painter: GuidePainter(
        showGrid: _showGrid,
        isBalanced: _isBalanced,
        horizontalBalance: _horizontalBalance,
        verticalBalance: _verticalBalance,
      ),
      child: Container(),
    );
  }

  Widget _buildControls() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _showGrid ? Icons.grid_on : Icons.grid_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() => _showGrid = !_showGrid);
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBalanceIndicator('수평', _horizontalBalance),
                _buildCaptureButton(),
                _buildBalanceIndicator('수직', _verticalBalance),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceIndicator(String label, double value) {
    final color = value.abs() < 0.1 ? Colors.green : Colors.red;
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              '${(value * 100).abs().toStringAsFixed(0)}%',
              style: TextStyle(color: color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: () async {
        final imagePath = await _takePicture();
        if (imagePath != null && mounted) {
          Navigator.pop(context, imagePath);
        }
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _isBalanced ? Colors.green : Colors.red,
            width: 4,
          ),
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class GuidePainter extends CustomPainter {
  final bool showGrid;
  final bool isBalanced;
  final double horizontalBalance;
  final double verticalBalance;

  GuidePainter({
    required this.showGrid,
    required this.isBalanced,
    required this.horizontalBalance,
    required this.verticalBalance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = isBalanced ? Colors.green : Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 중심 십자선
    canvas.drawLine(
      Offset(center.dx - 30, center.dy),
      Offset(center.dx + 30, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 30),
      Offset(center.dx, center.dy + 30),
      paint,
    );

    if (showGrid) {
      // 격자 무늬
      final gridPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 1;

      // 수평선
      for (var i = 1; i <= 2; i++) {
        final y = size.height * (i / 3);
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          gridPaint,
        );
      }

      // 수직선
      for (var i = 1; i <= 2; i++) {
        final x = size.width * (i / 3);
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          gridPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(GuidePainter oldDelegate) {
    return showGrid != oldDelegate.showGrid ||
        isBalanced != oldDelegate.isBalanced ||
        horizontalBalance != oldDelegate.horizontalBalance ||
        verticalBalance != oldDelegate.verticalBalance;
  }
} 