import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/community_state.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';

enum _CommunityFilter { all, neighborhood, needsConfirmation }

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  _CommunityFilter _filter = _CommunityFilter.all;

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(communityPostsProvider);
    final visiblePosts = posts
        .where((post) {
          return switch (_filter) {
            _CommunityFilter.all => true,
            _CommunityFilter.neighborhood => post.isInNeighborhood,
            _CommunityFilter.needsConfirmation =>
              post.status == CommunityPostStatus.needsConfirmation,
          };
        })
        .toList(growable: false);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '커뮤니티',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge?.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '이웃들이 함께 만드는 용봉동 안전 지도예요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CompanionColors.muted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _CommunitySummary(),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      _FilterChip(
                        label: '전체',
                        onTap: () =>
                            setState(() => _filter = _CommunityFilter.all),
                        selected: _filter == _CommunityFilter.all,
                      ),
                      _FilterChip(
                        label: '내 동네',
                        onTap: () => setState(
                          () => _filter = _CommunityFilter.neighborhood,
                        ),
                        selected: _filter == _CommunityFilter.neighborhood,
                      ),
                      _FilterChip(
                        label: '확인 필요',
                        onTap: () => setState(
                          () => _filter = _CommunityFilter.needsConfirmation,
                        ),
                        selected: _filter == _CommunityFilter.needsConfirmation,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: visiblePosts.isEmpty
                        ? Center(
                            child: Text(
                              '아직 올라온 이야기가 없어요.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: CompanionColors.muted),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 74),
                            itemCount: visiblePosts.length,
                            itemBuilder: (context, index) {
                              final post = visiblePosts[index];
                              return _CommunityPostCard(
                                onConfirm: () => ref
                                    .read(communityPostsProvider.notifier)
                                    .confirm(post.id),
                                onOpen: () =>
                                    context.push('/community/${post.id}'),
                                post: post,
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                          ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: Semantics(
                button: true,
                label: '커뮤니티 글쓰기',
                child: Material(
                  borderRadius: BorderRadius.circular(999),
                  color: CompanionColors.coral,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push('/community/write'),
                    child: const SizedBox.square(
                      dimension: 56,
                      child: Icon(
                        Icons.add_rounded,
                        color: CompanionColors.white,
                        size: 27,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunitySummary extends StatelessWidget {
  const _CommunitySummary();

  @override
  Widget build(BuildContext context) => CompanionCard(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    radius: 22,
    child: const Row(
      children: [
        Expanded(
          child: _SummaryMetric(label: '이번 주 제보', value: '18'),
        ),
        _SummaryDivider(),
        Expanded(
          child: _SummaryMetric(
            color: CompanionColors.green,
            label: '함께 확인됨',
            value: '12',
          ),
        ),
        _SummaryDivider(),
        Expanded(
          child: _SummaryMetric(label: '참여 이웃', value: '42'),
        ),
      ],
    ),
  );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.color = CompanionColors.ink,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(color: color, fontSize: 20),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10.5),
      ),
    ],
  );
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 42,
    child: VerticalDivider(
      color: CompanionColors.creamMuted,
      thickness: 1,
      width: 16,
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onTap,
    required this.selected,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      borderRadius: BorderRadius.circular(999),
      color: selected ? CompanionColors.ink : CompanionColors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? CompanionColors.white : CompanionColors.ink,
            ),
          ),
        ),
      ),
    ),
  );
}

class _CommunityPostCard extends StatelessWidget {
  const _CommunityPostCard({
    required this.onConfirm,
    required this.onOpen,
    required this.post,
  });

  final VoidCallback onConfirm;
  final VoidCallback onOpen;
  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final (avatarBackground, avatarForeground) = switch (post.avatarTone) {
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
    final isConfirmed = post.status == CommunityPostStatus.confirmed;
    final tagBackground = isConfirmed
        ? CompanionColors.greenSoft
        : CompanionColors.amberSoft;
    final tagForeground = isConfirmed
        ? CompanionColors.green
        : CompanionColors.amber;

    return CompanionCard(
      onTap: onOpen,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      radius: 22,
      semanticLabel: '${post.name}의 ${post.location} 커뮤니티 글 상세 보기',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: avatarBackground,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 34,
                  child: Center(
                    child: Text(
                      post.initial,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: avatarForeground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${post.location} · ${post.time}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CompanionTag(
                    backgroundColor: tagBackground,
                    foregroundColor: tagForeground,
                    label: isConfirmed ? '확인됨' : '확인 필요',
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: CompanionColors.faint,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Semantics(
            button: true,
            label: '이 도로 상황 확인하기, 현재 ${post.confirmations}명 확인',
            child: Material(
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onConfirm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        color: CompanionColors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '저도 확인했어요 · ${post.confirmations}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: CompanionColors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
