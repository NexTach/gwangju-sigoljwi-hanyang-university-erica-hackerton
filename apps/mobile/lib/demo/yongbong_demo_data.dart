import '../core/models.dart';

/// A single, internally consistent demo scenario around Yongbong-dong,
/// Buk-gu, Gwangju.
///
/// Keeps the app's seeded roads, routes and GPS trace in one neighborhood.
abstract final class YongbongDemoData {
  static const areaLabel = '광주 북구 용봉동 · 전남대 일대';
  static const routeDisclaimer = '경로 상태는 달라질 수 있으니 이동 중 주변을 확인해 주세요.';

  static const centerLatitude = 35.1788215;
  static const centerLongitude = 126.9005050;
  static const originLatitude = 35.177235;
  static const originLongitude = 126.899021;
  static const destinationLatitude = 35.181894;
  static const destinationLongitude = 126.899271;

  static const minjuRoadId = '10000000-0000-4000-8000-000000000101';
  static const banryongRoadId = '10000000-0000-4000-8000-000000000132';
  static const seoljuk202RoadId = '10000000-0000-4000-8000-000000000204';
  static const gounRoadId = '10000000-0000-4000-8000-000000000245';
  static const seoljuk217RoadId = '10000000-0000-4000-8000-000000000217';
  static const banryong41RoadId = '10000000-0000-4000-8000-000000000241';
  static const banryong27RoadId = '10000000-0000-4000-8000-000000000227';
  static const yongju30RoadId = '10000000-0000-4000-8000-000000000230';

  /// Foot route captured from the OSM road graph on 2026-07-19.
  ///
  /// 설죽로202번길 → 반룡로18번길 → 반룡로17번길 → 용주로 → 고운로
  static const fastestRoute = <({double latitude, double longitude})>[
    (latitude: 35.177235, longitude: 126.899021),
    (latitude: 35.177410, longitude: 126.899011),
    (latitude: 35.177342, longitude: 126.899360),
    (latitude: 35.177852, longitude: 126.899513),
    (latitude: 35.178306, longitude: 126.899651),
    (latitude: 35.178784, longitude: 126.899788),
    (latitude: 35.179274, longitude: 126.899934),
    (latitude: 35.179789, longitude: 126.900076),
    (latitude: 35.180261, longitude: 126.900206),
    (latitude: 35.180786, longitude: 126.900351),
    (latitude: 35.181263, longitude: 126.900096),
    (latitude: 35.181334, longitude: 126.900259),
    (latitude: 35.181706, longitude: 126.900067),
    (latitude: 35.182098, longitude: 126.899865),
    (latitude: 35.181894, longitude: 126.899271),
  ];

  /// Road-following alternative via the longer, high-scoring 고운로 section.
  static const accessibleRoute = <({double latitude, double longitude})>[
    (latitude: 35.177235, longitude: 126.899021),
    (latitude: 35.177410, longitude: 126.899011),
    (latitude: 35.177342, longitude: 126.899360),
    (latitude: 35.177852, longitude: 126.899513),
    (latitude: 35.178306, longitude: 126.899651),
    (latitude: 35.178784, longitude: 126.899788),
    (latitude: 35.179274, longitude: 126.899934),
    (latitude: 35.179789, longitude: 126.900076),
    (latitude: 35.180261, longitude: 126.900206),
    (latitude: 35.180786, longitude: 126.900351),
    (latitude: 35.180824, longitude: 126.900445),
    (latitude: 35.181270, longitude: 126.901541),
    (latitude: 35.181749, longitude: 126.901313),
    (latitude: 35.182124, longitude: 126.901131),
    (latitude: 35.182473, longitude: 126.900953),
    (latitude: 35.182689, longitude: 126.901582),
    (latitude: 35.182473, longitude: 126.900953),
    (latitude: 35.182098, longitude: 126.899865),
    (latitude: 35.181894, longitude: 126.899271),
  ];

