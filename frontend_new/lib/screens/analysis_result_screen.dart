import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/pose_analysis_result.dart';
import '../services/pose_evaluation_service.dart';

class AnalysisResultScreen extends StatefulWidget {
  final Map<String, File> images;
  final PoseAnalysisResult result;

  const AnalysisResultScreen({
    Key? key,
    required this.images,
    required this.result,
  }) : super(key: key);

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  bool _isSaving = false;

  Widget _buildImageWithMarkers(String viewType, File image) {
    final angles = widget.result.angles[viewType] ?? {};
    
    return Stack(
      children: [
        Image.file(
          image,
          height: 300,
          fit: BoxFit.contain,
        ),
        ...angles.entries.map((entry) {
          return Positioned(
            left: entry.value['x'],
            top: entry.value['y'],
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${entry.key}: ${entry.value['angle'].toStringAsFixed(1)}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'NotoSansKR',
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildScoreCard(String title, double score) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansKR',
              ),
            ),
            const SizedBox(height: 8),
            CircularProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                score > 80 ? Colors.green : (score > 60 ? Colors.orange : Colors.red),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${score.toStringAsFixed(1)}점',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansKR',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndSavePDF() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('자세 분석 결과 보고서'),
                ),
                pw.Paragraph(
                  text: '분석 일시: ${widget.result.timestamp}',
                ),
                // TODO: Add more PDF content
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/pose_analysis_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareFiles([file.path], text: '자세 분석 결과 보고서');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF 생성 중 오류가 발생했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _saveResults() async {
    try {
      // TODO: Save results to backend
      await _generateAndSavePDF();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('분석 결과가 저장되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장 중 오류가 발생했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '분석 결과',
          style: TextStyle(fontFamily: 'NotoSansKR'),
        ),
        backgroundColor: const Color(0xFF4A55E7),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '자세 분석 결과',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansKR',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildScoreCard('자세 점수', widget.result.score),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildScoreCard('대칭성', widget.result.symmetryScores['overall'] ?? 0),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '촬영 결과',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansKR',
              ),
            ),
            const SizedBox(height: 16),
            _buildImageWithMarkers('FRONT', widget.images['FRONT']!),
            const SizedBox(height: 16),
            _buildImageWithMarkers('SIDE', widget.images['SIDE']!),
            const SizedBox(height: 16),
            _buildImageWithMarkers('BACK', widget.images['BACK']!),
            const SizedBox(height: 24),
            const Text(
              '피드백',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansKR',
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.result.feedback,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'NotoSansKR',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveResults,
              style: ElevatedButton.styleFrom(
                primary: const Color(0xFF4A55E7),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      '결과 저장하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'NotoSansKR',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 