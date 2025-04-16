import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/pose_history_service.dart';
import '../models/pose_analysis_result.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/data_export_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedPeriod = '1개월';
  DateTime? _startDate;
  DateTime? _endDate;
  List<PoseAnalysisResult> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setDefaultPeriod();
    _loadResults();
  }

  void _setDefaultPeriod() {
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(const Duration(days: 30));
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load results from backend
      // _results = await PoseService.getResults(_startDate, _endDate);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기록을 불러오는 중 오류가 발생했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate!,
        end: _endDate!,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A55E7),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = '직접 선택';
      });
      _loadResults();
    }
  }

  void _onPeriodChanged(String? value) {
    if (value == null) return;

    final now = DateTime.now();
    setState(() {
      _selectedPeriod = value;
      _endDate = now;
      switch (value) {
        case '1개월':
          _startDate = now.subtract(const Duration(days: 30));
          break;
        case '3개월':
          _startDate = now.subtract(const Duration(days: 90));
          break;
        case '6개월':
          _startDate = now.subtract(const Duration(days: 180));
          break;
      }
    });
    _loadResults();
  }

  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final filePath = await DataExportService.exportData(_results);
      await DataExportService.shareExportFile(filePath);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('데이터를 내보냈습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final importedResults = await DataExportService.importData();
      setState(() {
        _results = importedResults;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${importedResults.length}개의 기록을 가져왔습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildResultCard(PoseAnalysisResult result) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => _showResultDetail(result),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('yyyy.MM.dd HH:mm').format(result.timestamp),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansKR',
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: result.score > 80
                              ? Colors.green
                              : (result.score > 60 ? Colors.orange : Colors.red),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${result.score.toStringAsFixed(1)}점',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NotoSansKR',
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          switch (value) {
                            case 'share':
                              _shareResult(result);
                              break;
                            case 'delete':
                              _showDeleteDialog(result);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share),
                                SizedBox(width: 8),
                                Text('공유하기'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('삭제하기', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                result.feedback,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'NotoSansKR',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareResult(PoseAnalysisResult result) async {
    try {
      final text = '''
자세 분석 결과 (${DateFormat('yyyy.MM.dd HH:mm').format(result.timestamp)})
점수: ${result.score.toStringAsFixed(1)}점
피드백: ${result.feedback}
''';
      await Share.share(text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('공유 중 오류가 발생했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteDialog(PoseAnalysisResult result) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '기록 삭제',
          style: TextStyle(fontFamily: 'NotoSansKR'),
        ),
        content: const Text(
          '이 분석 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.',
          style: TextStyle(fontFamily: 'NotoSansKR'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '취소',
              style: TextStyle(fontFamily: 'NotoSansKR'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(
              '삭제',
              style: TextStyle(fontFamily: 'NotoSansKR'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // TODO: Delete result from backend
        // await PoseService.deleteResult(result.id);
        _results.remove(result);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기록이 삭제되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('삭제 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showResultDetail(PoseAnalysisResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatisticsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '자세 분석 기록',
          style: TextStyle(fontFamily: 'NotoSansKR'),
        ),
        backgroundColor: const Color(0xFF4A55E7),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'export':
                  await _exportData();
                  break;
                case 'import':
                  await _importData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.upload),
                    SizedBox(width: 8),
                    Text('데이터 내보내기'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('데이터 가져오기'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: const InputDecoration(
                      labelText: '기간 선택',
                      border: OutlineInputBorder(),
                    ),
                    items: ['1개월', '3개월', '6개월', '직접 선택']
                        .map((period) => DropdownMenuItem(
                              value: period,
                              child: Text(
                                period,
                                style: const TextStyle(fontFamily: 'NotoSansKR'),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == '직접 선택') {
                        _selectDateRange();
                      } else {
                        _onPeriodChanged(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(
                        child: Text(
                          '분석 기록이 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'NotoSansKR',
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          return _buildResultCard(_results[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final PoseAnalysisResult result;

  const _HistoryItem({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            '${result.score.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          '${result.poseType.toString().split('.').last}',
          style: Theme.of(context).textTheme.headline6,
        ),
        subtitle: Text(
          '${result.timestamp.toString().split('.')[0]}',
          style: Theme.of(context).textTheme.caption,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _showDeleteDialog(context),
        ),
        onTap: () => _showResultDetail(context),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('이 분석 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<PoseHistoryService>().deleteResult(result.id);
    }
  }

  void _showResultDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ResultDetailSheet(result: result),
    );
  }
}

class _ResultDetailSheet extends StatelessWidget {
  final PoseAnalysisResult result;

  const _ResultDetailSheet({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  '분석 결과 상세',
                  style: Theme.of(context).textTheme.headline5,
                ),
                const SizedBox(height: 16),
                _buildScoreSection(),
                const SizedBox(height: 16),
                _buildAnglesSection(),
                const SizedBox(height: 16),
                _buildFeedbackSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '종합 점수: ${result.score.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: result.score / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                result.score >= 80
                    ? Colors.green
                    : result.score >= 60
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnglesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '관절 각도',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...result.angles.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text('${entry.value.toStringAsFixed(1)}°'),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '피드백',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(result.feedback),
          ],
        ),
      ),
    );
  }
} 