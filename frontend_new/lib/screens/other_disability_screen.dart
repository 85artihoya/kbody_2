import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OtherDisabilityScreen extends StatefulWidget {
  final Map<String, dynamic> registerData;
  
  const OtherDisabilityScreen({
    super.key,
    required this.registerData,
  });

  @override
  State<OtherDisabilityScreen> createState() => _OtherDisabilityScreenState();
}

class _OtherDisabilityScreenState extends State<OtherDisabilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _disabilityController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _disabilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기타 장애 입력'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/disability-selection', extra: widget.registerData),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '장애 진단명을 입력해주세요',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _disabilityController,
                  decoration: const InputDecoration(
                    labelText: '장애 진단명',
                    hintText: '장애 진단명을 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '장애 진단명을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          // 회원 정보에 기타 장애 정보 추가
                          final registerData = Map<String, dynamic>.from(widget.registerData);
                          registerData['disability_type'] = '기타';
                          registerData['other_disability_name'] = _disabilityController.text;
                          registerData['user_type'] = 'disabled';
                          
                          print('Final registration data: $registerData');

                          // 회원가입 수행
                          await context.read<AuthProvider>().register(registerData);

                          if (mounted) {
                            context.go('/register-complete');
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
                        '저장',
                        style: TextStyle(fontSize: 16),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 