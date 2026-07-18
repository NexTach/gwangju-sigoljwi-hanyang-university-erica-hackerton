import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/community_state.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/demo_profile_state.dart';

class CommunityWriteScreen extends ConsumerStatefulWidget {
  const CommunityWriteScreen({super.key});

  @override
  ConsumerState<CommunityWriteScreen> createState() =>
      _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends ConsumerState<CommunityWriteScreen> {
  static const _situations = ['단차 · 파손', '경사로 없음', '공사 중', '개선됨'];

  final _bodyController = TextEditingController();
  var _hasPhoto = false;
  var _selectedSituation = _situations.first;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
        children: [
          Row(
            children: [
              _BackLink(onTap: _goBack),
              const Spacer(),
              FilledButton(
                onPressed: _submit,
                style: companionButtonStyle(
                  FilledButton.styleFrom(
                    backgroundColor: CompanionColors.coral,
                    foregroundColor: CompanionColors.white,
                    minimumSize: const Size(72, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: const StadiumBorder(),
                    textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                child: const Text('등록'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '이웃에게 알리기',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text(
            '보신 도로 상황을 공유해주세요',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: CompanionColors.muted),
          ),
          const SizedBox(height: 20),
          CompanionCard(
            onTap: () => showCompanionMessage(context, '현재 위치를 사용하고 있어요.'),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            radius: 20,
            semanticLabel: '현재 위치 광주 북구 용봉동 반룡로',
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: CompanionColors.coral,
                  size: 19,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '현재 위치',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '광주 북구 용봉동 · 반룡로',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: CompanionColors.faint,
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '어떤 상황인가요?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            runSpacing: 8,
            spacing: 8,
            children: [
              for (final situation in _situations)
                _SituationChip(
                  label: situation,
                  onTap: () => setState(() => _selectedSituation = situation),
                  selected: _selectedSituation == situation,
                ),
            ],
          ),
          const SizedBox(height: 16),
          CompanionCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            radius: 20,
            child: SizedBox(
              height: 198,
              child: TextField(
                controller: _bodyController,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText:
                      '이웃들에게 도움이 될 내용을 자유롭게 적어주세요. '
                      '예: 이 앞 연석에 경사로가 없어서 지나가기 어려워요.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 14),
          CompanionCard(
            border: _hasPhoto ? CompanionColors.coral : null,
            onTap: _togglePhoto,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            radius: 20,
            selected: _hasPhoto,
            semanticLabel: _hasPhoto ? '추가한 사진 제거하기' : '사진 추가하기',
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: _hasPhoto
                        ? CompanionColors.coralSoft
                        : CompanionColors.creamMuted,
                  ),
                  child: SizedBox.square(
                    dimension: 44,
                    child: Icon(
                      _hasPhoto ? Icons.check_rounded : Icons.image_outlined,
                      color: _hasPhoto
                          ? CompanionColors.coralAction
                          : CompanionColors.muted,
                      size: 21,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _hasPhoto ? '사진이 추가됐어요' : '사진 추가하기',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _hasPhoto
                        ? CompanionColors.coralAction
                        : CompanionColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/community');
    }
  }

  void _submit() {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      showCompanionMessage(context, '이웃에게 알릴 내용을 적어주세요.');
      return;
    }

    final nickname = ref.read(demoProfileProvider).nickname;
    ref
        .read(communityPostsProvider.notifier)
        .addPost(
          author: '$nickname님',
          body: body,
          initial: nickname.substring(0, 1),
          situation: _selectedSituation,
        );

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/community');
    }
  }

  void _togglePhoto() {
    setState(() => _hasPhoto = !_hasPhoto);
    showCompanionMessage(
      context,
      _hasPhoto ? '사진 한 장을 추가했어요.' : '추가한 사진을 지웠어요.',
    );
  }
}

class _SituationChip extends StatelessWidget {
  const _SituationChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? CompanionColors.white : CompanionColors.ink,
              fontSize: 12,
            ),
          ),
        ),
      ),
    ),
  );
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
