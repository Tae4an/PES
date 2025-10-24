import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'config/theme.dart';
import 'config/router_config.dart';
import 'config/env_config.dart';
import 'core/platform/google_maps_initializer.dart';
import 'core/notifications/notification_handler.dart';
import 'core/services/fcm_service.dart';
import 'core/network/dio_client.dart';
import 'core/utils/logger.dart';
import 'presentation/widgets/notification_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 변수 로드
  try {
    await dotenv.load(fileName: '.env');
    AppLogger.i('환경 변수 로드 완료');
    AppLogger.i('Google Maps API Key: ${EnvConfig.googleMapsApiKey.substring(0, 10)}...');
    
    // Google Maps 네이티브 초기화
    await GoogleMapsInitializer.initialize(EnvConfig.googleMapsApiKey);
  } catch (e) {
    AppLogger.e('환경 변수 로드 실패: $e');
  }

  // 화면 방향 고정 (세로 모드만)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase 초기화
  try {
    await Firebase.initializeApp();
    AppLogger.i('Firebase 초기화 완료');

    // Firebase Background 메시지 핸들러 설정
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    AppLogger.e('Firebase 초기화 실패: $e');
  }

  // Hive 초기화
  await Hive.initFlutter();
  AppLogger.i('Hive 초기화 완료');

  // 앱 실행
  runApp(
    const ProviderScope(
      child: PesApp(),
    ),
  );
}

/// PES 메인 앱
class PesApp extends ConsumerStatefulWidget {
  const PesApp({Key? key}) : super(key: key);

  @override
  ConsumerState<PesApp> createState() => _PesAppState();
}

class _PesAppState extends ConsumerState<PesApp> {
  final NotificationHandler _notificationHandler = NotificationHandler();
  late final FCMService _fcmService;

  @override
  void initState() {
    super.initState();
    _fcmService = FCMService(DioClient());
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 알림 초기화
    try {
      await _notificationHandler.initialize();
      AppLogger.i('알림 핸들러 초기화 완료');

      // FCM 토큰 가져오기 및 서버 전송
      final token = await _notificationHandler.getToken();
      if (token != null) {
        AppLogger.i('FCM 토큰: ${token.substring(0, 20)}...');
        
        // 서버에 토큰 전송
        try {
          final response = await _fcmService.registerCurrentDevice(token);
          AppLogger.i('FCM 토큰 서버 등록 성공: ${response.tokenId}');
        } catch (e) {
          AppLogger.e('FCM 토큰 서버 등록 실패: $e');
          // 토큰 등록 실패해도 앱은 계속 실행
        }
      }
    } catch (e) {
      AppLogger.e('알림 초기화 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PES - Personal Emergency Siren',
      debugShowCheckedModeBanner: false,

      // 테마 설정
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // 라우팅 설정
      routerConfig: AppRouter.router,

      // 로케일 설정
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 빌더 (전역 설정)
      builder: (context, child) {
        return NotificationOverlay(
          key: NotificationService.key,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0, // 텍스트 크기 고정
            ),
            child: child!,
          ),
        );
      },
    );
  }
}

