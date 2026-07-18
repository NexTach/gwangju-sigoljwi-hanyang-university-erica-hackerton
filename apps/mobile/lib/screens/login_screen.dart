import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/brand_mark.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 52),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Center(
                    child: RoadDnaBrandMark(showAccentDot: false, size: 64),
                  ),
                  const SizedBox(height: 20),
                  CompanionCard(
                    padding: const EdgeInsets.all(22),
                    radius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '보이지 않던 위험을\n미리 알려드려요',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 14),
                        const Divider(
                          color: CompanionColors.creamMuted,
                          height: 1,
                        ),
                        const SizedBox(height: 8),
                        const _RoadPreviewRow(
                          label: '오크가 3번길',
                          tag: '주의',
                          tagBackground: CompanionColors.amberSoft,
                          tagColor: CompanionColors.amber,
                        ),
                        const _RoadPreviewRow(
                          label: '리버사이드길',
                          tag: '편안',
                          tagBackground: CompanionColors.greenSoft,
                          tagColor: CompanionColors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PageDot(active: true),
                      SizedBox(width: 6),
                      _PageDot(),
                      SizedBox(width: 6),
                      _PageDot(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '위험한지 편안한지\n내 이동 경로를 분석하세요',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  const SizedBox(height: 24),
                  _SocialLoginButton(
                    backgroundColor: Color(0xFFFEE500),
                    icon: _KakaoMark(),
                    label: '카카오로 3초만에 로그인',
                    onPressed: () => context.go('/permission'),
                  ),
                  const SizedBox(height: 10),
                  _SocialLoginButton(
                    backgroundColor: CompanionColors.white,
                    borderColor: CompanionColors.creamLine,
                    icon: const _GoogleMark(),
                    label: '구글로 로그인',
                    onPressed: () => context.go('/permission'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '로그인 시 이용약관 및 개인정보처리방침에 동의해요',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CompanionColors.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RoadPreviewRow extends StatelessWidget {
  const _RoadPreviewRow({
    required this.label,
    required this.tag,
    required this.tagBackground,
    required this.tagColor,
  });

  final String label;
  final String tag;
  final Color tagBackground;
  final Color tagColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: CompanionColors.muted),
          ),
        ),
        CompanionTag(
          backgroundColor: tagBackground,
          foregroundColor: tagColor,
          label: tag,
        ),
      ],
    ),
  );
}

class _PageDot extends StatelessWidget {
  const _PageDot({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: active ? CompanionColors.coral : CompanionColors.creamLine,
      shape: BoxShape.circle,
    ),
    child: const SizedBox.square(dimension: 6),
  );
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.backgroundColor,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.borderColor,
  });

  final Color backgroundColor;
  final Color? borderColor;
  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: SizedBox(
      height: 56,
      child: Material(
        borderRadius: BorderRadius.circular(999),
        color: backgroundColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              border: borderColor == null
                  ? null
                  : Border.all(color: borderColor!, width: 1.5),
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _KakaoMark extends StatelessWidget {
  const _KakaoMark();

  @override
  Widget build(BuildContext context) => const Icon(
    Icons.chat_bubble_rounded,
    color: CompanionColors.ink,
    size: 18,
  );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => Text(
    'G',
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: const Color(0xFF4285F4),
      fontSize: 18,
    ),
  );
}
