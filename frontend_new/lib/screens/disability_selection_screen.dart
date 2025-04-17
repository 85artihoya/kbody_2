import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class DisabilitySelectionScreen extends StatefulWidget {
  final Map<String, dynamic> registerData;

  const DisabilitySelectionScreen({
    Key? key,
    required this.registerData,
  }) : super(key: key);

  @override
  State<DisabilitySelectionScreen> createState() => _DisabilitySelectionScreenState();
}

class _DisabilitySelectionScreenState extends State<DisabilitySelectionScreen> {
  String? _selectedType;
  bool _isLoading = false;

  void _handleSelection(String type) async {
    setState(() {
      _selectedType = type;
    });
  }

  void _handleNext() async {
    if (_selectedType == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Selected type: $_selectedType');
      print('Register data before: ${widget.registerData}');
      
      final updatedData = Map<String, dynamic>.from(widget.registerData);
      updatedData['disability_type'] = _selectedType;
      
      print('Updated register data: $updatedData');

      switch (_selectedType) {
        case '뇌병변장애':
          context.go('/gmfcs-selection', extra: updatedData);
          break;
        case '발달장애':
          context.go('/developmental-type', extra: updatedData);
          break;
        case '기타장애':
          context.go('/other-disability', extra: updatedData);
          break;
        case '비장애':
          // 비장애인 경우 바로 회원가입 진행
          final authService = Provider.of<AuthService>(context, listen: false);
          await authService.register(updatedData);
          context.go('/register-complete');
          break;
      }
    } catch (e) {
      print('Error in _handleSelection: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장애 유형 선택 중 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('장애 유형 선택'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '장애 유형을 선택해주세요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildSelectionTile('뇌병변장애'),
                    _buildSelectionTile('발달장애'),
                    _buildSelectionTile('기타장애'),
                    _buildSelectionTile('비장애'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectedType == null || _isLoading ? null : _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A55E7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '다음',
                      style: TextStyle(fontSize: 16),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionTile(String type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => _handleSelection(type),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedType == type
                ? const Color(0xFF4A55E7)
                : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            type,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _selectedType == type
                ? const Color(0xFF4A55E7)
                : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
} 