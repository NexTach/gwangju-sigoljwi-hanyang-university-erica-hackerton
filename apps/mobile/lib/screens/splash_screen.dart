import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:road_dna_design/road_dna_design.dart';

import '../services/location_service.dart';
import '../state/providers.dart';
import '../ui/brand_mark.dart';

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
    try {
      await ref.read(anonymousIdentityProvider.future);
      final access = await ref.read(locationAccessProvider.future);
      if (!mounted) return;
      context.go(
        access == LocationAccess.granted ? '/home' : '/permission',
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = '앱을 준비하지 못했어요. 다시 시도해 주세요.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(RdSpacing.x8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const RoadDnaBrandMark(size: 84),
              const SizedBox(height: RdSpacing.x5),
              Text(
                'Road DNA',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: RdSpacing.x2),
              Text(
                '이동의 흔적이 도시의 장벽을 발견하다.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.rdColors.contentSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: RdSpacing.x8),
              if (_error == null)
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                Text(
                  _error!,
                  style: TextStyle(color: context.rdColors.statusCritical),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: RdSpacing.x4),
                RdButton(
                  label: '다시 시도',
                  onPressed: () {
                    setState(() => _error = null);
                    _bootstrap();
                  },
                  tone: RdButtonTone.secondary,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
