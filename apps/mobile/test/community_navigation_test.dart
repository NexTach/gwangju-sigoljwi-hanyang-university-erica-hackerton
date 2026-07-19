import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:road_dna_mobile/screens/community_detail_screen.dart';
import 'package:road_dna_mobile/screens/community_screen.dart';
import 'package:road_dna_mobile/ui/community_state.dart';
import 'package:road_dna_mobile/ui/companion_theme.dart';

void main() {
  group('Describe 커뮤니티 게시글 탐색', () {
    group('Context 사진이 첨부된 게시글을 목록에서 여는 경우', () {
      testWidgets('It 목록에는 사진을 숨기고 상세 화면에서만 보여준다', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(430, 932);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        addTearDown(container.dispose);
        container
            .read(communityPostsProvider.notifier)
            .addPost(
              author: '용봉이',
              body: '사진으로 확인한 보도블록 파손 구간이에요.',
              imageBytes: base64Decode(_onePixelPng),
              initial: '용',
              situation: '파손됨',
            );
        final router = GoRouter(
          initialLocation: '/community',
          routes: [
            GoRoute(
              path: '/community',
              builder: (context, state) => const CommunityScreen(),
            ),
            GoRoute(
              path: '/community/:id',
              builder: (context, state) => CommunityDetailScreen(
                postId: int.parse(state.pathParameters['id']!),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              theme: companionTheme(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final postBody = find.text('사진으로 확인한 보도블록 파손 구간이에요.');
        expect(postBody, findsOneWidget);
        expect(find.byType(Image), findsNothing);

        await tester.ensureVisible(postBody);
        await tester.pumpAndSettle();
        final postCardTapTarget = find.ancestor(
          of: postBody,
          matching: find.byType(InkWell),
        );
        expect(postCardTapTarget, findsOneWidget);

        await tester.tap(postCardTapTarget);
        await tester.pumpAndSettle();

        expect(find.text('파손됨'), findsOneWidget);
        expect(find.text('현장 사진'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        expect(find.text('사진으로 확인한 보도블록 파손 구간이에요.'), findsOneWidget);
      });
    });
  });
}

const _onePixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
