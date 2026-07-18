import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _ageAgreed = true;
  bool _locationAgreed = true;
  bool _marketingAgreed = false;
  bool _privacyAgreed = true;
  bool _serviceAgreed = true;

  bool get _requiredAgreed =>
      _ageAgreed && _serviceAgreed && _privacyAgreed && _locationAgreed;

  void _toggleRequired() {
    final next = !_requiredAgreed;
    setState(() {
      _ageAgreed = next;
      _serviceAgreed = next;
      _privacyAgreed = next;
      _locationAgreed = next;
    });
  }

  void _showTerms(String label) {
    showCompanionMessage(context, '$label 전문은 데모에서 생략했어요.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 22),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BackLink(onTap: () => context.go('/permission')),
                  const SizedBox(height: 22),
                  Text(
                    '약관에 동의해주세요',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '여러분의 개인정보와 이동 데이터를\n안전하게 지켜드릴게요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CompanionColors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    checked: _requiredAgreed,
                    child: CompanionCard(
                      onTap: _toggleRequired,
                      padding: const EdgeInsets.all(18),
                      radius: 22,
                      semanticLabel: '필수 약관 모두 동의',
                      child: Row(
                        children: [
                          _AgreementMark(
                            checked: _requiredAgreed,
                            filled: true,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '모두 동의',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '서비스 이용에 필요한 약관에 모두 동의합니다',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Column(
                      children: [
                        _AgreementRow(
                          checked: _ageAgreed,
                          label: '(필수) 만 14세 이상입니다',
                          onChanged: (value) =>
                              setState(() => _ageAgreed = value),
                        ),
                        _AgreementRow(
                          checked: _serviceAgreed,
                          label: '(필수) 서비스 이용약관 동의',
                          onChanged: (value) =>
                              setState(() => _serviceAgreed = value),
                          onView: () => _showTerms('서비스 이용약관'),
                        ),
                        _AgreementRow(
                          checked: _privacyAgreed,
                          label: '(필수) 개인정보 처리방침 동의',
                          onChanged: (value) =>
                              setState(() => _privacyAgreed = value),
                          onView: () => _showTerms('개인정보 처리방침'),
                        ),
                        _AgreementRow(
                          checked: _locationAgreed,
                          label: '(필수) 위치·센서 정보 수집 동의',
                          onChanged: (value) =>
                              setState(() => _locationAgreed = value),
                          onView: () => _showTerms('위치·센서 정보 수집 동의'),
                        ),
                        _AgreementRow(
                          checked: _marketingAgreed,
                          label: '(선택) 마케팅 정보 수신 동의',
                          onChanged: (value) =>
                              setState(() => _marketingAgreed = value),
                          onView: () => _showTerms('마케팅 정보 수신 동의'),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 20),
                  CompanionPrimaryButton(
                    label: '다음',
                    onPressed: _requiredAgreed
                        ? () => context.go('/nickname')
                        : null,
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

class _BackLink extends StatelessWidget {
  const _BackLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Semantics(
      button: true,
      excludeSemantics: true,
      label: '돌아가기',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const SizedBox(
          height: 44,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chevron_left_rounded,
                color: CompanionColors.coralAction,
                size: 22,
              ),
              SizedBox(width: 2),
              Text(
                '돌아가기',
                style: TextStyle(
                  color: CompanionColors.coralAction,
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.checked,
    required this.label,
    required this.onChanged,
    this.onView,
    this.showDivider = true,
  });

  final bool checked;
  final String label;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onView;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Material(
    color: CompanionColors.white,
    child: InkWell(
      onTap: () => onChanged(!checked),
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(color: CompanionColors.creamMuted),
                )
              : null,
        ),
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
        child: Row(
          children: [
            Semantics(
              checked: checked,
              child: _AgreementMark(checked: checked),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: checked ? CompanionColors.ink : CompanionColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onView != null)
              TextButton(
                onPressed: onView,
                style: TextButton.styleFrom(
                  foregroundColor: CompanionColors.muted,
                  minimumSize: const Size(48, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: Theme.of(context).textTheme.labelSmall,
                ),
                child: const Text('보기'),
              ),
          ],
        ),
      ),
    ),
  );
}

class _AgreementMark extends StatelessWidget {
  const _AgreementMark({required this.checked, this.filled = false});

  final bool checked;
  final bool filled;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    alignment: Alignment.center,
    duration: const Duration(milliseconds: 140),
    height: filled ? 22 : 20,
    width: filled ? 22 : 20,
    decoration: BoxDecoration(
      color: checked && filled
          ? CompanionColors.coralAction
          : Colors.transparent,
      shape: filled ? BoxShape.circle : BoxShape.rectangle,
    ),
    child: Icon(
      Icons.check_rounded,
      color: checked
          ? filled
                ? CompanionColors.white
                : CompanionColors.coralAction
          : CompanionColors.faint,
      size: filled ? 14 : 19,
    ),
  );
}
