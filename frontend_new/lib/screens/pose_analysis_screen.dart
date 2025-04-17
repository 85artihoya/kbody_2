import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

enum PoseType { front, side, back }

class PoseAnalysisScreen extends StatefulWidget {
  const PoseAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<PoseAnalysisScreen> createState() => _PoseAnalysisScreenState();
}

class _PoseAnalysisScreenState extends State<PoseAnalysisScreen> {
  final _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.single,
    ),
  );
  File? _image;
  String _analysisResult = '';
  List<Pose> _poses = [];
  bool _isAnalyzing = false;
  List<String> _feedback = [];
  List<Map<String, dynamic>> _analysisHistory = [];
  bool _showHistory = false;
  bool _isLoading = false;
  String? _errorMessage;
  PoseType? _selectedPoseType;

  @override
  void initState() {
    super.initState();
    _loadAnalysisHistory();
  }

  Future<void> _loadAnalysisHistory() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('pose_analysis_history');
      if (historyJson != null) {
        setState(() {
          _analysisHistory = List<Map<String, dynamic>>.from(
            json.decode(historyJson),
          );
        });
      }
    } catch (e) {
      setState(() => _errorMessage = '분석 이력을 불러오는데 실패했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAnalysisHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'pose_analysis_history',
        json.encode(_analysisHistory),
      );
    } catch (e) {
      setState(() => _errorMessage = '분석 결과를 저장하는데 실패했습니다.');
    }
  }

  Future<bool> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final storageStatus = await Permission.storage.status;
    
    if (!cameraStatus.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        setState(() => _errorMessage = '카메라 권한이 필요합니다.');
        return false;
      }
    }
    
    if (!storageStatus.isGranted) {
      final result = await Permission.storage.request();
      if (!result.isGranted) {
        setState(() => _errorMessage = '저장소 권한이 필요합니다.');
        return false;
      }
    }
    
    return true;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!await _checkPermissions()) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile == null) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _image = File(pickedFile.path);
        _analysisResult = '';
        _poses = [];
        _feedback = [];
        _showHistory = false;
      });

      await _analyzeImage(_image!);
    } catch (e) {
      setState(() {
        _errorMessage = '이미지 선택에 실패했습니다.';
        _isLoading = false;
      });
    }
  }

  Future<void> _analyzeImage(File image) async {
    setState(() {
      _isAnalyzing = true;
      _analysisResult = '자세 분석 중...';
    });

    try {
      final inputImage = InputImage.fromFile(image);
      final poses = await _poseDetector.processImage(inputImage);
      
      if (mounted) {
        setState(() {
          _poses = poses;
          _analyzePose(poses);
          _isAnalyzing = false;
          _isLoading = false;
        });

        // 분석 결과 저장
        final analysisResult = {
          'timestamp': DateTime.now().toIso8601String(),
          'imagePath': image.path,
          'feedback': _feedback,
          'result': _analysisResult,
        };
        _analysisHistory.insert(0, analysisResult);
        await _saveAnalysisHistory();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '자세 분석에 실패했습니다.';
        _isAnalyzing = false;
        _isLoading = false;
      });
    }
  }

  void _analyzePose(List<Pose> poses) {
    if (poses.isEmpty) {
      setState(() {
        _analysisResult = '사람이 감지되지 않았습니다.';
      });
      return;
    }

    final pose = poses.first;
    final landmarks = pose.landmarks;

    // 주요 관절 위치 확인
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];
    final leftEye = landmarks[PoseLandmarkType.leftEye];
    final rightEye = landmarks[PoseLandmarkType.rightEye];
    final nose = landmarks[PoseLandmarkType.nose];

    if (leftShoulder == null || rightShoulder == null || 
        leftHip == null || rightHip == null ||
        leftKnee == null || rightKnee == null ||
        leftAnkle == null || rightAnkle == null) {
      setState(() {
        _analysisResult = '몸의 주요 관절이 감지되지 않았습니다.';
      });
      return;
    }

    // 자세 분석 결과
    final feedback = <String>[];
    final scores = <String, double>{};
    
    // 머리 위치 분석
    if (nose != null && leftEye != null && rightEye != null) {
      final headTilt = _calculateHeadTilt(
        Offset(leftEye.x, leftEye.y),
        Offset(rightEye.x, rightEye.y),
        Offset(nose.x, nose.y)
      );
      scores['head_tilt'] = headTilt;
      if (headTilt > 10) {
        feedback.add('머리가 ${headTilt.toStringAsFixed(1)}도 기울어져 있습니다.');
      }
    }

    // 어깨 수평 분석
    final shoulderAngle = (rightShoulder.y - leftShoulder.y).abs();
    scores['shoulder_angle'] = shoulderAngle;
    if (shoulderAngle > 10) {
      feedback.add('어깨가 ${shoulderAngle.toStringAsFixed(1)}도 기울어져 있습니다.');
    }

    // 엉덩이 수평 분석
    final hipAngle = (rightHip.y - leftHip.y).abs();
    scores['hip_angle'] = hipAngle;
    if (hipAngle > 10) {
      feedback.add('엉덩이가 ${hipAngle.toStringAsFixed(1)}도 기울어져 있습니다. 엉덩이를 수평으로 맞춰주세요.');
    }

    // 무릎 정렬 분석
    final kneeAlignment = (rightKnee.x - leftKnee.x).abs();
    scores['knee_alignment'] = kneeAlignment;
    if (kneeAlignment > 20) {
      feedback.add('무릎이 ${kneeAlignment.toStringAsFixed(1)}도 벌어져 있습니다. 무릎을 정렬해주세요.');
    }

    // 발 정렬 분석
    final ankleAlignment = (rightAnkle.x - leftAnkle.x).abs();
    scores['ankle_alignment'] = ankleAlignment;
    if (ankleAlignment > 20) {
      feedback.add('발이 ${ankleAlignment.toStringAsFixed(1)}도 벌어져 있습니다. 발을 정렬해주세요.');
    }

    // 팔꿈치 각도 분석
    if (leftElbow != null && rightElbow != null) {
      final leftElbowAngle = _calculateAngle(
        Offset(leftShoulder.x, leftShoulder.y),
        Offset(leftElbow.x, leftElbow.y),
        leftWrist != null ? Offset(leftWrist.x, leftWrist.y) : null
      );
      final rightElbowAngle = _calculateAngle(
        Offset(rightShoulder.x, rightShoulder.y),
        Offset(rightElbow.x, rightElbow.y),
        rightWrist != null ? Offset(rightWrist.x, rightWrist.y) : null
      );
      
      scores['left_elbow_angle'] = leftElbowAngle;
      scores['right_elbow_angle'] = rightElbowAngle;
      
      if (leftElbowAngle < 90 || rightElbowAngle < 90) {
        feedback.add('팔꿈치가 ${min(leftElbowAngle, rightElbowAngle).toStringAsFixed(1)}도로 너무 구부러져 있습니다. 팔을 더 펴주세요.');
      }
    }

    // 척추 정렬 분석
    if (leftShoulder != null && rightShoulder != null && 
        leftHip != null && rightHip != null) {
      final spineAlignment = _calculateSpineAlignment(
        Offset(leftShoulder.x, leftShoulder.y),
        Offset(rightShoulder.x, rightShoulder.y),
        Offset(leftHip.x, leftHip.y),
        Offset(rightHip.x, rightHip.y),
      );
      scores['spine_alignment'] = spineAlignment;
      if (spineAlignment > 15) {
        feedback.add('척추가 ${spineAlignment.toStringAsFixed(1)}도 기울어져 있습니다. 허리를 곧게 펴주세요.');
      }
    }

    // 전반적인 자세 점수 계산
    final overallScore = _calculateOverallScore(scores);
    final scoreFeedback = _getScoreFeedback(overallScore);

    setState(() {
      _feedback = feedback;
      if (feedback.isEmpty) {
        _analysisResult = '자세가 매우 좋습니다! (점수: ${overallScore.toStringAsFixed(1)}/100)\n$scoreFeedback';
      } else {
        _analysisResult = '자세 분석 결과 (점수: ${overallScore.toStringAsFixed(1)}/100)\n$scoreFeedback\n\n개선이 필요한 부분:\n${feedback.join('\n')}';
      }
    });
  }

  double _calculateHeadTilt(Offset leftEye, Offset rightEye, Offset nose) {
    final eyeLine = Point(rightEye.dx - leftEye.dx, rightEye.dy - leftEye.dy);
    final verticalLine = Point(0, 1);
    final dot = eyeLine.x * verticalLine.x + eyeLine.y * verticalLine.y;
    final det = eyeLine.x * verticalLine.y - eyeLine.y * verticalLine.x;
    return (atan2(det, dot) * 180 / pi).abs();
  }

  double _calculateSpineAlignment(Offset leftShoulder, Offset rightShoulder, Offset leftHip, Offset rightHip) {
    final shoulderCenter = Point(
      (leftShoulder.dx + rightShoulder.dx) / 2,
      (leftShoulder.dy + rightShoulder.dy) / 2,
    );
    final hipCenter = Point(
      (leftHip.dx + rightHip.dx) / 2,
      (leftHip.dy + rightHip.dy) / 2,
    );
    final spineLine = Point(hipCenter.x - shoulderCenter.x, hipCenter.y - shoulderCenter.y);
    final verticalLine = Point(0, 1);
    final dot = spineLine.x * verticalLine.x + spineLine.y * verticalLine.y;
    final det = spineLine.x * verticalLine.y - spineLine.y * verticalLine.x;
    return (atan2(det, dot) * 180 / pi).abs();
  }

  double _calculateAngle(Offset p1, Offset p2, Offset? p3) {
    if (p3 == null) return 0;
    final v1 = Point(p1.dx - p2.dx, p1.dy - p2.dy);
    final v2 = Point(p3.dx - p2.dx, p3.dy - p2.dy);
    final dot = v1.x * v2.x + v1.y * v2.y;
    final det = v1.x * v2.y - v1.y * v2.x;
    return (atan2(det, dot) * 180 / pi).abs();
  }

  double _calculateOverallScore(Map<String, double> scores) {
    double totalScore = 100.0;
    
    // 각 측정값에 대한 가중치 적용
    final weights = {
      'head_tilt': 0.15,
      'shoulder_angle': 0.2,
      'hip_angle': 0.2,
      'knee_alignment': 0.15,
      'ankle_alignment': 0.15,
      'spine_alignment': 0.15,
    };

    for (final entry in scores.entries) {
      if (weights.containsKey(entry.key)) {
        final weight = weights[entry.key]!;
        final value = entry.value;
        
        // 각 측정값에 대한 점수 감점 계산
        if (value > 0) {
          totalScore -= (value * weight);
        }
      }
    }

    return max(0, min(100, totalScore));
  }

  String _getScoreFeedback(double score) {
    if (score >= 90) {
      return '완벽한 자세입니다!';
    } else if (score >= 80) {
      return '좋은 자세입니다.';
    } else if (score >= 70) {
      return '보통 수준의 자세입니다.';
    } else if (score >= 60) {
      return '개선이 필요한 자세입니다.';
    } else {
      return '심각한 자세 문제가 있습니다. 전문가와 상담하시는 것을 추천드립니다.';
    }
  }

  Future<void> _saveAnalysisResult() async {
    if (_image == null || _feedback.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final pdf = pw.Document();
      final imageBytes = await _image!.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('자세 분석 결과', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Image(image, width: 300, height: 300),
              pw.SizedBox(height: 20),
              pw.Text('자세 분석 결과:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              for (final feedback in _feedback)
                pw.Text('- $feedback'),
              pw.SizedBox(height: 20),
              pw.Text('분석 시간: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}'),
            ],
          ),
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/pose_analysis.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: '자세 분석 결과');
    } catch (e) {
      setState(() => _errorMessage = 'PDF 생성에 실패했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAnalysisHistory() {
    setState(() => _showHistory = true);
  }

  @override
  void dispose() {
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('자세 분석'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _selectedPoseType == null
          ? _buildPoseTypeSelection()
          : _buildImageSelection(),
    );
  }

  Widget _buildPoseTypeSelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '분석할 자세를 선택해주세요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildPoseTypeButton(
            '정면 (FRONT)',
            PoseType.front,
            '사람의 정면 사진을 촬영합니다.',
          ),
          const SizedBox(height: 16),
          _buildPoseTypeButton(
            '측면 (SIDE)',
            PoseType.side,
            '사람의 옆면 사진을 촬영합니다.',
          ),
          const SizedBox(height: 16),
          _buildPoseTypeButton(
            '후면 (BACK)',
            PoseType.back,
            '사람의 뒷모습 사진을 촬영합니다.',
          ),
        ],
      ),
    );
  }

  Widget _buildPoseTypeButton(String title, PoseType type, String description) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedPoseType = type;
        });
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_selectedPoseType.toString().split('.').last.toUpperCase()} 자세 분석',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/camera', extra: {
                'poseType': _selectedPoseType,
              });
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('사진 촬영'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('갤러리에서 선택'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedPoseType = null;
              });
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('뒤로가기'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_image != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _image!,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (_poses.isNotEmpty)
                    CustomPaint(
                      size: Size(300, 300),
                      painter: PosePainter(
                        poses: _poses,
                        imageSize: Size(300, 300),
                        scores: _calculateScores(_poses.first),
                      ),
                    ),
                ],
              )
              else
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      '사진을 선택해주세요',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('카메라'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('갤러리'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_analysisResult.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '자세 분석 결과',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _analysisResult,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            if (_isAnalyzing)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '분석 이력',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _showHistory = false),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _analysisHistory.isEmpty
              ? const Center(
                  child: Text('분석 이력이 없습니다.'),
                )
              : ListView.builder(
                  itemCount: _analysisHistory.length,
                  itemBuilder: (context, index) {
                    final analysis = _analysisHistory[index];
                    final timestamp = DateTime.parse(analysis['timestamp']);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: Image.file(
                          File(analysis['imagePath']),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                        title: Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(timestamp),
                        ),
                        subtitle: Text(
                          analysis['result'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          setState(() {
                            _image = File(analysis['imagePath']);
                            _analysisResult = analysis['result'];
                            _feedback = List<String>.from(analysis['feedback']);
                            _showHistory = false;
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Map<String, double> _calculateScores(Pose pose) {
    final landmarks = pose.landmarks;
    final scores = <String, double>{};

    // 머리 기울기
    final leftEye = landmarks[PoseLandmarkType.leftEye];
    final rightEye = landmarks[PoseLandmarkType.rightEye];
    final nose = landmarks[PoseLandmarkType.nose];
    if (leftEye != null && rightEye != null && nose != null) {
      scores['head_tilt'] = _calculateHeadTilt(
        Offset(leftEye.x, leftEye.y),
        Offset(rightEye.x, rightEye.y),
        Offset(nose.x, nose.y)
      );
    }

    // 어깨 기울기
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    if (leftShoulder != null && rightShoulder != null) {
      scores['shoulder_angle'] = (rightShoulder.y - leftShoulder.y).abs();
    }

    // 척추 정렬
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    if (leftShoulder != null && rightShoulder != null && 
        leftHip != null && rightHip != null) {
      scores['spine_alignment'] = _calculateSpineAlignment(
        Offset(leftShoulder.x, leftShoulder.y),
        Offset(rightShoulder.x, rightShoulder.y),
        Offset(leftHip.x, leftHip.y),
        Offset(rightHip.x, rightHip.y),
      );
    }

    // 무릎 정렬
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    if (leftKnee != null && rightKnee != null) {
      scores['knee_alignment'] = (rightKnee.x - leftKnee.x).abs();
    }

    return scores;
  }
}

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final Map<String, double>? scores;

  PosePainter({
    required this.poses,
    required this.imageSize,
    this.scores,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty) return;

    final pose = poses.first;
    final landmarks = pose.landmarks;

    // 관절 연결선 그리기
    _drawConnections(canvas, size, landmarks);
    
    // 관절 포인트 그리기
    _drawLandmarks(canvas, size, landmarks);
    
    // 문제가 있는 부분 강조 표시
    if (scores != null) {
      _highlightProblemAreas(canvas, size, landmarks, scores!);
    }
  }

  void _drawConnections(Canvas canvas, Size size, Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.blue.withOpacity(0.7);

    // 주요 관절 연결선
    final connections = [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    ];

    for (final connection in connections) {
      final start = landmarks[connection[0]];
      final end = landmarks[connection[1]];
      
      if (start != null && end != null) {
        canvas.drawLine(
          Offset(
            start.x * size.width / imageSize.width,
            start.y * size.height / imageSize.height,
          ),
          Offset(
            end.x * size.width / imageSize.width,
            end.y * size.height / imageSize.height,
          ),
          paint,
        );
      }
    }
  }

  void _drawLandmarks(Canvas canvas, Size size, Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.green;

    for (final landmark in landmarks.values) {
      canvas.drawCircle(
        Offset(
          landmark.x * size.width / imageSize.width,
          landmark.y * size.height / imageSize.height,
        ),
        5,
        paint,
      );
    }
  }

  void _highlightProblemAreas(
    Canvas canvas,
    Size size,
    Map<PoseLandmarkType, PoseLandmark> landmarks,
    Map<String, double> scores,
  ) {
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.red.withOpacity(0.7);

    // 문제가 있는 관절 강조 표시
    if (scores['head_tilt'] != null && scores['head_tilt']! > 10) {
      _drawHeadTiltIndicator(canvas, size, landmarks, highlightPaint);
    }

    if (scores['shoulder_angle'] != null && scores['shoulder_angle']! > 10) {
      _drawShoulderTiltIndicator(canvas, size, landmarks, highlightPaint);
    }

    if (scores['spine_alignment'] != null && scores['spine_alignment']! > 15) {
      _drawSpineAlignmentIndicator(canvas, size, landmarks, highlightPaint);
    }

    if (scores['knee_alignment'] != null && scores['knee_alignment']! > 20) {
      _drawKneeAlignmentIndicator(canvas, size, landmarks, highlightPaint);
    }
  }

  void _drawHeadTiltIndicator(
    Canvas canvas,
    Size size,
    Map<PoseLandmarkType, PoseLandmark> landmarks,
    Paint paint,
  ) {
    final leftEye = landmarks[PoseLandmarkType.leftEye];
    final rightEye = landmarks[PoseLandmarkType.rightEye];
    final nose = landmarks[PoseLandmarkType.nose];

    if (leftEye != null && rightEye != null && nose != null) {
      final eyeCenter = Offset(
        (leftEye.x + rightEye.x) / 2 * size.width / imageSize.width,
        (leftEye.y + rightEye.y) / 2 * size.height / imageSize.height,
      );

      final nosePoint = Offset(
        nose.x * size.width / imageSize.width,
        nose.y * size.height / imageSize.height,
      );

      canvas.drawLine(eyeCenter, nosePoint, paint);
    }
  }

  void _drawShoulderTiltIndicator(
    Canvas canvas,
    Size size,
    Map<PoseLandmarkType, PoseLandmark> landmarks,
    Paint paint,
  ) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];

    if (leftShoulder != null && rightShoulder != null) {
      final leftPoint = Offset(
        leftShoulder.x * size.width / imageSize.width,
        leftShoulder.y * size.height / imageSize.height,
      );

      final rightPoint = Offset(
        rightShoulder.x * size.width / imageSize.width,
        rightShoulder.y * size.height / imageSize.height,
      );

      canvas.drawLine(leftPoint, rightPoint, paint);
    }
  }

  void _drawSpineAlignmentIndicator(
    Canvas canvas,
    Size size,
    Map<PoseLandmarkType, PoseLandmark> landmarks,
    Paint paint,
  ) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder != null && rightShoulder != null && 
        leftHip != null && rightHip != null) {
      final shoulderCenter = Offset(
        (leftShoulder.x + rightShoulder.x) / 2 * size.width / imageSize.width,
        (leftShoulder.y + rightShoulder.y) / 2 * size.height / imageSize.height,
      );

      final hipCenter = Offset(
        (leftHip.x + rightHip.x) / 2 * size.width / imageSize.width,
        (leftHip.y + rightHip.y) / 2 * size.height / imageSize.height,
      );

      canvas.drawLine(shoulderCenter, hipCenter, paint);
    }
  }

  void _drawKneeAlignmentIndicator(
    Canvas canvas,
    Size size,
    Map<PoseLandmarkType, PoseLandmark> landmarks,
    Paint paint,
  ) {
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];

    if (leftKnee != null && rightKnee != null) {
      final leftPoint = Offset(
        leftKnee.x * size.width / imageSize.width,
        leftKnee.y * size.height / imageSize.height,
      );

      final rightPoint = Offset(
        rightKnee.x * size.width / imageSize.width,
        rightKnee.y * size.height / imageSize.height,
      );

      canvas.drawLine(leftPoint, rightPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 