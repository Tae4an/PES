import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// 앱 내 알림 오버레이 위젯
class NotificationOverlay extends StatefulWidget {
  final Widget child;

  const NotificationOverlay({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay>
    with TickerProviderStateMixin {
  final List<InAppNotification> _notifications = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // FCM 포그라운드 메시지 리스너
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      _showNotification(
        title: message.notification!.title ?? '알림',
        body: message.notification!.body ?? '',
        data: message.data,
      );
    }
  }

  void _showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    final notification = InAppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      data: data,
      timestamp: DateTime.now(),
    );

    setState(() {
      _notifications.add(notification);
    });

    _animationController.forward();

    // 5초 후 자동 제거
    Future.delayed(const Duration(seconds: 5), () {
      _removeNotification(notification.id);
    });
  }

  void _removeNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          // 알림 오버레이
          if (_notifications.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Column(
                children: _notifications
                    .map((notification) => _buildNotificationCard(notification))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(InAppNotification notification) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          )),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _removeNotification(notification.id),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // 아이콘
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 내용
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.body,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(notification.timestamp),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 닫기 버튼
                      IconButton(
                        onPressed: () => _removeNotification(notification.id),
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) {
      return '방금 전';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// 앱 내 알림 데이터 모델
class InAppNotification {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.data,
    required this.timestamp,
  });
}

/// 전역 알림 표시 함수
class NotificationService {
  static final GlobalKey<_NotificationOverlayState> _key = 
      GlobalKey<_NotificationOverlayState>();

  static GlobalKey<_NotificationOverlayState> get key => _key;

  static void showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    _key.currentState?._showNotification(
      title: title,
      body: body,
      data: data,
    );
  }
}
