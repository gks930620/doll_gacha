import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/constants.dart';
import 'oauth2_webview_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _authService.login(
      _usernameController.text,
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 실패. 아이디와 비밀번호를 확인해주세요.')),
        );
      }
    }
  }

  Future<void> _handleOAuth2Login(String provider) async {
    // Construct the URL based on provider
    // Assuming the pattern /custom-oauth2/login/app/{provider}
    final url = '${AppConstants.baseUrl}/custom-oauth2/login/app/$provider';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OAuth2WebViewScreen(loginUrl: url),
      ),
    );

    if (result == true) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final success = await _authService.loginWithGoogle();

      if (success) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google 로그인에 실패했습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleKakaoLogin() async {
    setState(() => _isLoading = true);

    try {
      final success = await _authService.loginWithKakao();

      if (success) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('카카오 로그인에 실패했습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Text(
              '다시 오신 것을 환영합니다!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // 일반 로그인 폼
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: '아이디',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('로그인', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('또는', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            // 소셜 로그인 버튼들
            _SocialLoginButton(
              text: '카카오로 시작하기',
              color: const Color(0xFFFEE500),
              textColor: Colors.black87,
              icon: Icons.chat_bubble, // 카카오 아이콘 대신 임시
              onPressed: _handleKakaoLogin,
            ),
            const SizedBox(height: 12),
            _SocialLoginButton(
              text: 'Google로 시작하기',
              color: Colors.white,
              textColor: Colors.black87,
              icon: Icons.g_mobiledata, // 구글 아이콘 대신 임시
              onPressed: _handleGoogleLogin,
              hasBorder: true,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('계정이 없으신가요?'),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text('회원가입'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final IconData icon;
  final VoidCallback onPressed;
  final bool hasBorder;

  const _SocialLoginButton({
    required this.text,
    required this.color,
    required this.textColor,
    required this.icon,
    required this.onPressed,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: textColor),
      label: Text(text, style: TextStyle(color: textColor, fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: hasBorder ? const BorderSide(color: Colors.grey) : BorderSide.none,
        ),
      ),
    );
  }
}

