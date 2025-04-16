import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DisabilityTypeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DisabilityTypeScreen({
    super.key,
    required this.userData,
  });

  @override
  State<DisabilityTypeScreen> createState() => _DisabilityTypeScreenState();
}

class _DisabilityTypeScreenState extends State<DisabilityTypeScreen> {
  String? _selectedType;
  bool _isNextButtonEnabled = false;

  void _updateNextButtonState() {
    setState(() {
      _isNextButtonEnabled = _selectedType != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('장애 유형 선택'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '장애 유형을 선택해주세요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              RadioListTile<String>(
                title: const Text('뇌병변'),
                value: 'brain',
                groupValue: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                    _updateNextButtonState();
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('발달장애'),
                value: 'developmental',
                groupValue: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                    _updateNextButtonState();
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('기타'),
                value: 'other',
                groupValue: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                    _updateNextButtonState();
                  });
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isNextButtonEnabled
                    ? () {
                        widget.userData['disabilityType'] = _selectedType;
                        switch (_selectedType) {
                          case 'brain':
                            context.push('/brain-disability', extra: widget.userData);
                            break;
                          case 'developmental':
                            context.push('/developmental-disability', extra: widget.userData);
                            break;
                          case 'other':
                            context.push('/other-disability', extra: widget.userData);
                            break;
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('다음'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 