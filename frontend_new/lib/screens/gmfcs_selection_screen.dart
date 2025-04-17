import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class GmfcsSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> registerData;
  
  const GmfcsSelectionScreen({
    super.key,
    required this.registerData,
  });

  @override
  State<GmfcsSelectionScreen> createState() => _GmfcsSelectionScreenState();
}

class _GmfcsSelectionScreenState extends State<GmfcsSelectionScreen> {
  String? _selectedLevel;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GMFCS 레벨 선택'),
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
                'GMFCS 레벨을 선택해주세요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    final level = index + 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedLevel = 'GMFCS-$level';
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _selectedLevel == 'GMFCS-$level'
                                ? const Color(0xFF4A55E7)
                                : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/drawable-xxxhdpi/GMFCS_$level.png',
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'GMFCS-$level',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedLevel == 'GMFCS-$level'
                                      ? const Color(0xFF4A55E7)
                                      : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _selectedLevel == null || _isLoading
                  ? null
                  : () async {
                      await _handleSave();
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
    );
  }

  Future<void> _handleSave() async {
    if (_selectedLevel == null || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 회원 정보에 GMFCS 레벨 추가
      final registerData = Map<String, dynamic>.from(widget.registerData);
      
      print('Original registerData: $registerData'); // 원본 데이터 로깅
      
      // GMFCS 레벨 설정
      registerData['gmfcs_level'] = _selectedLevel!.trim();
      registerData['user_type'] = 'disabled';
      registerData['disability_type'] = '뇌병변장애';
      
      print('Modified registerData: $registerData'); // 수정된 데이터 로깅

      // 회원가입 수행
      await context.read<AuthProvider>().register(registerData);

      if (mounted) {
        context.go('/register-complete');
      }
    } catch (e) {
      print('Registration error: $e'); // 에러 로깅
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 