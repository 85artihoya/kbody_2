import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerCenterScreen extends StatelessWidget {
  const CustomerCenterScreen({super.key});

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw '전화를 걸 수 없습니다: $phoneNumber';
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'info@k-body.com',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw '이메일을 보낼 수 없습니다';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('고객센터', 
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _InfoSection(
            title: '회사명',
            content: 'K운동발달연구원(주)',
            onTap: null,
          ),
          _InfoSection(
            title: '대표자',
            content: '김성경',
            onTap: null,
          ),
          _InfoSection(
            title: '주소',
            content: '경북 포항시 북구 법원로 97번길 24-9',
            onTap: null,
          ),
          _InfoSection(
            title: '웹사이트',
            content: 'k운동발달연구원.com',
            onTap: () {}, // TODO: 웹사이트 URL 추가
          ),
          _InfoSection(
            title: '연락처',
            content: 'T. 054-246-8897 / M. 010-4530-8897',
            onTap: () => _launchPhone('010-4530-8897'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _launchEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '문의하기',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onTap;

  const _InfoSection({
    required this.title,
    required this.content,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: onTap,
            child: Text(
              content,
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 16,
                color: onTap != null ? Theme.of(context).primaryColor : Colors.black,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 