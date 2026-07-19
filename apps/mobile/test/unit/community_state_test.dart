import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_mobile/ui/community_state.dart';

void main() {
  group('Describe CommunityPostsController.addPost', () {
    group('Context 사진이 첨부된 커뮤니티 글을 등록한 경우', () {
      test('It 상황·본문·사진을 새 게시글에 보존한다', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final originalImageBytes = Uint8List.fromList([1, 2, 3, 4]);

        container
            .read(communityPostsProvider.notifier)
            .addPost(
              author: '용봉이',
              body: '경사로 앞에 임시 적치물이 있어요.',
              imageBytes: originalImageBytes,
              initial: '용',
              situation: '주의 필요',
            );

        final post = container.read(communityPostsProvider).first;
        expect(post.body, '경사로 앞에 임시 적치물이 있어요.');
        expect(post.situation, '주의 필요');
        expect(post.imageBytes, [1, 2, 3, 4]);
        expect(identical(post.imageBytes, originalImageBytes), isFalse);

        originalImageBytes[0] = 99;
        expect(post.imageBytes, [1, 2, 3, 4]);
      });
    });

    group('Context 사진이 첨부된 글에 확인 반응을 남긴 경우', () {
      test('It 확인 수를 갱신하면서 상황·본문·사진을 유지한다', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final controller = container.read(communityPostsProvider.notifier);

        controller.addPost(
          author: '용봉이',
          body: '보도블록이 들떠 있어요.',
          imageBytes: Uint8List.fromList([8, 6, 4, 2]),
          initial: '용',
          situation: '파손됨',
        );
        final postId = container.read(communityPostsProvider).first.id;

        controller.confirm(postId);

        final confirmedPost = container
            .read(communityPostsProvider)
            .firstWhere((post) => post.id == postId);
        expect(confirmedPost.confirmations, 1);
        expect(confirmedPost.body, '보도블록이 들떠 있어요.');
        expect(confirmedPost.situation, '파손됨');
        expect(confirmedPost.imageBytes, [8, 6, 4, 2]);
      });
    });
  });
}
