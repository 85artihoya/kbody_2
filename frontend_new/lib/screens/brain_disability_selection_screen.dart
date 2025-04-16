import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class BrainDisabilitySelectionScreen extends StatefulWidget {
  final Map<String, dynamic> signupData;

  const BrainDisabilitySelectionScreen({
    super.key,
    required this.signupData,
  });

  @override
  State<BrainDisabilitySelectionScreen> createState() => _BrainDisabilitySelectionScreenState();
}

class _BrainDisabilitySelectionScreenState extends State<BrainDisabilitySelectionScreen> {
  int? _selectedLevel;
  bool _isLoading = false;

  Widget _buildGMFCSCard(int level) {
    final isSelected = _selectedLevel == level;
    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? Colors.blue : Colors.grey[200],
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLevel = level;
          });
        },
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 2,
              child: Image.asset(
                'assets/images/drawable-xxxhdpi/GMFCS_$level.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                        Text(
                          'GMFCS - $level',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: isSelected ? Colors.blue : Colors.grey[300],
              child: Text(
                'GMFCS - $level',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GMFCS 단계를 선택해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> updatedSignupData = Map.from(widget.signupData);
      updatedSignupData['disability'] = {
        'type': 'brain',
        'gmfcsLevel': _selectedLevel.toString(),
        'developmentalType': null,
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
        title: const Text('뇌병변 분류 선택'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (int i = 1; i <= 5; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildGMFCSCard(i),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _selectedLevel != null && !_isLoading ? _handleSubmit : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '저장',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
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