  /// Two OSM-foot routes west of the detected Banryong/Seoljuk barriers.
  ///
  /// These were captured with explicit waypoints on 설죽로 and
  /// 설죽로217번길. They are complete router geometries, not translated
  /// versions of the default route.
  static const avoidedFastestRoute = <({double latitude, double longitude})>[
    (latitude: 35.177235, longitude: 126.899021),
    (latitude: 35.177410, longitude: 126.899011),
    (latitude: 35.177448, longitude: 126.898816),
    (latitude: 35.177573, longitude: 126.898156),
    (latitude: 35.177700, longitude: 126.897516),
    (latitude: 35.177940, longitude: 126.897586),
    (latitude: 35.178550, longitude: 126.897766),
    (latitude: 35.178576, longitude: 126.897626),
    (latitude: 35.178688, longitude: 126.897659),
    (latitude: 35.179093, longitude: 126.897783),
    (latitude: 35.179206, longitude: 126.897815),
    (latitude: 35.179518, longitude: 126.897903),
    (latitude: 35.179650, longitude: 126.897940),
    (latitude: 35.179787, longitude: 126.897989),
    (latitude: 35.180490, longitude: 126.898240),
    (latitude: 35.181008, longitude: 126.898328),
    (latitude: 35.181211, longitude: 126.898348),
    (latitude: 35.181486, longitude: 126.898374),
    (latitude: 35.181591, longitude: 126.898384),
    (latitude: 35.181810, longitude: 126.899024),
    (latitude: 35.181894, longitude: 126.899271),
  ];

  static const avoidedAccessibleRoute = <({double latitude, double longitude})>[
    (latitude: 35.177235, longitude: 126.899021),
    (latitude: 35.177410, longitude: 126.899011),
    (latitude: 35.177448, longitude: 126.898816),
    (latitude: 35.177573, longitude: 126.898156),
    (latitude: 35.177700, longitude: 126.897516),
    (latitude: 35.177940, longitude: 126.897586),
    (latitude: 35.177973, longitude: 126.897442),
    (latitude: 35.178009, longitude: 126.897287),
    (latitude: 35.178112, longitude: 126.897300),
    (latitude: 35.178172, longitude: 126.897315),
    (latitude: 35.178226, longitude: 126.897322),
    (latitude: 35.178277, longitude: 126.897257),
    (latitude: 35.178314, longitude: 126.897169),
    (latitude: 35.178459, longitude: 126.897206),
    (latitude: 35.178466, longitude: 126.897073),
    (latitude: 35.178756, longitude: 126.897089),
    (latitude: 35.179123, longitude: 126.897110),
    (latitude: 35.179141, longitude: 126.896634),
    (latitude: 35.179505, longitude: 126.896651),
    (latitude: 35.179820, longitude: 126.896666),
    (latitude: 35.179808, longitude: 126.897148),
    (latitude: 35.180551, longitude: 126.897208),
    (latitude: 35.181049, longitude: 126.897245),
    (latitude: 35.181031, longitude: 126.897716),
    (latitude: 35.181008, longitude: 126.898328),
    (latitude: 35.181211, longitude: 126.898348),
    (latitude: 35.181486, longitude: 126.898374),
    (latitude: 35.181591, longitude: 126.898384),
    (latitude: 35.181810, longitude: 126.899024),
    (latitude: 35.181894, longitude: 126.899271),
  ];

