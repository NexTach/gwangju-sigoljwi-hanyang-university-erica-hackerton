import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CommunityPostStatus { needsConfirmation, confirmed }

enum CommunityAvatarTone { amber, green, neutral }

@immutable
class CommunityPost {
  const CommunityPost({
    required this.avatarTone,
    required this.body,
    required this.confirmations,
    required this.id,
    required this.initial,
    required this.isInNeighborhood,
    required this.location,
    required this.name,
    required this.roadSegmentId,
    required this.status,
    required this.time,
    this.situation,
  });

  final CommunityAvatarTone avatarTone;
  final String body;
  final int confirmations;
  final int id;
  final String initial;
  final bool isInNeighborhood;
  final String location;
  final String name;
  final String roadSegmentId;
  final CommunityPostStatus status;
  final String time;
  final String? situation;

  CommunityPost copyWith({int? confirmations, CommunityPostStatus? status}) =>
      CommunityPost(
        avatarTone: avatarTone,
        body: body,
        confirmations: confirmations ?? this.confirmations,
        id: id,
        initial: initial,
        isInNeighborhood: isInNeighborhood,
        location: location,
        name: name,
        roadSegmentId: roadSegmentId,
        situation: situation,
        status: status ?? this.status,
        time: time,
      );
}

class CommunityPostsController extends Notifier<List<CommunityPost>> {
  var _nextId = 5;

  @override
  List<CommunityPost> build() {
    _nextId = 5;
    return const [
      CommunityPost(
        avatarTone: CommunityAvatarTone.amber,
        body: '이 앞 연석에 경사로가 없어서 휠체어로 지나가기 어려워요. 다른 분들도 확인해주세요.',
        confirmations: 3,
        id: 1,
        initial: '지',
        isInNeighborhood: true,
        location: '반룡로',
        name: '지은님',
        roadSegmentId: '10000000-0000-4000-8000-000000000132',
        status: CommunityPostStatus.needsConfirmation,
        time: '12분 전',
      ),
      CommunityPost(
        avatarTone: CommunityAvatarTone.green,
        body: '보수 공사가 끝나서 이제 평탄해졌어요! 안심하고 지나가셔도 됩니다.',
        confirmations: 8,
        id: 2,
        initial: '민',
        isInNeighborhood: false,
        location: '고운로',
        name: '민준님',
        roadSegmentId: '10000000-0000-4000-8000-000000000245',
        status: CommunityPostStatus.confirmed,
        time: '1시간 전',
      ),
      CommunityPost(
        avatarTone: CommunityAvatarTone.neutral,
        body: '전남대 후문 쪽 인도가 넓고 평평해서 유모차 끌기 좋아요.',
        confirmations: 12,
        id: 3,
        initial: '서',
        isInNeighborhood: true,
        location: '민주대로',
        name: '서연님',
        roadSegmentId: '10000000-0000-4000-8000-000000000101',
        status: CommunityPostStatus.confirmed,
        time: '3시간 전',
      ),
      CommunityPost(
        avatarTone: CommunityAvatarTone.amber,
        body: '공사 구간이 아직 남아있어요. 우회하는 게 좋을 것 같아요.',
        confirmations: 5,
        id: 4,
        initial: '태',
        isInNeighborhood: false,
        location: '설죽로202번길',
        name: '태호님',
        roadSegmentId: '10000000-0000-4000-8000-000000000204',
        status: CommunityPostStatus.needsConfirmation,
        time: '어제',
      ),
    ];
  }

  void addPost({
    required String author,
    required String body,
    required String initial,
    required String situation,
  }) {
    final normalizedBody = body.trim();
    if (normalizedBody.isEmpty) return;

    final isResolved = situation == '개선됨';
    state = [
      CommunityPost(
        avatarTone: isResolved
            ? CommunityAvatarTone.green
            : CommunityAvatarTone.amber,
        body: normalizedBody,
        confirmations: 0,
        id: _nextId++,
        initial: initial,
        isInNeighborhood: true,
        location: '반룡로',
        name: author,
        roadSegmentId: '10000000-0000-4000-8000-000000000132',
        situation: situation,
        status: isResolved
            ? CommunityPostStatus.confirmed
            : CommunityPostStatus.needsConfirmation,
        time: '방금 전',
      ),
      ...state,
    ];
  }

  void confirm(int id) {
    state = [
      for (final post in state)
        if (post.id == id)
          post.copyWith(
            confirmations: post.confirmations + 1,
            status: post.confirmations + 1 >= 6
                ? CommunityPostStatus.confirmed
                : post.status,
          )
        else
          post,
    ];
  }
}

final communityPostsProvider =
    NotifierProvider<CommunityPostsController, List<CommunityPost>>(
      CommunityPostsController.new,
    );
