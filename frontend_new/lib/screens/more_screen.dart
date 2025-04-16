import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/profile_screen.dart';
import '../screens/password_change_screen.dart';
import '../screens/logout_screen.dart';
import '../screens/customer_center_screen.dart';
import '../screens/terms_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '더보기',
          style: TextStyle(fontFamily: 'NotoSansKR'),
        ),
        backgroundColor: const Color(0xFF4A55E7),
      ),
      body: ListView(
        children: [
          // 정보 섹션
          const _SectionHeader(title: '정보'),
          _MenuItem(
            title: '내정보',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
            showDivider: true,
          ),
          _MenuItem(
            title: '버전정보',
            trailing: const Text(
              'Ver 1.0',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'NotoSansKR',
              ),
            ),
            onTap: () {},
          ),

          // 사용자 설정 섹션
          const _SectionHeader(title: '사용자 설정'),
          _MenuItem(
            title: '알림 설정',
            onTap: () {},
            showDivider: true,
          ),
          _MenuItem(
            title: '비밀번호 변경',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PasswordChangeScreen()),
            ),
            showDivider: true,
          ),
          _MenuItem(
            title: '로그아웃',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LogoutScreen()),
            ),
          ),

          // 기타 섹션
          const _SectionHeader(title: '기타'),
          _MenuItem(
            title: '고객센터',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CustomerCenterScreen()),
            ),
            showDivider: true,
          ),
          _MenuItem(
            title: '약관 및 정책',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TermsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      color: Colors.grey[100],
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontFamily: 'NotoSansKR',
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool showDivider;

  const _MenuItem({
    Key? key,
    required this.title,
    this.trailing,
    required this.onTap,
    this.showDivider = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'NotoSansKR',
            ),
          ),
          trailing: trailing ?? const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(height: 1),
      ],
    );
  }
} 