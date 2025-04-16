import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DisabilityTypeScreen extends StatefulWidget {
  const DisabilityTypeScreen({super.key});

  @override
  State<DisabilityTypeScreen> createState() => _DisabilityTypeScreenState();
}

class _DisabilityTypeScreenState extends State<DisabilityTypeScreen> {
  String? _selectedType;

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
                '해당하는 장애 유형을 선택해주세요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildTypeButton('뇌병변', 'brain'),
              const SizedBox(height: 16),
              _buildTypeButton('발달장애', 'developmental'),
              const SizedBox(height: 16),
              _buildTypeButton('기타', 'other'),
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedType == null 
                  ? null 
                  : () {
                      switch (_selectedType) {
                        case 'brain':
                          context.go('/gmfcs-selection');
                          break;
                        case 'developmental':
                          context.go('/developmental-type');
                          break;
                        case 'other':
                          context.go('/other-disability');
                          break;
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

  Widget _buildTypeButton(String label, String value) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedType = value;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedType == value 
          ? const Color(0xFF4A55E7) 
          : Colors.grey[300],
        foregroundColor: _selectedType == value 
          ? Colors.white 
          : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
} 