import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DisabilitySelectionScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DisabilitySelectionScreen({
    super.key,
    required this.userData,
  });

  @override
  State<DisabilitySelectionScreen> createState() => _DisabilitySelectionScreenState();
}

class _DisabilitySelectionScreenState extends State<DisabilitySelectionScreen> {
  bool? _hasDisability;
  bool _isNextButtonEnabled = false;

  void _updateNextButtonState() {
    setState(() {
      _isNextButtonEnabled = _hasDisability != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('세부 정보 입력'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '장애 여부를 선택해주세요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              RadioListTile<bool>(
                title: const Text('장애'),
                value: true,
                groupValue: _hasDisability,
                onChanged: (value) {
                  setState(() {
                    _hasDisability = value;
                    _updateNextButtonState();
                  });
                },
              ),
              RadioListTile<bool>(
                title: const Text('비장애'),
                value: false,
                groupValue: _hasDisability,
                onChanged: (value) {
                  setState(() {
                    _hasDisability = value;
                    _updateNextButtonState();
                  });
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isNextButtonEnabled
                    ? () {
                        if (_hasDisability == true) {
                          // 장애 선택 시 장애 유형 선택 화면으로 이동
                          context.push('/disability-type', extra: widget.userData);
                        } else {
                          // 비장애 선택 시 회원가입 완료
                          final Map<String, dynamic> updatedUserData = Map.from(widget.userData);
                          updatedUserData['disability'] = {
                            'type': 'none',
                            'developmentalType': null,
                            'gmfcsLevel': null,
                            'otherDisabilityName': null,
                          };
                          context.push('/auth/register-complete', extra: updatedUserData);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(_hasDisability == true ? '다음' : '저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 