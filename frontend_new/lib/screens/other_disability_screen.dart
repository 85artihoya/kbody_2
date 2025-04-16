import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class OtherDisabilityScreen extends StatefulWidget {
  final Map<String, dynamic> signupData;

  const OtherDisabilityScreen({
    super.key,
    required this.signupData,
  });

  @override
  State<OtherDisabilityScreen> createState() => _OtherDisabilityScreenState();
}

class _OtherDisabilityScreenState extends State<OtherDisabilityScreen> {
  final _diagnosisController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _diagnosisController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_diagnosisController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('진단명을 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> updatedSignupData = Map.from(widget.signupData);
      updatedSignupData['disability'] = {
        'type': 'other',
        'otherDisabilityName': _diagnosisController.text,
        'gmfcsLevel': null,
        'developmentalType': null,
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
        title: const Text('기타 장애 진단명 입력'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '진단명을 입력해주세요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _diagnosisController,
              decoration: const InputDecoration(
                labelText: '진단명',
                border: OutlineInputBorder(),
                hintText: '예) 뇌졸중, 척수손상 등',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 