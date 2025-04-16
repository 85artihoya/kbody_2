import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'dart:convert';

class RegisterCompleteScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const RegisterCompleteScreen({
    super.key,
    required this.userData,
  });

  @override
  State<RegisterCompleteScreen> createState() => _RegisterCompleteScreenState();
}

class _RegisterCompleteScreenState extends State<RegisterCompleteScreen> {
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting registration process...');
      print('User data: ${jsonEncode(widget.userData)}');

      // 회원가입 시도
      await context.read<AuthProvider>().register(widget.userData);
      
      if (!mounted) return;

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원가입이 완료되었습니다. 로그인해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // 잠시 대기 후 로그인 화면으로 이동
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      context.go('/login');
    } catch (e) {
      print('Registration error: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isRegistering = _isLoading || authProvider.isLoading;

    return WillPopScope(
      onWillPop: () async => false,  // 뒤로가기 버튼 비활성화
      child: Scaffold(
        appBar: AppBar(
          title: const Text('회원가입 완료'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Icon(
                  Icons.check_circle_outline,
                  size: 100,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                const Text(
                  '회원가입이 완료되었습니다',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  '로그인 후 서비스를 이용해주세요',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: isRegistering ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: isRegistering
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '로그인 하기',
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