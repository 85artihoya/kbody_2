import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DevelopmentalTypeScreen extends StatefulWidget {
  final Map<String, dynamic> registerData;
  
  const DevelopmentalTypeScreen({
    super.key,
    required this.registerData,
  });

  @override
  State<DevelopmentalTypeScreen> createState() => _DevelopmentalTypeScreenState();
}

class _DevelopmentalTypeScreenState extends State<DevelopmentalTypeScreen> {
  String? _selectedType;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('발달장애 유형 선택'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/disability-selection', extra: widget.registerData),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '발달장애 유형을 선택해주세요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildTypeButton('지적 장애', 'intellectual'),
              const SizedBox(height: 16),
              _buildTypeButton('자폐 장애', 'autism'),
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedType == null || _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        // 회원 정보에 발달장애 유형 추가
                        final registerData = Map<String, dynamic>.from(widget.registerData);
                        registerData['developmental_type'] = _selectedType == 'intellectual' ? '지적 장애' : '자폐 장애';
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