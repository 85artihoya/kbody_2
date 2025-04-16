import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/pose_service.dart';
import '../services/pose_evaluation_service.dart';
import 'package:image_picker/image_picker.dart';

enum BodyView {
  front('FRONT', 'front_angle', 'home_Front_Back_body'),
  side('SIDE', 'side_angle', 'home_side_body'),
  back('BACK', 'back_angle', 'home_Front_Back_body');

  final String label;
  final String angleImage;
  final String bodyImage;
  const BodyView(this.label, this.angleImage, this.bodyImage);
}

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  BodyView _selectedView = BodyView.front;
  final Map<BodyView, File?> _selectedImages = {};
  bool _isBalanced = false;

  Widget _buildBodyImage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/images/${_selectedView.angleImage}.png',
          height: MediaQuery.of(context).size.height * 0.4,
          fit: BoxFit.contain,
        ),
        if (_selectedImages[_selectedView] != null)
          Image.file(
            _selectedImages[_selectedView]!,
            height: MediaQuery.of(context).size.height * 0.4,
            fit: BoxFit.contain,
          ),
      ],
    );
  }

  Widget _buildViewButton(BodyView view) {
    final isSelected = _selectedView == view;
    final hasImage = _selectedImages[view] != null;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = view;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A55E7) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/${view.bodyImage}.png',
                  height: 60,
                  color: isSelected ? Colors.white : hasImage ? const Color(0xFF4A55E7) : Colors.grey[400],
                ),
                if (hasImage)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4A55E7),
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              view.label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'NotoSansKR',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    try {
      final result = await Navigator.push<XFile>(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            viewType: _selectedView.label,
          ),
        ),
      );
      
      if (result != null) {
        setState(() {
          _selectedImages[_selectedView] = File(result.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사진 촬영 중 오류가 발생했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _selectedImages[_selectedView] = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사진 선택 중 오류가 발생했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool get canAnalyze => _selectedImages.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A55E7),
        title: const Text(
          '포즈업',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'NotoSansKR',
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          const Text(
            'BODY MEASUREMENT',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoSansKR',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedView.label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontFamily: 'NotoSansKR',
            ),
          ),
          const SizedBox(height: 24),
          _buildBodyImage(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: BodyView.values.map(_buildViewButton).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _takePicture,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '촬영하기',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'NotoSansKR',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickImage,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '사진선택',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'NotoSansKR',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton(
              onPressed: canAnalyze ? () {
                // TODO: 분석 결과 화면으로 이동
              } : null,
              style: ElevatedButton.styleFrom(
                primary: const Color(0xFF4A55E7),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                '결과확인',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'NotoSansKR',
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: '더보기',
          ),
        ],
      ),
    );
  }
}

class PosePainter extends CustomPainter {
  final Pose pose;

  PosePainter(this.pose);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.blue;

    for (final landmark in pose.landmarks.values) {
      canvas.drawCircle(
        Offset(landmark.x, landmark.y),
        4.0,
        paint,
      );
    }

    // 관절 연결선 그리기
    _drawLine(canvas, paint, pose.landmarks[PoseLandmarkType.leftShoulder],
        pose.landmarks[PoseLandmarkType.leftElbow]);
    _drawLine(canvas, paint, pose.landmarks[PoseLandmarkType.leftElbow],
        pose.landmarks[PoseLandmarkType.leftWrist]);
    _drawLine(canvas, paint, pose.landmarks[PoseLandmarkType.rightShoulder],
        pose.landmarks[PoseLandmarkType.rightElbow]);
    _drawLine(canvas, paint, pose.landmarks[PoseLandmarkType.rightElbow],
        pose.landmarks[PoseLandmarkType.rightWrist]);
    // 추가적인 연결선은 필요에 따라 구현
  }

  void _drawLine(Canvas canvas, Paint paint, PoseLandmark? start, PoseLandmark? end) {
    if (start == null || end == null) return;
    canvas.drawLine(
      Offset(start.x, start.y),
      Offset(end.x, end.y),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 