import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../models/pose_analysis_result.dart';

class DataExportService {
  static Future<String> exportData(List<PoseAnalysisResult> results) async {
    try {
      final data = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'results': results.map((r) => r.toJson()).toList(),
      };

      final jsonString = jsonEncode(data);
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/pose_analysis_export_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('데이터 내보내기 중 오류가 발생했습니다: $e');
    }
  }

  static Future<List<PoseAnalysisResult>> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('파일을 선택하지 않았습니다');
      }

      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);

      if (data['version'] != '1.0') {
        throw Exception('지원하지 않는 파일 버전입니다');
      }

      return (data['results'] as List)
          .map((json) => PoseAnalysisResult.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('데이터 가져오기 중 오류가 발생했습니다: $e');
    }
  }

  static Future<void> shareExportFile(String filePath) async {
    try {
      await Share.shareFiles(
        [filePath],
        text: '자세 분석 기록 내보내기',
      );
    } catch (e) {
      throw Exception('파일 공유 중 오류가 발생했습니다: $e');
    }
  }
} 