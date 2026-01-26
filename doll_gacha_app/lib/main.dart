import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/shop_list_screen.dart';
import 'screens/shop_detail_screen.dart';
import 'screens/review_write_screen.dart';
import 'screens/community_list_screen.dart';
import 'screens/community_detail_screen.dart';
import 'screens/community_write_screen.dart';
import 'models/community_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드
  await dotenv.load(fileName: ".env");

  // 카카오맵 SDK 초기화
  AuthRepository.initialize(
    appKey: dotenv.env['KAKAO_MAP_JAVASCRIPT_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doll Gacha',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case '/shops':
            return MaterialPageRoute(builder: (_) => const ShopListScreen());
          case '/shop-detail':
            final shopId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (_) => ShopDetailScreen(shopId: shopId),
            );
          case '/review-write':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => ReviewWriteScreen(
                shopId: args['shopId'],
                shopName: args['shopName'],
              ),
            );
          case '/community':
            return MaterialPageRoute(builder: (_) => const CommunityListScreen());
          case '/community-detail':
            final communityId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (_) => CommunityDetailScreen(communityId: communityId),
            );
          case '/community-write':
            final community = settings.arguments as Community?;
            return MaterialPageRoute(
              builder: (_) => CommunityWriteScreen(community: community),
            );
          default:
            return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
      },
    );
  }
}

