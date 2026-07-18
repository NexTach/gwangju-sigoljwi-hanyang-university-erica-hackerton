import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:road_dna_design/road_dna_design.dart';

import '../core/models.dart';
import '../state/tracking_controller.dart';

const roadDnaFallbackCenter = LatLng(35.1788215, 126.9005050);

class RoadMapView extends StatefulWidget {
  const RoadMapView({
    this.barriers = const [],
    this.center = roadDnaFallbackCenter,
    this.currentLocation,
    this.fitPadding = const EdgeInsets.all(36),
    this.fitToContent = false,
    this.followCurrentLocation = false,
    this.impactPoints = const [],
    this.mapController,
    this.onMapReady,
    this.onRoadTap,
    this.roadGeometries = const {},
    this.roads = const [],
    this.routes = const [],
    this.selectedRoute,
    this.showAttribution = true,
    this.tileProvider,
    this.tileUrlTemplate = const String.fromEnvironment(
      'ROAD_DNA_TILE_URL',
      defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    this.trace = const [],
    this.traceColor,
    this.zoom = 16,
    super.key,
  });

  final List<DetectedBarrier> barriers;
  final LatLng center;
  final LocationReading? currentLocation;
  final EdgeInsets fitPadding;
  final bool fitToContent;
  final bool followCurrentLocation;
  final List<LatLng> impactPoints;
  final MapController? mapController;
  final VoidCallback? onMapReady;
  final ValueChanged<RoadMapItem>? onRoadTap;
  final Map<String, List<LatLng>> roadGeometries;
  final List<RoadMapItem> roads;
  final List<RouteOption> routes;
  final RouteOption? selectedRoute;
  final bool showAttribution;
  final TileProvider? tileProvider;
  final String tileUrlTemplate;
  final List<LatLng> trace;
  final Color? traceColor;
  final double zoom;

  @override
  State<RoadMapView> createState() => _RoadMapViewState();
}

class _RoadMapViewState extends State<RoadMapView> {
  static const _minimumZoom = 12.0;
  static const _maximumZoom = 19.0;
  static const _fitMaximumZoom = 17.0;

  late final MapController _internalMapController;
  final LayerHitNotifier<RoadMapItem> _roadHitNotifier = ValueNotifier(null);
  late final TileProvider _tileProvider;
  bool _mapReady = false;

  MapController get _mapController =>
      widget.mapController ?? _internalMapController;

  @override
  void initState() {
    super.initState();
    _internalMapController = MapController();
    _tileProvider =
        widget.tileProvider ??
        NetworkTileProvider(
          cachingProvider: kDebugMode
              ? const DisabledMapCachingProvider()
              : BuiltInMapCachingProvider.getOrCreateInstance(
                  maxCacheSize: 64 * 1024 * 1024,
                ),
          silenceExceptions: true,
        );
  }

  @override
  void didUpdateWidget(covariant RoadMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mapReady) return;

    final contentChanged = !listEquals(
      _contentPoints(oldWidget),
      _contentPoints(widget),
    );
    if (widget.fitToContent && contentChanged) {
      _scheduleCameraUpdate(_fitContent);
      return;
    }

    final currentLocation = widget.currentLocation;
    final oldLocation = oldWidget.currentLocation;
    final locationChanged =
        currentLocation != null &&
        (oldLocation == null ||
            currentLocation.latitude != oldLocation.latitude ||
            currentLocation.longitude != oldLocation.longitude);
    if (widget.followCurrentLocation && locationChanged) {
      _scheduleCameraUpdate(() => _moveToCurrentLocation(currentLocation));
      return;
    }

    if (widget.center != oldWidget.center) {
      _scheduleCameraUpdate(
        () => _mapController.move(widget.center, _mapController.camera.zoom),
      );
    }
  }

