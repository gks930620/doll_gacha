import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/constants.dart';
import '../services/auth_service.dart';

class OAuth2WebViewScreen extends StatefulWidget {
  final String loginUrl;

  const OAuth2WebViewScreen({super.key, required this.loginUrl});

  @override
  State<OAuth2WebViewScreen> createState() => _OAuth2WebViewScreenState();
}

class _OAuth2WebViewScreenState extends State<OAuth2WebViewScreen> {
  late final WebViewController _controller;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            debugPrint('WebView Navigation: ${request.url}'); // 디버깅용 로그

            // ✅ 서버에서 리다이렉트한 성공 URL 감지 (http://localhost:8080/login/success...)
            if (request.url.contains('/login/success')) {
              debugPrint('Login success URL detected');
              final uri = Uri.parse(request.url);
              final accessToken = uri.queryParameters['access_token'];
              final refreshToken = uri.queryParameters['refresh_token'];

              if (accessToken != null) {
                debugPrint('Token found, saving and closing...');
                // await를 사용하여 저장이 완료될 때까지 대기
                await _authService.saveToken(accessToken, refreshToken: refreshToken);
                if (mounted) {
                  Navigator.pop(context, true); // 성공 반환 및 창 닫기
                }
              } else {
                debugPrint('Token not found in URL');
              }
              // 해당 페이지로 이동하지 않음 (흰 화면 방지)
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.loginUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Login'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

