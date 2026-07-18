import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _notifications = [
    _NotificationItem(
      body: '오늘의 산책 점수는 88점, 대체로 편안한 경로였어요',
      id: 1,
      time: '16:03',
      title: '산책 리포트가 도착했어요',
      unread: true,
    ),
    _NotificationItem(
      body: '최근 반복적인 충격이 감지되어 접근성 점수가 조정됐어요',
      id: 2,
      time: '14:21',
      title: '오크가 구간 점수가 낮아졌어요',
      unread: true,
    ),
    _NotificationItem(
      body: '리버사이드길 데이터가 5명 이상에게 확인되어 신뢰도 65%가 됐어요',
      id: 3,
      time: '09:47',
      title: '신뢰도가 상승했어요',
      unread: false,
    ),
    _NotificationItem(
      body: '휠체어 전용 센서 모드가 추가됐어요',
      id: 4,
      time: '3일 전',
      title: 'Road DNA 업데이트 안내',
      unread: false,
    ),
  ];

  final Set<int> _readInSession = {};

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BackLink(onTap: _goBack),
            const SizedBox(height: 14),
            Text(
              '알림',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(
                  child: Divider(
                    color: CompanionColors.creamLine,
                    height: 1,
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '25.08.19',
                    style: TextStyle(
                      color: CompanionColors.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: CompanionColors.creamLine,
                    height: 1,
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  final unread =
                      notification.unread &&
                      !_readInSession.contains(notification.id);
                  return CompanionCard(
                    key: ValueKey(notification.id),
                    onTap: () {
                      if (unread) {
                        setState(() => _readInSession.add(notification.id));
                      }
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    radius: 22,
                    semanticLabel:
                        '${notification.title}, ${unread ? '읽지 않은 알림' : '읽은 알림'}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                notification.title,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            if (unread) ...[
                              const SizedBox(width: 5),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: CompanionColors.coral,
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox.square(dimension: 5),
                              ),
                            ],
                            const SizedBox(width: 4),
                            Text(
                              notification.time,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: CompanionColors.faint,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.body,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: CompanionColors.muted,
                                fontSize: 12.5,
                              ),
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '돌아가기',
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back_ios_new_rounded,
              color: CompanionColors.coral,
              size: 18,
            ),
            SizedBox(width: 3),
            Text(
              '돌아가기',
              style: TextStyle(
                color: CompanionColors.coral,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NotificationItem {
  const _NotificationItem({
    required this.body,
    required this.id,
    required this.time,
    required this.title,
    required this.unread,
  });

  final String body;
  final int id;
  final String time;
  final String title;
  final bool unread;
}
