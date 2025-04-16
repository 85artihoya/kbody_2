import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DisabilitySelectionScreen extends StatefulWidget {
  const DisabilitySelectionScreen({super.key});

  @override
  State<DisabilitySelectionScreen> createState() => _DisabilitySelectionScreenState();
}

class _DisabilitySelectionScreenState extends State<DisabilitySelectionScreen> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('세부 정보 입력'),
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
                '정확한 측정을 위해 해당 정보를 체크해주세요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedType = 'disabled';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedType == 'disabled' 
                    ? const Color(0xFF4A55E7) 
                    : Colors.grey[300],
                  foregroundColor: _selectedType == 'disabled' 
                    ? Colors.white 
                    : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '장애',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedType = 'non-disabled';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedType == 'non-disabled' 
                    ? const Color(0xFF4A55E7) 
                    : Colors.grey[300],
                  foregroundColor: _selectedType == 'non-disabled' 
                    ? Colors.white 
                    : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '비장애',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedType == null 
                  ? null 
                  : () {
                      if (_selectedType == 'disabled') {
                        context.go('/disability-type');
                      } else {
                        // 비장애인 선택 시 바로 회원가입 완료 페이지로 이동
                        context.go('/register-complete');
                      }
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A55E7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text(
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
} 