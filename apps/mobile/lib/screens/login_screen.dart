import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/brand_mark.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';

const _carouselInterval = Duration(milliseconds: 3500);
const _carouselAnimationDuration = Duration(milliseconds: 320);
const _initialCarouselPage = 3000;

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
  late final PageController _pageController;
  Timer? _advanceTimer;
  var _activeIndex = 0;
  var _currentPage = _initialCarouselPage;
  var _disableAnimations = false;
  var _hasSeenForegroundLifecycle = false;
  var _isAppActive = true;
  var _isAnimatingPage = false;
  var _isUserInteracting = false;
  var _wasExplicitlyBackgrounded = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialCarouselPage);
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
    _pageController.dispose();
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
    if (!_isAppActive ||
        _isAnimatingPage ||
        _isUserInteracting ||
        !_pageController.hasClients ||
        !mounted) {
      return;
    }
    _advanceTimer = Timer(_carouselInterval, () {
      _advanceTimer = null;
      _advance();
    });
  }

  void _advance() {
    if (!mounted ||
        !_isAppActive ||
        _isAnimatingPage ||
        _isUserInteracting ||
        !_pageController.hasClients) {
      return;
    }
    _showPhysicalPage(_currentPage + 1);
  }

  void _showPhysicalPage(int targetPage) {
    if (!mounted || !_pageController.hasClients || _isAnimatingPage) return;
    if (targetPage == _currentPage) {
      _scheduleAdvance();
      return;
    }

    _advanceTimer?.cancel();
    _advanceTimer = null;
    _isAnimatingPage = true;
    if (_disableAnimations) {
      _pageController.jumpToPage(targetPage);
      _isAnimatingPage = false;
      _scheduleAdvance();
      return;
    }

    unawaited(
      _pageController
          .animateToPage(
            targetPage,
            duration: _carouselAnimationDuration,
            curve: Curves.easeInOutCubic,
          )
          .whenComplete(() {
            if (!mounted) return;
            _isAnimatingPage = false;
            _scheduleAdvance();
          }),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _advanceTimer?.cancel();
      _advanceTimer = null;
      _isUserInteracting = true;
    } else if (notification is ScrollEndNotification) {
      _isUserInteracting = false;
      if (mounted) _scheduleAdvance();
    }
    return false;
  }

  void _handlePageChanged(int page) {
    _currentPage = page;
    final nextIndex = page % _loginSlides.length;
    if (nextIndex == _activeIndex) return;
    setState(() => _activeIndex = nextIndex);
  }

  void _goToSlide(int targetIndex) {
    if (targetIndex == _activeIndex) {
      _scheduleAdvance();
      return;
    }

    final forwardDelta =
        (targetIndex - _activeIndex + _loginSlides.length) %
        _loginSlides.length;
    final backwardDelta = forwardDelta - _loginSlides.length;
    final delta = forwardDelta <= backwardDelta.abs()
        ? forwardDelta
        : backwardDelta;
    _showPhysicalPage(_currentPage + delta);
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
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _handleScrollNotification,
                        child: PageView.builder(
                          key: const ValueKey('login-carousel-page-view'),
                          controller: _pageController,
                          clipBehavior: Clip.hardEdge,
                          onPageChanged: _handlePageChanged,
                          padEnds: false,
                          physics: const PageScrollPhysics(),
                          itemBuilder: (context, page) {
                            final slideIndex = page % _loginSlides.length;
                            return _LoginCarouselSlide(
                              key: ValueKey('login-carousel-slide-$slideIndex'),
                              slide: _loginSlides[slideIndex],
                            );
                          },
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
