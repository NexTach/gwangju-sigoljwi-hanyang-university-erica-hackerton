import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:road_dna_design/road_dna_design.dart';

import '../core/models.dart';
import '../state/tracking_controller.dart';

class RoadMapView extends StatelessWidget {
  const RoadMapView({
    required this.center,
    this.barriers = const [],
    this.currentLocation,
    this.onRoadTap,
    this.roads = const [],
    this.routes = const [],
    this.showAttribution = true,
    this.tileUrlTemplate = const String.fromEnvironment(
      'ROAD_DNA_TILE_URL',
      defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    this.zoom = 16,
    super.key,
  });

  final List<DetectedBarrier> barriers;
  final LatLng center;
  final LocationReading? currentLocation;
  final ValueChanged<RoadMapItem>? onRoadTap;
  final List<RoadMapItem> roads;
  final List<RouteOption> routes;
  final bool showAttribution;
  final String tileUrlTemplate;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final colors = context.rdColors;
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          maxZoom: 19,
          tileProvider: kDebugMode
              ? NetworkTileProvider(
                  cachingProvider: const DisabledMapCachingProvider(),
                )
              : null,
          urlTemplate: tileUrlTemplate,
          userAgentPackageName: 'com.roaddna.mobile',
        ),
        if (roads.isNotEmpty)
          PolylineLayer(
            polylines: roads
                .map(
                  (road) => Polyline(
                    borderColor: colors.surface,
                    borderStrokeWidth: 3,
                    color: road.grade.color(colors),
                    points: [
                      LatLng(
                        road.latitude - 0.000045,
                        road.longitude - 0.00006,
                      ),
                      LatLng(
                        road.latitude + 0.000045,
                        road.longitude + 0.00006,
                      ),
                    ],
                    strokeWidth: 7,
                  ),
                )
                .toList(growable: false),
          ),
        if (routes.isNotEmpty)
          PolylineLayer(
            polylines: routes
                .map(
                  (route) => Polyline(
                    borderColor: colors.surface,
                    borderStrokeWidth: 3,
                    color: route.type == RouteType.accessible
                        ? colors.actionPrimary
                        : colors.contentTertiary,
                    pattern: route.type == RouteType.fastest
                        ? StrokePattern.dashed(segments: const [10, 8])
                        : const StrokePattern.solid(),
                    points: route.coordinates
                        .map(
                          (coordinate) =>
                              LatLng(coordinate.latitude, coordinate.longitude),
                        )
                        .toList(growable: false),
                    strokeWidth: route.type == RouteType.accessible ? 7 : 5,
                  ),
                )
                .toList(growable: false),
          ),
        MarkerLayer(
          markers: [
            for (final road in roads)
              Marker(
                height: RdSize.touchTarget,
                point: LatLng(road.latitude, road.longitude),
                width: RdSize.touchTarget,
                child: Semantics(
                  button: true,
                  label:
                      '${road.roadName}, ${road.score == null ? '데이터 없음' : '${road.score}점'}, ${road.grade.label}',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onRoadTap == null ? null : () => onRoadTap!(road),
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.surface, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 8,
                              color: Color(0x28101318),
                              offset: Offset(0, 3),
                            ),
                          ],
                          color: road.grade.color(colors),
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(dimension: 18),
                      ),
                    ),
                  ),
                ),
              ),
            for (final barrier in barriers)
              Marker(
                height: 44,
                point: LatLng(
                  barrier.location.latitude,
                  barrier.location.longitude,
                ),
                width: 44,
                child: Semantics(
                  label: '이동 충격 후보',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.surface, width: 3),
                      color: colors.statusWarning,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: colors.contentInverse,
                      size: 22,
                    ),
                  ),
                ),
              ),
            if (currentLocation case final location?)
              Marker(
                height: 48,
                point: LatLng(location.latitude, location.longitude),
                width: 48,
                child: Semantics(
                  label: '현재 위치',
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.surface, width: 4),
                        boxShadow: const [
                          BoxShadow(blurRadius: 10, color: Color(0x303563E9)),
                        ],
                        color: colors.actionPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 20),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (showAttribution)
          const RichAttributionWidget(
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          ),
      ],
    );
  }
}
