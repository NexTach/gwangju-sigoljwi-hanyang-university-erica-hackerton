import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/community_state.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';

class CommunityDetailScreen extends ConsumerWidget {
  const CommunityDetailScreen({required this.postId, super.key});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = _findPost(ref.watch(communityPostsProvider));
    if (post == null) {
      return _MissingCommunityPost(onBack: () => _goBack(context));
    }

    final isConfirmed = post.status == CommunityPostStatus.confirmed;
    final statusBackground = isConfirmed
        ? CompanionColors.greenSoft
        : CompanionColors.amberSoft;
    final statusForeground = isConfirmed
        ? CompanionColors.green
        : CompanionColors.amber;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 30),
          children: [
            CompanionBackLink(onPressed: () => _goBack(context)),
            const SizedBox(height: 20),
            Row(
              children: [
                CompanionTag(
                  backgroundColor: statusBackground,
                  foregroundColor: statusForeground,
                  label: isConfirmed ? '확인됨' : '확인 필요',
                ),
                const Spacer(),
                Text(post.time, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              post.situation ?? '도로 상황 제보',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 7),
            Text(
              '${post.location}에서 이웃이 전한 이동 정보예요',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: CompanionColors.muted),
            ),
            if (post.imageBytes case final imageBytes?) ...[
              const SizedBox(height: 22),
              Text(
                '현장 사진',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: CompanionColors.coralAction,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    semanticLabel: '${post.location} 커뮤니티 현장 사진',
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(
                          color: CompanionColors.creamMuted,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: CompanionColors.muted,
                              size: 42,
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            CompanionCard(
              padding: const EdgeInsets.all(20),
              radius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CommunityAvatar(post: post),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.name,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '용봉동 이웃',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      color: CompanionColors.creamMuted,
                      height: 1,
                    ),
                  ),
                  Text(
                    post.body,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.65),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CompanionCard(
              onTap: () => _openRoad(context, post),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              radius: 20,
              semanticLabel: '${post.location} 도로 정보 보기',
              child: Row(
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: CompanionColors.coralSoft,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 42,
                      child: Icon(
                        Icons.route_outlined,
                        color: CompanionColors.coralAction,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.location,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '도로 점수와 최근 감지 확인',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: CompanionColors.faint,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            CompanionPrimaryButton(
              backgroundColor: isConfirmed
                  ? CompanionColors.green
                  : CompanionColors.coralAction,
              icon: Icons.check_rounded,
              label: isConfirmed
                  ? '${post.confirmations}명이 확인했어요'
                  : '저도 확인했어요 · ${post.confirmations}',
              onPressed: () {
                ref.read(communityPostsProvider.notifier).confirm(post.id);
                showCompanionMessage(context, '확인에 참여했어요.');
              },
            ),
          ],
        ),
      ),
    );
  }

  CommunityPost? _findPost(List<CommunityPost> posts) {
    for (final post in posts) {
      if (post.id == postId) return post;
    }
    return null;
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/community');
    }
  }

  void _openRoad(BuildContext context, CommunityPost post) {
    final uri = Uri(
      path: '/road/${post.roadSegmentId}',
      queryParameters: {'name': post.location},
    );
    context.push(uri.toString());
  }
}

class _CommunityAvatar extends StatelessWidget {
  const _CommunityAvatar({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (post.avatarTone) {
      CommunityAvatarTone.amber => (
        CompanionColors.amberSoft,
        CompanionColors.amber,
      ),
      CommunityAvatarTone.green => (
        CompanionColors.greenSoft,
        CompanionColors.green,
      ),
      CommunityAvatarTone.neutral => (
        CompanionColors.creamMuted,
        CompanionColors.muted,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: SizedBox.square(
        dimension: 42,
        child: Center(
          child: Text(
            post.initial,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _MissingCommunityPost extends StatelessWidget {
  const _MissingCommunityPost({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompanionBackLink(onPressed: onBack),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      color: CompanionColors.faint,
                      size: 42,
                    ),
                    SizedBox(height: 14),
                    Text(
                      '게시글을 찾을 수 없어요',
                      style: TextStyle(
                        color: CompanionColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '커뮤니티 목록에서 다른 이야기를 확인해주세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: CompanionColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
