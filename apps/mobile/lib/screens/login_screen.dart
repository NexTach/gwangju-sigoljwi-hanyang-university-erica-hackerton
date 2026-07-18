import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/brand_mark.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';

const _carouselInterval = Duration(milliseconds: 3500);
const _carouselAnimationDuration = Duration(milliseconds: 320);
const _carouselSwipeThreshold = 44.0;
const _carouselFlingThreshold = 320.0;

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    @visibleForTesting this.initialLifecycleStateOverride,
  });

  @visibleForTesting
  final AppLifecycleState? initialLifecycleStateOverride;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  Timer? _advanceTimer;
  Timer? _transitionTimer;
  var _activeIndex = 0;
  var _disableAnimations = false;
  var _hasSeenForegroundLifecycle = false;
  var _isAppActive = true;
  var _isDragging = false;
  var _isTransitioning = false;
  var _wasExplicitlyBackgrounded = false;
  var _horizontalDragDistance = 0.0;
  var _transitionDirection = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycleState =
        widget.initialLifecycleStateOverride ??
        WidgetsBinding.instance.lifecycleState;
    _hasSeenForegroundLifecycle =
        lifecycleState == AppLifecycleState.resumed ||
        lifecycleState == AppLifecycleState.inactive;
    _wasExplicitlyBackgrounded =
        lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.hidden;
    _isAppActive = _canBootstrapCarousel(lifecycleState);
    // A cold Android launch can still report `detached` before its first
    // lifecycle message. Start the clock now as well as after the first frame
    // so a missed `resumed` event cannot leave the carousel permanently idle.
    _scheduleAdvance();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _isAppActive = _canBootstrapCarousel(
        WidgetsBinding.instance.lifecycleState,
      );
      _scheduleAdvance();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _transitionTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isForeground =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    if (isForeground) {
      _hasSeenForegroundLifecycle = true;
      _wasExplicitlyBackgrounded = false;
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wasExplicitlyBackgrounded = true;
    }
    final isActive =
        isForeground ||
        (state == AppLifecycleState.detached &&
            !_hasSeenForegroundLifecycle &&
            !_wasExplicitlyBackgrounded);
    if (_isAppActive == isActive) return;
    _isAppActive = isActive;
    if (isActive) {
      _scheduleAdvance();
    } else {
      _advanceTimer?.cancel();
      _advanceTimer = null;
    }
  }

  bool _canBootstrapCarousel(AppLifecycleState? state) =>
      state != AppLifecycleState.paused &&
      state != AppLifecycleState.hidden &&
      (state != AppLifecycleState.detached || !_wasExplicitlyBackgrounded);

  void _scheduleAdvance() {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    if (!_isAppActive || _isDragging || _isTransitioning || !mounted) return;
    _advanceTimer = Timer(_carouselInterval, () {
      _advanceTimer = null;
      _advance();
    });
  }

  void _advance() {
    if (!mounted || !_isAppActive || _isDragging || _isTransitioning) return;
    _showRelativeSlide(1);
  }

  void _showRelativeSlide(int delta) {
    final nextIndex =
        (_activeIndex + delta + _loginSlides.length) % _loginSlides.length;
    _showSlide(nextIndex, direction: delta.sign);
  }

  void _showSlide(int targetIndex, {required int direction}) {
    if (!mounted) return;
    if (_isTransitioning) return;
    if (targetIndex == _activeIndex) {
      _scheduleAdvance();
      return;
    }

    _advanceTimer?.cancel();
    _advanceTimer = null;
    _transitionTimer?.cancel();
    setState(() {
      _isTransitioning = true;
      _transitionDirection = direction;
      _activeIndex = targetIndex;
    });
    final transitionDuration = _disableAnimations
        ? Duration.zero
        : _carouselAnimationDuration;
    if (transitionDuration == Duration.zero) {
      _isTransitioning = false;
      _scheduleAdvance();
      return;
    }
    _transitionTimer = Timer(transitionDuration, () {
      _transitionTimer = null;
      if (!mounted) return;
      _isTransitioning = false;
      _scheduleAdvance();
    });
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    _isDragging = true;
    _horizontalDragDistance = 0;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _horizontalDragDistance += details.primaryDelta ?? 0;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    _isDragging = false;
    final velocity = details.primaryVelocity ?? 0;
    final shouldAdvance =
        _horizontalDragDistance <= -_carouselSwipeThreshold ||
        velocity <= -_carouselFlingThreshold;
    final shouldGoBack =
        _horizontalDragDistance >= _carouselSwipeThreshold ||
        velocity >= _carouselFlingThreshold;

    if (shouldAdvance) {
      _showRelativeSlide(1);
    } else if (shouldGoBack) {
      _showRelativeSlide(-1);
    } else {
      _scheduleAdvance();
    }
    _horizontalDragDistance = 0;
  }

  void _handleHorizontalDragCancel() {
    _isDragging = false;
    _horizontalDragDistance = 0;
    _scheduleAdvance();
  }

  void _goToSlide(int targetIndex) {
    if (targetIndex == _activeIndex) {
      _scheduleAdvance();
      return;
    }

    var direction = targetIndex - _activeIndex;
    if (direction > 1) direction -= _loginSlides.length;
    if (direction < -1) direction += _loginSlides.length;
    _showSlide(targetIndex, direction: direction.sign);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Center(
                    child: RoadDnaBrandMark(showAccentDot: false, size: 60),
                  ),
                  const SizedBox(height: 18),
                  ClipRect(
                    key: const ValueKey('login-carousel-viewport'),
                    child: SizedBox(
                      height: 246,
                      child: GestureDetector(
                        key: const ValueKey('login-carousel'),
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: _handleHorizontalDragStart,
                        onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                        onHorizontalDragEnd: _handleHorizontalDragEnd,
                        onHorizontalDragCancel: _handleHorizontalDragCancel,
                        child: AnimatedSwitcher(
                          duration: _disableAnimations
                              ? Duration.zero
                              : _carouselAnimationDuration,
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          layoutBuilder: (currentChild, previousChildren) =>
                              Stack(
                                alignment: Alignment.center,
                                fit: StackFit.expand,
                                clipBehavior: Clip.hardEdge,
                                children: [...previousChildren, ?currentChild],
                              ),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation.drive(
                                  CurveTween(
                                    curve: const Interval(
                                      0.55,
                                      1,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                ),
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: Offset(
                                      0.012 * _transitionDirection,
                                      0,
                                    ),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: ScaleTransition(
                                    scale: Tween<double>(
                                      begin: 0.992,
                                      end: 1,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                              ),
                          child: _LoginCarouselSlide(
                            key: ValueKey('login-carousel-slide-$_activeIndex'),
                            slide: _loginSlides[_activeIndex],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _loginSlides.length,
                      (index) => _CarouselDot(
                        active: index == _activeIndex,
                        index: index,
                        onTap: () => _goToSlide(index),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 22),
                  _KakaoLoginButton(onPressed: () => context.go('/permission')),
                  const SizedBox(height: 10),
                  _GoogleLoginButton(
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

class _LoginSlideData {
  const _LoginSlideData({
    required this.cardTitle,
    required this.description,
    required this.rows,
  });

  final String cardTitle;
  final String description;
  final List<_PreviewRowData> rows;
}

class _PreviewRowData {
  const _PreviewRowData({
    required this.label,
    required this.tag,
    required this.tagBackground,
    required this.tagColor,
  });

  final String label;
  final String tag;
  final Color tagBackground;
  final Color tagColor;
}

const _loginSlides = [
  _LoginSlideData(
    cardTitle: '보이지 않던 위험을 미리 알려드려요',
    description: '위험한지 편안한지\n내 이동 경로를 분석하세요',
    rows: [
      _PreviewRowData(
        label: '반룡로',
        tag: '주의',
        tagBackground: CompanionColors.amberSoft,
        tagColor: CompanionColors.amber,
      ),
      _PreviewRowData(
        label: '설죽로202번길',
        tag: '편안',
        tagBackground: CompanionColors.greenSoft,
        tagColor: CompanionColors.green,
      ),
    ],
  ),
  _LoginSlideData(
    cardTitle: '내게 맞는 경로를 비교해요',
    description: '이동 방식에 맞는\n더 편안한 길을 골라보세요',
    rows: [
      _PreviewRowData(
        label: '편안한 경로 · 18분',
        tag: '추천',
        tagBackground: CompanionColors.greenSoft,
        tagColor: CompanionColors.green,
      ),
      _PreviewRowData(
        label: '빠른 경로 · 14분',
        tag: '턱 2곳',
        tagBackground: CompanionColors.amberSoft,
        tagColor: CompanionColors.amber,
      ),
    ],
  ),
  _LoginSlideData(
    cardTitle: '걸을수록 길 정보가 쌓여요',
    description: '내 산책 기록이\n모두의 안전한 길이 돼요',
    rows: [
      _PreviewRowData(
        label: '오늘 확인한 보도',
        tag: '1.2km',
        tagBackground: CompanionColors.coralSoft,
        tagColor: CompanionColors.coralAction,
      ),
      _PreviewRowData(
        label: '함께 확인한 이웃',
        tag: '24명',
        tagBackground: CompanionColors.greenSoft,
        tagColor: CompanionColors.green,
      ),
    ],
  ),
];

class _LoginCarouselSlide extends StatelessWidget {
  const _LoginCarouselSlide({required this.slide, super.key});

  final _LoginSlideData slide;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 1),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompanionCard(
          padding: const EdgeInsets.all(20),
          radius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                slide.cardTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Divider(color: CompanionColors.creamMuted, height: 1),
              const SizedBox(height: 7),
              for (final row in slide.rows) _RoadPreviewRow(data: row),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(
          slide.description,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _RoadPreviewRow extends StatelessWidget {
  const _RoadPreviewRow({required this.data});

  final _PreviewRowData data;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: CompanionColors.muted),
          ),
        ),
        const SizedBox(width: 8),
        CompanionTag(
          backgroundColor: data.tagBackground,
          foregroundColor: data.tagColor,
          label: data.tag,
        ),
      ],
    ),
  );
}

class _CarouselDot extends StatelessWidget {
  const _CarouselDot({
    required this.active,
    required this.index,
    required this.onTap,
  });

  final bool active;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${index + 1}번 소개 보기',
    selected: active,
    child: InkResponse(
      key: ValueKey('login-carousel-dot-$index'),
      onTap: onTap,
      radius: 20,
      child: SizedBox.square(
        dimension: 30,
        child: Center(
          child: AnimatedContainer(
            key: ValueKey(
              'login-carousel-dot-$index-${active ? 'active' : 'inactive'}',
            ),
            width: active ? 18 : 6,
            height: 6,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: active ? CompanionColors.coral : CompanionColors.creamLine,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    ),
  );
}

class _KakaoLoginButton extends StatelessWidget {
  const _KakaoLoginButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _SocialLoginButton(
    key: const ValueKey('login-button-kakao'),
    semanticLabel: '카카오로 로그인',
    label: '카카오로 로그인',
    backgroundColor: const Color(0xFFFEE500),
    borderColor: Colors.transparent,
    foregroundColor: const Color(0xD9000000),
    icon: const _KakaoLoginSymbol(),
    onPressed: onPressed,
  );
}

class _KakaoLoginSymbol extends StatelessWidget {
  const _KakaoLoginSymbol();

  static const _sourceButtonWidth = 600.0;
  static const _sourceButtonHeight = 90.0;
  static const _renderedButtonHeight = 50.0;
  static const _scale = _renderedButtonHeight / _sourceButtonHeight;

  @override
  Widget build(BuildContext context) => ClipRect(
    key: const ValueKey('login-button-kakao-icon'),
    clipBehavior: Clip.hardEdge,
    child: SizedBox.square(
      dimension: 24,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: _sourceButtonWidth * _scale,
        maxWidth: _sourceButtonWidth * _scale,
        minHeight: _renderedButtonHeight,
        maxHeight: _renderedButtonHeight,
        child: Transform.translate(
          // Preserve the official 600×90 artwork at a 50px-high scale.
          // This 24px viewport exposes its untouched x≈29–64/y≈28–61 symbol.
          offset: const Offset(-14, -13),
          child: Image.asset(
            'assets/brand/kakao-login-large-wide.png',
            width: _sourceButtonWidth * _scale,
            height: _renderedButtonHeight,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
        ),
      ),
    ),
  );
}

class _GoogleLoginButton extends StatelessWidget {
  const _GoogleLoginButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _SocialLoginButton(
    key: const ValueKey('login-button-google'),
    semanticLabel: '구글로 로그인',
    label: '구글로 로그인',
    backgroundColor: CompanionColors.white,
    borderColor: const Color(0xFF747775),
    foregroundColor: const Color(0xFF1F1F1F),
    icon: SizedBox.square(
      key: const ValueKey('login-button-google-icon'),
      dimension: 24,
      child: Center(
        child: Image.asset(
          'assets/brand/google-g.png',
          width: 20,
          height: 20,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
    ),
    onPressed: onPressed,
  );
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.semanticLabel,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String semanticLabel;
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    excludeSemantics: true,
    label: semanticLabel,
    child: SizedBox(
      height: 50,
      width: double.infinity,
      child: Material(
        key: ValueKey('$semanticLabel-surface'),
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          overlayColor: companionButtonOverlayColor,
          splashFactory: NoSplash.splashFactory,
          child: Padding(
            key: ValueKey('$semanticLabel-content'),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                    ),
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
