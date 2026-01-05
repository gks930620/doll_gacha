import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '계정 만들기',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '서비스 이용을 위해 정보를 입력해주세요.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildTextField(label: '아이디', icon: Icons.person),
            const SizedBox(height: 16),
            _buildTextField(label: '이메일', icon: Icons.email, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField(label: '비밀번호', icon: Icons.lock, isObscure: true),
            const SizedBox(height: 16),
            _buildTextField(label: '비밀번호 확인', icon: Icons.lock_outline, isObscure: true),
            const SizedBox(height: 16),
            _buildTextField(label: '닉네임', icon: Icons.face),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // 회원가입 로직
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('회원가입이 완료되었습니다.')),
                );
                Navigator.pop(context); // 로그인 화면으로 돌아가기
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('가입하기', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool isObscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      obscureText: isObscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(icon),
      ),
    );
  }
}

