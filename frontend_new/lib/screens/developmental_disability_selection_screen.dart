import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DevelopmentalDisabilitySelectionScreen extends StatefulWidget {
  final Map<String, dynamic> signupData;

  const DevelopmentalDisabilitySelectionScreen({
    super.key,
    required this.signupData,
  });

  @override
  State<DevelopmentalDisabilitySelectionScreen> createState() => _DevelopmentalDisabilitySelectionScreenState();
}

class _DevelopmentalDisabilitySelectionScreenState extends State<DevelopmentalDisabilitySelectionScreen> {
  String? _selectedType;
  bool _isLoading = false;

  Widget _buildTypeButton(String type, String label) {
    final isSelected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedType = type;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    type == 'intellectual' ? Icons.psychology : Icons.people_alt,
                    size: 32,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? Colors.white : Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('발달장애 유형을 선택해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 기존 회원가입 데이터 복사
      final Map<String, dynamic> updatedSignupData = Map.from(widget.signupData);
      
      // 장애 정보 추가
      updatedSignupData['disability'] = {
        'type': 'developmental',
        'developmentalType': _selectedType,
        'gmfcsLevel': null,
        'otherDisabilityName': null,
      };
      
      if (mounted) {
        context.push('/auth/register-complete', extra: updatedSignupData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('세부 정보 입력'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '장애인 복지법 상의 유형을\n선택해주세요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildTypeButton('intellectual', '지적 장애'),
                  _buildTypeButton('autism', '자폐 장애'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _selectedType != null && !_isLoading ? _handleSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedType != null ? Colors.blue : Colors.grey[300],
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        '저장',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedType != null ? Colors.white : Colors.grey[600],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 