  /// Exact OSM foot-router fixtures from the common demo origin to each
  /// tappable nearby-road destination.
  static const minjuTargetRoute = <({double latitude, double longitude})>[
    (latitude: 35.177235, longitude: 126.899021),
    (latitude: 35.176767, longitude: 126.899048),
    (latitude: 35.176785, longitude: 126.899349),
    (latitude: 35.176794, longitude: 126.899433),
    (latitude: 35.176786, longitude: 126.899436),
    (latitude: 35.176747, longitude: 126.899446),
    (latitude: 35.176754, longitude: 126.899501),
    (latitude: 35.176737, longitude: 126.899574),
    (latitude: 35.176626, longitude: 126.899712),
    (latitude: 35.176601, longitude: 126.899743),
    (latitude: 35.176574, longitude: 126.899777),
    (latitude: 35.176644, longitude: 126.899852),
    (latitude: 35.176658, longitude: 126.900378),
    (latitude: 35.176672, longitude: 126.900432),
    (latitude: 35.176688, longitude: 126.900640),
    (latitude: 35.176708, longitude: 126.900771),
    (latitude: 35.176545, longitude: 126.900755),
    (latitude: 35.176458, longitude: 126.900900),
    (latitude: 35.176323, longitude: 126.900991),
    (latitude: 35.176418, longitude: 126.901311),
    (latitude: 35.176421, longitude: 126.901494),
    (latitude: 35.176392, longitude: 126.901664),
    (latitude: 35.176257, longitude: 126.901935),
    (latitude: 35.176217, longitude: 126.902017),
    (latitude: 35.176262, longitude: 126.902031),
    (latitude: 35.176251, longitude: 126.902095),
    (latitude: 35.176242, longitude: 126.902148),
    (latitude: 35.176183, longitude: 126.902153),
    (latitude: 35.176199, longitude: 126.902343),
    (latitude: 35.176227, longitude: 126.902395),
    (latitude: 35.176259, longitude: 126.902586),
    (latitude: 35.176287, longitude: 126.902721),
    (latitude: 35.176267, longitude: 126.902885),
    (latitude: 35.176242, longitude: 126.902991),
    (latitude: 35.176139, longitude: 126.903046),
    (latitude: 35.176079, longitude: 126.903089),
    (latitude: 35.176094, longitude: 126.903159),
    (latitude: 35.176122, longitude: 126.903270),
    (latitude: 35.176136, longitude: 126.903320),
    (latitude: 35.176087, longitude: 126.903372),
    (latitude: 35.176045, longitude: 126.903516),
    (latitude: 35.175996, longitude: 126.903739),
    (latitude: 35.175972, longitude: 126.903891),
    (latitude: 35.175948, longitude: 126.903961),
    (latitude: 35.175905, longitude: 126.904022),
    (latitude: 35.175907, longitude: 126.904136),
    (latitude: 35.175868, longitude: 126.904155),
    (latitude: 35.175840, longitude: 126.904185),
    (latitude: 35.175885, longitude: 126.904253),
    (latitude: 35.175919, longitude: 126.904293),
    (latitude: 35.176005, longitude: 126.904348),
    (latitude: 35.176063, longitude: 126.904380),
    (latitude: 35.175568, longitude: 126.905835),
    (latitude: 35.175547, longitude: 126.905929),
    (latitude: 35.175699, longitude: 126.905981),
  ];

  static const banryongTargetRoute = <({double latitude, double longitude})>[
    (latitude: 35.177235, longitude: 126.899021),
    (latitude: 35.177410, longitude: 126.899011),
    (latitude: 35.177342, longitude: 126.899360),
    (latitude: 35.177105, longitude: 126.900579),
    (latitude: 35.177107, longitude: 126.900715),
    (latitude: 35.177233, longitude: 126.901388),
    (latitude: 35.177383, longitude: 126.902133),
    (latitude: 35.177803, longitude: 126.902245),
    (latitude: 35.178262, longitude: 126.902367),
    (latitude: 35.178758, longitude: 126.902511),
    (latitude: 35.178682, longitude: 126.902884),
    (latitude: 35.178641, longitude: 126.903091),
    (latitude: 35.178603, longitude: 126.903276),
  ];

  static const seoljuk202TargetRoute = <({double latitude, double longitude})>[
    (latitude: 35.177235, longitude: 126.899021),
    (latitude: 35.177410, longitude: 126.899011),
    (latitude: 35.177342, longitude: 126.899360),
    (latitude: 35.177105, longitude: 126.900579),
    (latitude: 35.177107, longitude: 126.900715),
    (latitude: 35.177180, longitude: 126.901104),
  ];

