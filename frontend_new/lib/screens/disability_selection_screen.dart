import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'brain_disability_selection_screen.dart';
import 'developmental_disability_selection_screen.dart';
import 'other_disability_screen.dart';

enum DisabilityType {
  brain('뇌병변'),
  developmental('발달장애'),
  other('기타');

  final String label;
  const DisabilityType(this.label);
}

class DisabilitySelectionScreen extends StatefulWidget {
  final Map<String, dynamic>? signupData;
  
  const DisabilitySelectionScreen({
    Key? key,
    this.signupData,
  }) : super(key: key);

  @override
  State<DisabilitySelectionScreen> createState() => _DisabilitySelectionScreenState();
}

class _DisabilitySelectionScreenState extends State<DisabilitySelectionScreen> {
  String? _selectedDisabilityType;
  String? _selectedGmfcsLevel;
  String? _selectedDevelopmentalType;
  bool _isLoading = false;

  final List<String> _disabilityTypes = [
    '뇌성마비',
    '척수장애',
    '근육병',
    '발달장애',
    '기타',
  ];

  final List<String> _gmfcsLevels = [
    'GMFCS I',
    'GMFCS II',
    'GMFCS III',
    'GMFCS IV',
    'GMFCS V',
  ];

  final List<String> _developmentalTypes = [
    '자폐성 장애',
    '지적 장애',
    '주의력결핍 과잉행동장애',
    '학습장애',
    '기타',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('장애 정보 입력'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '장애 유형을 선택해주세요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _disabilityTypes.map((type) {
                final isSelected = _selectedDisabilityType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedDisabilityType = selected ? type : null;
                      _selectedGmfcsLevel = null;
                      _selectedDevelopmentalType = null;
                    });
                  },
                );
              }).toList(),
            ),
            if (_selectedDisabilityType == '뇌성마비') ...[
              const SizedBox(height: 24),
              const Text(
                'GMFCS 레벨을 선택해주세요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _gmfcsLevels.map((level) {
                  final isSelected = _selectedGmfcsLevel == level;
                  return ChoiceChip(
                    label: Text(level),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedGmfcsLevel = selected ? level : null;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            if (_selectedDisabilityType == '발달장애') ...[
              const SizedBox(height: 24),
              const Text(
                '발달 장애 유형을 선택해주세요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _developmentalTypes.map((type) {
                  final isSelected = _selectedDevelopmentalType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedDevelopmentalType = selected ? type : null;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || !_isValidSelection
                    ? null
                    : _handleSubmit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('다음'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isValidSelection {
    if (_selectedDisabilityType == null) return false;
    if (_selectedDisabilityType == '뇌성마비' && _selectedGmfcsLevel == null) return false;
    if (_selectedDisabilityType == '발달장애' && _selectedDevelopmentalType == null) return false;
    return true;
  }

  Future<void> _handleSubmit() async {
    if (!_isValidSelection) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedDisabilityType == '기타') {
        if (mounted) {
          context.push('/other-disability');
        }
        return;
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updateDisabilityInfo(
        disabilityType: _selectedDisabilityType!,
        gmfcsLevel: _selectedGmfcsLevel,
        developmentalType: _selectedDevelopmentalType,
      );

      if (mounted) {
        context.go('/home');
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
} 