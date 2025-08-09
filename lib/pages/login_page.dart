// pages/login_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../pages/main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _isSigningIn = false;

  Future<void> _onGoogleLoginPressed() async {
    if (_isSigningIn) return; // 중복 방지

    setState(() {
      _isSigningIn = true;
    });

    final user = await _authService.signInWithGoogle();

    setState(() {
      _isSigningIn = false;
    });

    if (user != null) {
      print('로그인 성공: ${user.displayName}');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인에 실패했거나 취소되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A6FB3),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/app_logo.png', height: 120),
            const SizedBox(height: 20),
            const Text(
              'SCalendar 로그인',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'SCalendar는 성신여대 전용 공지 달력 앱입니다.\n공지사항을 한눈에 확인하고, 신청 기간을 놓치지 마세요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSigningIn ? null : _onGoogleLoginPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6A6FB3),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSigningIn
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/google_logo.png', height: 24),
                        const SizedBox(width: 10),
                        const Text('Google로 로그인', style: TextStyle(fontSize: 16)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