  static const gounTargetRoute = <({double latitude, double longitude})>[
    (latitude: 35.177235, longitude: 126.899021),
    (latitude: 35.177410, longitude: 126.899011),
    (latitude: 35.177342, longitude: 126.899360),
    (latitude: 35.177852, longitude: 126.899513),
    (latitude: 35.178306, longitude: 126.899651),
    (latitude: 35.178784, longitude: 126.899788),
    (latitude: 35.179274, longitude: 126.899934),
    (latitude: 35.179789, longitude: 126.900076),
    (latitude: 35.180261, longitude: 126.900206),
    (latitude: 35.180786, longitude: 126.900351),
    (latitude: 35.180824, longitude: 126.900445),
    (latitude: 35.181270, longitude: 126.901541),
    (latitude: 35.181749, longitude: 126.901313),
    (latitude: 35.182124, longitude: 126.901131),
    (latitude: 35.182473, longitude: 126.900953),
    (latitude: 35.182689, longitude: 126.901582),
  ];

  static const seoljuk217TargetRoute = <({double latitude, double longitude})>[
    (latitude: 35.177235, longitude: 126.899021),
    (latitude: 35.177410, longitude: 126.899011),
    (latitude: 35.177448, longitude: 126.898816),
    (latitude: 35.177573, longitude: 126.898156),
    (latitude: 35.177700, longitude: 126.897516),
    (latitude: 35.177940, longitude: 126.897586),
    (latitude: 35.177973, longitude: 126.897442),
    (latitude: 35.178009, longitude: 126.897287),
    (latitude: 35.178112, longitude: 126.897300),
    (latitude: 35.178172, longitude: 126.897315),
    (latitude: 35.178226, longitude: 126.897322),
    (latitude: 35.178277, longitude: 126.897257),
    (latitude: 35.178314, longitude: 126.897169),
    (latitude: 35.178459, longitude: 126.897206),
    (latitude: 35.178466, longitude: 126.897073),
    (latitude: 35.178756, longitude: 126.897089),
    (latitude: 35.179123, longitude: 126.897110),
    (latitude: 35.179141, longitude: 126.896634),
    (latitude: 35.179505, longitude: 126.896651),
  ];

  static const banryong41TargetRoute = <({double latitude, double longitude})>[
    (latitude: 35.177235, longitude: 126.899021),
    (latitude: 35.177410, longitude: 126.899011),
    (latitude: 35.177342, longitude: 126.899360),
    (latitude: 35.177852, longitude: 126.899513),
    (latitude: 35.178306, longitude: 126.899651),
    (latitude: 35.178784, longitude: 126.899788),
    (latitude: 35.179274, longitude: 126.899934),
    (latitude: 35.179789, longitude: 126.900076),
    (latitude: 35.179681, longitude: 126.900641),
    (latitude: 35.179558, longitude: 126.901275),
    (latitude: 35.179494, longitude: 126.901650),
    (latitude: 35.179434, longitude: 126.901966),
    (latitude: 35.179426, longitude: 126.902012),
    (latitude: 35.179374, longitude: 126.902292),
  ];

  static const banryong27TargetRoute = <({double latitude, double longitude})>[
    (latitude: 35.177235, longitude: 126.899021),
    (latitude: 35.177410, longitude: 126.899011),
    (latitude: 35.177342, longitude: 126.899360),
    (latitude: 35.177852, longitude: 126.899513),
    (latitude: 35.178306, longitude: 126.899651),
    (latitude: 35.178784, longitude: 126.899788),
    (latitude: 35.179274, longitude: 126.899934),
    (latitude: 35.179789, longitude: 126.900076),
    (latitude: 35.180261, longitude: 126.900206),
    (latitude: 35.180029, longitude: 126.901398),
    (latitude: 35.180497, longitude: 126.901536),
  ];

