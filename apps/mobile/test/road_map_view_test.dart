import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:road_dna_design/road_dna_design.dart';
import 'package:road_dna_mobile/ui/road_map_view.dart';

void main() {
  testWidgets('map bounds zoom and reuses its network tile provider', (
    tester,
  ) async {
    Widget mapAt(LatLng center) => MaterialApp(
      theme: RdTheme.light(),
      home: SizedBox.expand(
        child: RoadMapView(center: center, showAttribution: false),
      ),
    );

    await tester.pumpWidget(mapAt(const LatLng(35.15995, 126.85315)));

    final flutterMap = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final firstTileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
    final firstTileProvider = firstTileLayer.tileProvider;

    expect(flutterMap.options.minZoom, 12);
    expect(flutterMap.options.maxZoom, 19);
    expect(firstTileLayer.keepBuffer, 1);
    expect(firstTileLayer.panBuffer, 0);

    await tester.pumpWidget(mapAt(const LatLng(35.16005, 126.85325)));

    final rebuiltTileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(rebuiltTileLayer.tileProvider, same(firstTileProvider));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
