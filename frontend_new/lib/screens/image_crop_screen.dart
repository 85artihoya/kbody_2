import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../screens/pose_analysis_screen.dart';

class ImageCropScreen extends StatefulWidget {
  final String imagePath;
  final PoseType poseType;

  const ImageCropScreen({
    Key? key,
    required this.imagePath,
    required this.poseType,
  }) : super(key: key);

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  File? _croppedFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cropImage();
  }

  Future<void> _cropImage() async {
    setState(() => _isLoading = true);

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: widget.imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1.5),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '이미지 크롭',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: '이미지 크롭',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _croppedFile = File(croppedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 크롭 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _retryCrop() {
    _cropImage();
  }

  void _proceedToAnalysis() {
    if (_croppedFile != null) {
      context.push('/analysis', extra: {
        'imagePath': _croppedFile!.path,
        'poseType': widget.poseType,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이미지 크롭'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _croppedFile == null
              ? _buildErrorView()
              : _buildPreviewView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            '이미지 크롭에 실패했습니다.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _retryCrop,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewView() {
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            child: Image.file(
              _croppedFile!,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _retryCrop,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 크롭'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _proceedToAnalysis,
                icon: const Icon(Icons.check),
                label: const Text('분석 진행'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 