  static const yongju30TargetRoute = <({double latitude, double longitude})>[
    (latitude: 35.177235, longitude: 126.899021),
    (latitude: 35.177410, longitude: 126.899011),
    (latitude: 35.177342, longitude: 126.899360),
    (latitude: 35.177852, longitude: 126.899513),
    (latitude: 35.178306, longitude: 126.899651),
    (latitude: 35.178784, longitude: 126.899788),
    (latitude: 35.179274, longitude: 126.899934),
    (latitude: 35.179789, longitude: 126.900076),
    (latitude: 35.180261, longitude: 126.900206),
    (latitude: 35.180786, longitude: 126.900351),
    (latitude: 35.180824, longitude: 126.900445),
    (latitude: 35.181270, longitude: 126.901541),
    (latitude: 35.181749, longitude: 126.901313),
    (latitude: 35.182124, longitude: 126.901131),
    (latitude: 35.182473, longitude: 126.900953),
  ];

  /// Follows the accessible route in both directions so the closing segment
  /// never cuts across a building or an unmapped part of the road network.
  static const demoGpsPath = <({double latitude, double longitude})>[
    ...accessibleRoute,
    (latitude: 35.182098, longitude: 126.899865),
    (latitude: 35.182473, longitude: 126.900953),
    (latitude: 35.182689, longitude: 126.901582),
    (latitude: 35.182473, longitude: 126.900953),
    (latitude: 35.182124, longitude: 126.901131),
    (latitude: 35.181749, longitude: 126.901313),
    (latitude: 35.181270, longitude: 126.901541),
    (latitude: 35.180824, longitude: 126.900445),
    (latitude: 35.180786, longitude: 126.900351),
    (latitude: 35.180261, longitude: 126.900206),
    (latitude: 35.179789, longitude: 126.900076),
    (latitude: 35.179274, longitude: 126.899934),
    (latitude: 35.178784, longitude: 126.899788),
    (latitude: 35.178306, longitude: 126.899651),
    (latitude: 35.177852, longitude: 126.899513),
    (latitude: 35.177342, longitude: 126.899360),
    (latitude: 35.177410, longitude: 126.899011),
    (latitude: 35.177235, longitude: 126.899021),
  ];

  static List<RoadMapItem> roads(MovementType movementType) {
    final updatedAt = DateTime.now().toUtc();
    const seeds =
        <
          ({
            double confidence,
            int events,
            double latitude,
            double longitude,
            String name,
            String segmentId,
            List<int> scores,
          })
        >[
          (
            confidence: 0.46,
            events: 8,
            latitude: 35.1757018,
            longitude: 126.9059674,
            name: '민주대로',
            segmentId: minjuRoadId,
            scores: [86, 85, 84],
          ),
          (
            confidence: 0.65,
            events: 16,
            latitude: 35.1785726,
            longitude: 126.9032665,
            name: '반룡로',
            segmentId: banryongRoadId,
            scores: [39, 36, 34],
          ),
          (
            confidence: 0.555,
            events: 12,
            latitude: 35.177180,
            longitude: 126.901104,
            name: '설죽로202번길',
            segmentId: seoljuk202RoadId,
            scores: [59, 57, 55],
          ),
          (
            confidence: 0.46,
            events: 8,
            latitude: 35.1826485,
            longitude: 126.9016026,
            name: '고운로',
            segmentId: gounRoadId,
            scores: [83, 82, 80],
          ),
          (
            confidence: 0.7512,
            events: 21,
            latitude: 35.179505,
            longitude: 126.896651,
            name: '설죽로217번길',
            segmentId: seoljuk217RoadId,
            scores: [92, 90, 91],
          ),
          (
            confidence: 0.6025,
            events: 14,
            latitude: 35.179374,
            longitude: 126.902292,
            name: '반룡로41번길',
            segmentId: banryong41RoadId,
            scores: [76, 73, 75],
          ),
          (
            confidence: 0.6975,
            events: 18,
            latitude: 35.180497,
            longitude: 126.901536,
            name: '반룡로27번길',
            segmentId: banryong27RoadId,
            scores: [48, 45, 51],
          ),
          (
            confidence: 0.6737,
            events: 17,
            latitude: 35.182473,
            longitude: 126.900953,
            name: '용주로30번길',
            segmentId: yongju30RoadId,
            scores: [84, 81, 83],
          ),
        ];

    return [
      for (final (index, seed) in seeds.indexed)
        RoadMapItem(
          confidence: seed.confidence,
          eventCount: seed.events,
          grade: gradeForScore(seed.scores[movementType.index]),
          latitude: seed.latitude,
          longitude: seed.longitude,
          movementType: movementType,
          roadName: seed.name,
          roadSegmentId: seed.segmentId,
          score: seed.scores[movementType.index],
          updatedAt: updatedAt.subtract(Duration(minutes: index * 7)),
        ),
    ];
  }