  @override
  void dispose() {
    _roadHitNotifier.dispose();
    _internalMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.rdColors;
    final routePolylines = _routePolylines(colors);
    final roadPolylines = _roadPolylines(colors);
    return FlutterMap(
      key: const ValueKey('road-map'),
      mapController: _mapController,
      options: MapOptions(
        backgroundColor: colors.surfaceSubtle,
        initialCenter: widget.center,
        initialZoom: widget.zoom.clamp(_minimumZoom, _maximumZoom),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        maxZoom: _maximumZoom,
        minZoom: _minimumZoom,
        onMapReady: _handleMapReady,
      ),
      children: [
        TileLayer(
          evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
          keepBuffer: 1,
          maxNativeZoom: 19,
          maxZoom: _maximumZoom,
          minZoom: _minimumZoom,
          panBuffer: 0,
          tileProvider: _tileProvider,
          urlTemplate: widget.tileUrlTemplate,
          userAgentPackageName: 'com.nextach.roaddna.road_dna_mobile',
        ),
        if (widget.currentLocation case final location?)
          CircleLayer(
            key: const ValueKey('current-location-accuracy'),
            circles: [
              CircleMarker(
                borderColor: colors.actionPrimary.withValues(alpha: 0.35),
                borderStrokeWidth: 1,
                color: colors.actionPrimary.withValues(alpha: 0.12),
                point: LatLng(location.latitude, location.longitude),
                radius: location.accuracy.clamp(3, 250).toDouble(),
                useRadiusInMeter: true,
              ),
            ],
          ),
        if (roadPolylines.isNotEmpty)
          GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: widget.onRoadTap == null ? null : _handleRoadPolylineTap,
            child: PolylineLayer<RoadMapItem>(
              key: const ValueKey('road-polylines'),
              hitNotifier: _roadHitNotifier,
              minimumHitbox: RdSize.touchTarget,
              polylines: roadPolylines,
            ),
          ),
        if (routePolylines.isNotEmpty)
          PolylineLayer(
            key: const ValueKey('route-polylines'),
            polylines: routePolylines,
          ),
        if (widget.trace.length >= 2)
          PolylineLayer(
            key: const ValueKey('route-trace'),
            polylines: [
              Polyline(
                borderColor: colors.surface,
                borderStrokeWidth: 3,
                color: widget.traceColor ?? colors.mapGood,
                points: widget.trace,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
                strokeWidth: 7,
              ),
            ],
          ),
        MarkerLayer(
          key: const ValueKey('map-markers'),
          markers: [
            for (final road in widget.roads)
              _roadMarker(colors, road, visible: !_hasRoadGeometry(road)),
            for (final barrier in widget.barriers)
              _impactMarker(
                colors,
                label: '이동 충격 후보',
                point: LatLng(
                  barrier.location.latitude,
                  barrier.location.longitude,
                ),
              ),
            for (final (index, point) in widget.impactPoints.indexed)
              _impactMarker(
                colors,
                label: '기록된 충격 지점 ${index + 1}',
                point: point,
              ),
            ..._endpointMarkers(colors),
            if (widget.currentLocation case final location?)
              Marker(
                height: 48,
                point: LatLng(location.latitude, location.longitude),
                width: 48,
                child: Semantics(
                  key: const ValueKey('current-location-marker'),
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
        if (widget.showAttribution)
          Align(
            key: const ValueKey('openstreetmap-attribution'),
            alignment: Alignment.bottomLeft,
            child: SafeArea(
              minimum: const EdgeInsets.all(3),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: colors.surface.withValues(alpha: 0.88),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    '© OpenStreetMap contributors',
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.contentSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Polyline<RoadMapItem>> _roadPolylines(RdSemanticColors colors) => [
    for (final road in widget.roads)
      if (widget.roadGeometries[road.roadSegmentId] case final points?
          when points.length >= 2)
        Polyline<RoadMapItem>(
          borderColor: colors.surface,
          borderStrokeWidth: 3,
          color: road.grade.color(colors),
          hitValue: road,
          points: points,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
          strokeWidth: 7,
        ),
  ];

  List<Polyline> _routePolylines(RdSemanticColors colors) {
    final selectedRoute = widget.selectedRoute;
    final routes = [
      for (final route in widget.routes)
        if (!identical(route, selectedRoute)) route,
      if (selectedRoute != null && widget.routes.contains(selectedRoute))
        selectedRoute,
    ];
    return [
      for (final route in routes)
        if (route.coordinates.length >= 2)
          Polyline(
            borderColor: colors.surface.withValues(
              alpha: selectedRoute == null || identical(route, selectedRoute)
                  ? 1
                  : 0.7,
            ),
            borderStrokeWidth: 3,
            color:
                (route.type == RouteType.accessible
                        ? colors.mapGood
                        : colors.contentTertiary)
                    .withValues(
                      alpha:
                          selectedRoute == null ||
                              identical(route, selectedRoute)
                          ? 1
                          : 0.52,
                    ),
            pattern: route.type == RouteType.fastest
                ? StrokePattern.dashed(segments: const [10, 8])
                : const StrokePattern.solid(),
            points: [
              for (final coordinate in route.coordinates)
                LatLng(coordinate.latitude, coordinate.longitude),
            ],
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
            strokeWidth:
                (route.type == RouteType.accessible ? 7 : 5) +
                (identical(route, selectedRoute) ? 1.5 : 0),
          ),
    ];
  }

  Marker _roadMarker(
    RdSemanticColors colors,
    RoadMapItem road, {
    required bool visible,
  }) => Marker(
    height: RdSize.touchTarget,
    point: LatLng(road.latitude, road.longitude),
    width: RdSize.touchTarget,
    child: Semantics(
      button: widget.onRoadTap != null,
      label:
          '${road.roadName}, ${road.score == null ? '데이터 없음' : '${road.score}점'}, ${road.grade.label}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onRoadTap == null ? null : () => widget.onRoadTap!(road),
        child: Center(
          child: visible
              ? DecoratedBox(
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
                )
              : const SizedBox.square(dimension: RdSize.touchTarget),
        ),
      ),
    ),
  );

  List<Marker> _endpointMarkers(RdSemanticColors colors) {
    final route = widget.selectedRoute ?? _preferredRoute;
    final routePoints = route == null
        ? const <LatLng>[]
        : [
            for (final coordinate in route.coordinates)
              LatLng(coordinate.latitude, coordinate.longitude),
          ];
    final points = widget.trace.length >= 2 ? widget.trace : routePoints;
    if (points.length < 2) return const [];

    return [
      _endpointMarker(
        colors,
        icon: Icons.trip_origin_rounded,
        label: '출발 지점',
        point: points.first,
      ),
      _endpointMarker(
        colors,
        icon: Icons.flag_rounded,
        label: '도착 지점',
        point: points.last,
      ),
    ];
  }

  Marker _endpointMarker(
    RdSemanticColors colors, {
    required IconData icon,
    required String label,
    required LatLng point,
  }) => Marker(
    height: 38,
    point: point,
    width: 38,
    child: Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colors.surface, width: 3),
          color: colors.contentPrimary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colors.contentInverse, size: 17),
      ),
    ),
  );

  Marker _impactMarker(
    RdSemanticColors colors, {
    required String label,
    required LatLng point,
  }) => Marker(
    height: 44,
    point: point,
    width: 44,
    child: Semantics(
      excludeSemantics: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colors.surface, width: 3),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              color: Color(0x30101318),
              offset: Offset(0, 2),
            ),
          ],
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
  );

  RouteOption? get _preferredRoute {
    for (final route in widget.routes) {
      if (route.type == RouteType.accessible) return route;
    }
    return widget.routes.isEmpty ? null : widget.routes.first;
  }

  bool _hasRoadGeometry(RoadMapItem road) =>
      (widget.roadGeometries[road.roadSegmentId]?.length ?? 0) >= 2;

  void _handleRoadPolylineTap() {
    final hit = _roadHitNotifier.value;
    if (hit == null || hit.hitValues.isEmpty) return;
    widget.onRoadTap?.call(hit.hitValues.first);
  }

  void _handleMapReady() {
    _mapReady = true;
    widget.onMapReady?.call();
    if (widget.fitToContent) {
      _scheduleCameraUpdate(_fitContent);
    } else if (widget.followCurrentLocation) {
      final location = widget.currentLocation;
      if (location != null) {
        _scheduleCameraUpdate(() => _moveToCurrentLocation(location));
      }
    }
  }

  void _scheduleCameraUpdate(VoidCallback update) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _mapReady) update();
    });
  }

  void _moveToCurrentLocation(LocationReading location) {
    _mapController.move(
      LatLng(location.latitude, location.longitude),
      _mapController.camera.zoom.clamp(_minimumZoom, _maximumZoom),
    );
  }

  void _fitContent() {
    final points = _contentPoints(widget).toSet().toList(growable: false);
    if (points.isEmpty) {
      _mapController.move(
        widget.center,
        widget.zoom.clamp(_minimumZoom, _maximumZoom),
      );
      return;
    }
    if (points.length == 1) {
      _mapController.move(
        points.single,
        widget.zoom.clamp(_minimumZoom, _fitMaximumZoom),
      );
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        maxZoom: _fitMaximumZoom,
        minZoom: _minimumZoom,
        padding: widget.fitPadding,
      ),
    );
  }

  List<LatLng> _contentPoints(RoadMapView view) => [
    for (final route in view.routes)
      for (final coordinate in route.coordinates)
        LatLng(coordinate.latitude, coordinate.longitude),
    ...view.trace,
    for (final points in view.roadGeometries.values) ...points,
    for (final road in view.roads)
      if ((view.roadGeometries[road.roadSegmentId]?.length ?? 0) < 2)
        LatLng(road.latitude, road.longitude),
    for (final barrier in view.barriers)
      LatLng(barrier.location.latitude, barrier.location.longitude),
    ...view.impactPoints,
    if (view.currentLocation case final location?)
      LatLng(location.latitude, location.longitude),
  ];
}
