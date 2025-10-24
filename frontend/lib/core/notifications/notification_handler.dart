import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// FCM 알림 핸들러 (로컬 알림 임시 비활성화)
class NotificationHandler {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final Logger _logger = Logger();

  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  Logger get logger => _logger;

  /// 알림 초기화
  Future<void> initialize() async {
    try {
      // FCM 권한 요청
      await _requestPermission();
      
      // FCM 토큰 가져오기
      await _getToken();
      
      // 메시지 리스너 설정
      _setupMessageListeners();
      
      _logger.i('Notification handler initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize notification handler: $e');
    }
  }

  /// FCM 권한 요청
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    _logger.i('FCM permission status: ${settings.authorizationStatus}');
  }

  /// FCM 토큰 가져오기
  Future<String?> _getToken() async {
    try {
      String? token = await _fcm.getToken();
      _logger.i('FCM Token: $token');
      return token;
    } catch (e) {
      _logger.e('Failed to get FCM token: $e');
      return null;
    }
  }

  /// 메시지 리스너 설정
  void _setupMessageListeners() {
    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.i('Received foreground message: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // 백그라운드에서 앱 열기
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.i('Message opened app: ${message.messageId}');
      _handleMessageOpenedApp(message);
    });

    // 앱이 종료된 상태에서 알림으로 앱 실행 (초기화 시 체크)
    _checkInitialMessage();
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('Foreground message: ${message.notification?.title}');
    
    // 로컬 알림 대신 로그만 출력 (임시)
    if (message.notification != null) {
      _logger.i('Title: ${message.notification!.title}');
      _logger.i('Body: ${message.notification!.body}');
    }
  }

  /// 메시지로 앱 열기 처리
  void _handleMessageOpenedApp(RemoteMessage message) {
    _logger.i('Message opened app: ${message.data}');
    // TODO: 특정 화면으로 네비게이션
  }

  /// FCM 토큰 갱신 리스너
  void onTokenRefresh(Function(String) callback) {
    _fcm.onTokenRefresh.listen(callback);
  }

  /// 초기 메시지 체크
  Future<void> _checkInitialMessage() async {
    try {
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _logger.i('App opened from terminated state: ${initialMessage.messageId}');
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      _logger.e('Failed to get initial message: $e');
    }
  }

  /// 현재 FCM 토큰 가져오기
  Future<String?> getToken() async {
    return await _getToken();
  }

  /// 로컬 알림 표시 (임시 비활성화)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // 로컬 알림 대신 로그만 출력
    final logger = Logger();
    logger.i('Local notification (disabled): $title - $body');
  }
}

/// 백그라운드 메시지 핸들러
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final logger = Logger();
  logger.i('Background message: ${message.messageId}');
}