  static const RouteComparison routeComparison = RouteComparison(
    disclaimer: routeDisclaimer,
    routes: [
      RouteOption(
        accessibilityScore: 43,
        coordinates: fastestRoute,
        distance: 670,
        duration: 536,
        source: 'DISTANCE_ESTIMATE',
        type: RouteType.fastest,
      ),
      RouteOption(
        accessibilityScore: 91,
        coordinates: accessibleRoute,
        distance: 1000,
        duration: 800,
        source: 'ROAD_DNA',
        type: RouteType.accessible,
      ),
    ],
  );

  static const RouteComparison avoidedRouteComparison = RouteComparison(
    disclaimer: routeDisclaimer,
    routes: [
      RouteOption(
        accessibilityScore: 78,
        coordinates: avoidedFastestRoute,
        distance: 700,
        duration: 560,
        source: 'OSM_FOOT_AVOIDANCE',
        type: RouteType.fastest,
      ),
      RouteOption(
        accessibilityScore: 94,
        coordinates: avoidedAccessibleRoute,
        distance: 910,
        duration: 728,
        source: 'ROAD_DNA_AVOIDANCE',
        type: RouteType.accessible,
      ),
    ],
  );

  /// Real OSM road portions used by the nearby map. Every point is taken from
  /// one of the target-route fixtures above.
  static const roadGeometries =
      <String, List<({double latitude, double longitude})>>{
        minjuRoadId: [
          (latitude: 35.176063, longitude: 126.904380),
          (latitude: 35.175568, longitude: 126.905835),
          (latitude: 35.175547, longitude: 126.905929),
          (latitude: 35.175699, longitude: 126.905981),
        ],
        banryongRoadId: [
          (latitude: 35.178262, longitude: 126.902367),
          (latitude: 35.178758, longitude: 126.902511),
          (latitude: 35.178682, longitude: 126.902884),
          (latitude: 35.178641, longitude: 126.903091),
          (latitude: 35.178603, longitude: 126.903276),
        ],
        seoljuk202RoadId: [
          (latitude: 35.177342, longitude: 126.899360),
          (latitude: 35.177105, longitude: 126.900579),
          (latitude: 35.177107, longitude: 126.900715),
          (latitude: 35.177180, longitude: 126.901104),
        ],
        gounRoadId: [
          (latitude: 35.180824, longitude: 126.900445),
          (latitude: 35.181270, longitude: 126.901541),
          (latitude: 35.181749, longitude: 126.901313),
          (latitude: 35.182124, longitude: 126.901131),
          (latitude: 35.182473, longitude: 126.900953),
          (latitude: 35.182689, longitude: 126.901582),
        ],
        seoljuk217RoadId: [
          (latitude: 35.178459, longitude: 126.897206),
          (latitude: 35.178466, longitude: 126.897073),
          (latitude: 35.178756, longitude: 126.897089),
          (latitude: 35.179123, longitude: 126.897110),
          (latitude: 35.179141, longitude: 126.896634),
          (latitude: 35.179505, longitude: 126.896651),
        ],
        banryong41RoadId: [
          (latitude: 35.179789, longitude: 126.900076),
          (latitude: 35.179681, longitude: 126.900641),
          (latitude: 35.179558, longitude: 126.901275),
          (latitude: 35.179494, longitude: 126.901650),
          (latitude: 35.179434, longitude: 126.901966),
          (latitude: 35.179426, longitude: 126.902012),
          (latitude: 35.179374, longitude: 126.902292),
        ],
        banryong27RoadId: [
          (latitude: 35.180261, longitude: 126.900206),
          (latitude: 35.180029, longitude: 126.901398),
          (latitude: 35.180497, longitude: 126.901536),
        ],
        yongju30RoadId: [
          (latitude: 35.180824, longitude: 126.900445),
          (latitude: 35.181270, longitude: 126.901541),
          (latitude: 35.181749, longitude: 126.901313),
          (latitude: 35.182124, longitude: 126.901131),
          (latitude: 35.182473, longitude: 126.900953),
        ],
      };

