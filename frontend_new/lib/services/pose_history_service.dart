import 'package:flutter/foundation.dart';
import 'package:shared_preferences.dart';
import 'dart:convert';
import '../models/pose_analysis_result.dart';
import 'dart:async';

class PoseHistoryService extends ChangeNotifier {
  static const String _storageKey = 'pose_history';
  final List<PoseAnalysisResult> _history = [];
  final SharedPreferences _prefs;

  PoseHistoryService(this._prefs) {
    _loadHistory();
  }

  List<PoseAnalysisResult> get history => List.unmodifiable(_history);

  Future<void> _loadHistory() async {
    try {
      final historyJson = _prefs.getString(_storageKey);
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        _history.clear();
        _history.addAll(
          decoded.map((item) => PoseAnalysisResult.fromJson(item)),
        );
        notifyListeners();
      }
    } catch (e) {
      print('히스토리 로드 중 오류 발생: $e');
    }
  }

  Future<void> saveResult(PoseAnalysisResult result) async {
    try {
      _history.insert(0, result);
      await _saveHistory();
      notifyListeners();
    } catch (e) {
      print('결과 저장 중 오류 발생: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final historyJson = json.encode(
        _history.map((result) => result.toJson()).toList(),
      );
      await _prefs.setString(_storageKey, historyJson);
    } catch (e) {
      print('히스토리 저장 중 오류 발생: $e');
    }
  }

  Future<void> deleteResult(String id) async {
    try {
      _history.removeWhere((result) => result.id == id);
      await _saveHistory();
      notifyListeners();
    } catch (e) {
      print('결과 삭제 중 오류 발생: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      _history.clear();
      await _prefs.remove(_storageKey);
      notifyListeners();
    } catch (e) {
      print('히스토리 초기화 중 오류 발생: $e');
    }
  }

  List<PoseAnalysisResult> getResultsByPoseType(PoseType type) {
    return _history.where((result) => result.poseType == type).toList();
  }

  List<PoseAnalysisResult> getResultsByDateRange(DateTime start, DateTime end) {
    return _history.where((result) => 
      result.timestamp.isAfter(start) && result.timestamp.isBefore(end)
    ).toList();
  }

  double getAverageScore() {
    if (_history.isEmpty) return 0;
    return _history.map((result) => result.score).reduce((a, b) => a + b) / _history.length;
  }

  double getAverageScoreByPoseType(PoseType type) {
    final typeResults = getResultsByPoseType(type);
    if (typeResults.isEmpty) return 0;
    return typeResults.map((result) => result.score).reduce((a, b) => a + b) / typeResults.length;
  }
} 