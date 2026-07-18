import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/providers.dart';
import '../ui/brand_mark.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final startedAt = DateTime.now();
    try {
      await Future.wait([
        ref.read(anonymousIdentityProvider.future),
        ref.read(locationAccessProvider.future),
      ]);
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed < const Duration(milliseconds: 850)) {
        await Future<void>.delayed(const Duration(milliseconds: 850) - elapsed);
      }
      if (!mounted) return;
      context.go('/permission');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '앱을 준비하지 못했어요. 다시 시도해 주세요.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CompanionColors.coral,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: _error == null
                ? Column(
                    key: const ValueKey('brand'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const RoadDnaBrandMark(
                        backgroundColor: CompanionColors.coral,
                        showAccentDot: false,
                        size: 82,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Road DNA',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: CompanionColors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '당신을 위한 AI 이동 도우미',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: CompanionColors.white.withValues(alpha: 0.86),
                        ),
                      ),
                      const SizedBox(height: 34),
                      const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          color: CompanionColors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('error'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        color: CompanionColors.white,
                        size: 42,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: CompanionColors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      CompanionPrimaryButton(
                        backgroundColor: CompanionColors.white,
                        foregroundColor: CompanionColors.coralAction,
                        label: '다시 시도',
                        onPressed: () {
                          setState(() => _error = null);
                          unawaited(_bootstrap());
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );
}