  static RouteComparison comparisonFor({
    String? avoidedRoadSegmentId,
    String? targetRoadSegmentId,
  }) {
    if (avoidedRoadSegmentId != null) return avoidedRouteComparison;
    final target = targetRoute(targetRoadSegmentId);
    if (target != null) {
      return RouteComparison(disclaimer: routeDisclaimer, routes: [target]);
    }
    return routeComparison;
  }

  static RouteOption? targetRoute(String? roadSegmentId) =>
      switch (roadSegmentId) {
        minjuRoadId => const RouteOption(
          accessibilityScore: 86,
          coordinates: minjuTargetRoute,
          distance: 812,
          duration: 649,
          source: 'OSM_FOOT_TARGET',
          type: RouteType.accessible,
        ),
        banryongRoadId => const RouteOption(
          accessibilityScore: 39,
          coordinates: banryongTargetRoute,
          distance: 540,
          duration: 432,
          source: 'OSM_FOOT_TARGET',
          type: RouteType.accessible,
        ),
        seoljuk202RoadId => const RouteOption(
          accessibilityScore: 59,
          coordinates: seoljuk202TargetRoute,
          distance: 215,
          duration: 172,
          source: 'OSM_FOOT_TARGET',
          type: RouteType.accessible,
        ),
        gounRoadId => const RouteOption(
          accessibilityScore: 83,
          coordinates: gounTargetRoute,
          distance: 772,
          duration: 617,
          source: 'OSM_FOOT_TARGET',
          type: RouteType.accessible,
        ),
        seoljuk217RoadId => const RouteOption(
          accessibilityScore: 92,
          coordinates: seoljuk217TargetRoute,
          distance: 442,
          duration: 354,
          source: 'OSM_FOOT_TARGET',
          type: RouteType.accessible,
        ),
        banryong41RoadId => const RouteOption(
          accessibilityScore: 76,
          coordinates: banryong41TargetRoute,
          distance: 538,
          duration: 431,
          source: 'OSM_FOOT_TARGET',
          type: RouteType.accessible,
        ),
        banryong27RoadId => const RouteOption(
          accessibilityScore: 48,
          coordinates: banryong27TargetRoute,
          distance: 550,
          duration: 440,
          source: 'OSM_FOOT_TARGET',
          type: RouteType.accessible,
        ),
        yongju30RoadId => const RouteOption(
          accessibilityScore: 84,
          coordinates: yongju30TargetRoute,
          distance: 710,
          duration: 568,
          source: 'OSM_FOOT_TARGET',
          type: RouteType.accessible,
        ),
        _ => null,
      };

  static RoadGrade gradeForScore(int score) => switch (score) {
    >= 80 => RoadGrade.good,
    >= 60 => RoadGrade.normal,
    >= 40 => RoadGrade.caution,
    _ => RoadGrade.poor,
  };
}
