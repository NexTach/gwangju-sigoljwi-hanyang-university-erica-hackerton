import type { RoadMapItem } from "@road-dna/contracts";
import type { FeatureCollection, LineString } from "geojson";
import maplibregl, { type GeoJSONSource } from "maplibre-gl";
import { useEffect, useRef } from "react";

interface RoadMapProps {
  roads: RoadMapItem[];
}

const roadFeatures = (roads: RoadMapItem[]): FeatureCollection<LineString> => ({
  features: roads.map((road) => ({
    geometry: {
      coordinates: [
        [road.longitude - 0.00006, road.latitude - 0.000045],
        [road.longitude + 0.00006, road.latitude + 0.000045],
      ],
      type: "LineString",
    },
    properties: {
      grade: road.grade,
      movementType: road.movementType,
      roadName: road.roadName,
      roadSegmentId: road.roadSegmentId,
      score: road.score ?? -1,
    },
    type: "Feature",
  })),
  type: "FeatureCollection",
});

export function RoadMap({ roads }: RoadMapProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return undefined;
    const map = new maplibregl.Map({
      center: [126.85315, 35.15995],
      container: containerRef.current,
      interactive: false,
      maxZoom: 20,
      minZoom: 9,
      style: "https://tiles.openfreemap.org/styles/liberty",
      zoom: 16.3,
    });
    map.on("load", () => {
      map.addSource("road-dna", {
        data: roadFeatures([]),
        type: "geojson",
      });
      map.addLayer({
        id: "road-dna-halo",
        layout: { "line-cap": "round", "line-join": "round" },
        paint: {
          "line-color": "#ffffff",
          "line-opacity": 0.92,
          "line-width": 9,
        },
        source: "road-dna",
        type: "line",
      });
      map.addLayer({
        id: "road-dna-segments",
        layout: { "line-cap": "round", "line-join": "round" },
        paint: {
          "line-color": [
            "match",
            ["get", "grade"],
            "GOOD",
            "#4f9a72",
            "NORMAL",
            "#f5a623",
            "CAUTION",
            "#f5a623",
            "POOR",
            "#e14f3d",
            "#a69d94",
          ],
          "line-width": 6,
        },
        source: "road-dna",
        type: "line",
      });
    });
    mapRef.current = map;

    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, []);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;
    const update = () => {
      const source = map.getSource("road-dna") as GeoJSONSource | undefined;
      source?.setData(roadFeatures(roads));
    };
    if (map.isStyleLoaded()) update();
    else map.once("load", update);
  }, [roads]);

  return (
    <div className="dashboard-map">
      <div
        aria-label="도로 접근성 점수 지도"
        className="dashboard-map__canvas"
        ref={containerRef}
        role="img"
      />
      <div
        aria-label="지도 범례"
        className="dashboard-map__legend"
        role="group"
      >
        <span>
          <i aria-hidden className="is-poor" />
          접근성 취약
        </span>
        <span>
          <i aria-hidden className="is-caution" />
          개선 필요
        </span>
        <span>
          <i aria-hidden className="is-good" />
          양호
        </span>
      </div>
    </div>
  );
}
