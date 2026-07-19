import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
  static const _maximumPhotoBytes = 12 * 1024 * 1024;
  static const _situations = ['단차 · 파손', '경사로 없음', '공사 중', '개선됨'];

  final _bodyController = TextEditingController();
  final _imagePicker = ImagePicker();
  var _isPickingPhoto = false;
  Uint8List? _photoBytes;
  var _selectedSituation = _situations.first;

  @override
  void initState() {
    super.initState();
    unawaited(_recoverLostPhoto());
  }

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
          _buildPhotoAttachment(context),
        ],
      ),
    ),
  );

  Widget _buildPhotoAttachment(BuildContext context) {
    final photoBytes = _photoBytes;
    if (photoBytes == null) {
      return CompanionCard(
        onTap: _isPickingPhoto ? null : _pickPhoto,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        radius: 20,
        semanticLabel: '사진 보관함에서 사진 한 장 추가하기',
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: CompanionColors.creamMuted,
              ),
              child: SizedBox.square(
                dimension: 44,
                child: Center(
                  child: _isPickingPhoto
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            color: CompanionColors.coralAction,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: CompanionColors.muted,
                          size: 21,
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isPickingPhoto ? '사진을 불러오는 중이에요' : '사진 추가하기',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CompanionColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '등록하면 게시글 상세 화면에서 보여요',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return CompanionCard(
      border: CompanionColors.coral,
      padding: EdgeInsets.zero,
      radius: 20,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.memory(
                photoBytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                semanticLabel: '첨부할 커뮤니티 사진 미리보기',
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: CompanionColors.creamMuted,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: CompanionColors.muted,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '사진 1장 첨부됨',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '목록에는 표시되지 않아요',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _isPickingPhoto ? null : _pickPhoto,
                  style: companionButtonStyle(
                    TextButton.styleFrom(
                      foregroundColor: CompanionColors.coralAction,
                    ),
                  ),
                  child: const Text('변경'),
                ),
                CompanionIconButton(
                  backgroundColor: CompanionColors.creamMuted,
                  foregroundColor: CompanionColors.muted,
                  icon: Icons.delete_outline_rounded,
                  onPressed: _removePhoto,
                  semanticLabel: '첨부한 사진 제거',
                  size: 40,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
          imageBytes: _photoBytes,
          initial: nickname.substring(0, 1),
          situation: _selectedSituation,
        );

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/community');
    }
  }

  Future<void> _pickPhoto() async {
    if (_isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxHeight: 1600,
        maxWidth: 1600,
        requestFullMetadata: false,
      );
      if (photo != null) await _usePhoto(photo);
    } on PlatformException {
      if (mounted) {
        showCompanionMessage(context, '사진을 열지 못했어요. 다시 선택해주세요.');
      }
    } on Exception {
      if (mounted) {
        showCompanionMessage(context, '사진을 열지 못했어요. 다시 선택해주세요.');
      }
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _recoverLostPhoto() async {
    try {
      final response = await _imagePicker.retrieveLostData();
      if (!mounted || response.isEmpty) return;
      final files = response.files;
      if (files != null && files.isNotEmpty) {
        await _usePhoto(files.first);
      } else if (response.exception != null && mounted) {
        showCompanionMessage(context, '선택하던 사진을 복구하지 못했어요.');
      }
    } on PlatformException {
      if (mounted) {
        showCompanionMessage(context, '선택하던 사진을 복구하지 못했어요.');
      }
    } on Exception {
      if (mounted) {
        showCompanionMessage(context, '선택하던 사진을 복구하지 못했어요.');
      }
    }
  }

  Future<void> _usePhoto(XFile photo) async {
    final bytes = await photo.readAsBytes();
    if (!mounted) return;
    if (bytes.isEmpty) {
      showCompanionMessage(context, '비어 있는 사진은 첨부할 수 없어요.');
      return;
    }
    if (bytes.lengthInBytes > _maximumPhotoBytes) {
      showCompanionMessage(context, '12MB 이하 사진을 선택해주세요.');
      return;
    }
    setState(() => _photoBytes = Uint8List.fromList(bytes));
    showCompanionMessage(context, '사진을 첨부했어요.');
  }

  void _removePhoto() {
    setState(() => _photoBytes = null);
    showCompanionMessage(context, '첨부한 사진을 지웠어요.');
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
