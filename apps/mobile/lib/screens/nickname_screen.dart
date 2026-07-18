import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/demo_profile_state.dart';

class NicknameScreen extends ConsumerStatefulWidget {
  const NicknameScreen({super.key});

  @override
  ConsumerState<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends ConsumerState<NicknameScreen> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(demoProfileProvider).nickname,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final nickname = _controller.text.trim();
    if (nickname.length < 2 || nickname.length > 10) {
      setState(() => _error = '닉네임은 2~10자로 입력해 주세요.');
      return;
    }
    ref.read(demoProfileProvider.notifier).setNickname(nickname);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '마지막이에요',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: CompanionColors.coralAction,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '뭐라고 불러드릴까요?',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 28),
            TextField(
              autofocus: true,
              controller: _controller,
              maxLength: 10,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
              style: Theme.of(context).textTheme.headlineSmall,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                counterText: '',
                errorText: _error,
                helperText: '2~10자로 입력해주세요',
                hintText: '닉네임',
              ),
            ),
            const Spacer(),
            CompanionPrimaryButton(label: '시작하기', onPressed: _submit),
          ],
        ),
      ),
    ),
  );
}
