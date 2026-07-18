import type { RoadMapItem } from "@road-dna/contracts";
import type { FeatureCollection, LineString } from "geojson";
import maplibregl, {
  type GeoJSONSource,
  type MapGeoJSONFeature,
} from "maplibre-gl";
import { useEffect, useRef } from "react";

interface RoadMapProps {
  onSelect: (roadSegmentId: string) => void;
  roads: RoadMapItem[];
  selectedRoadId: string | null;
}

const roadFeatures = (
  roads: RoadMapItem[],
  selectedRoadId: string | null,
): FeatureCollection<LineString> => ({
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
      selected: road.roadSegmentId === selectedRoadId,
    },
    type: "Feature",
  })),
  type: "FeatureCollection",
});

export function RoadMap({ onSelect, roads, selectedRoadId }: RoadMapProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const onSelectRef = useRef(onSelect);

  useEffect(() => {
    onSelectRef.current = onSelect;
  }, [onSelect]);

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return undefined;
    const map = new maplibregl.Map({
      center: [126.85315, 35.15995],
      container: containerRef.current,
      cooperativeGestures: true,
      maxZoom: 20,
      minZoom: 9,
      style: "https://tiles.openfreemap.org/styles/liberty",
      zoom: 16.3,
    });
    map.addControl(
      new maplibregl.NavigationControl({ showCompass: false }),
      "bottom-right",
    );
    map.on("load", () => {
      map.addSource("road-dna", {
        data: roadFeatures([], null),
        type: "geojson",
      });
      map.addLayer({
        id: "road-dna-halo",
        layout: { "line-cap": "round", "line-join": "round" },
        paint: {
          "line-color": "#ffffff",
          "line-opacity": 0.92,
          "line-width": ["case", ["get", "selected"], 13, 9],
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
            "#18a866",
            "NORMAL",
            "#3182f6",
            "CAUTION",
            "#d97706",
            "POOR",
            "#e5484d",
            "#8b95a1",
          ],
          "line-width": ["case", ["get", "selected"], 9, 6],
        },
        source: "road-dna",
        type: "line",
      });
      const selectFeature = (
        event: maplibregl.MapLayerMouseEvent & {
          features?: MapGeoJSONFeature[];
        },
      ) => {
        const roadSegmentId = event.features?.[0]?.properties.roadSegmentId;
        if (typeof roadSegmentId === "string") {
          onSelectRef.current(roadSegmentId);
        }
      };
      map.on("click", "road-dna-segments", selectFeature);
      map.on("mouseenter", "road-dna-segments", () => {
        map.getCanvas().style.cursor = "pointer";
      });
      map.on("mouseleave", "road-dna-segments", () => {
        map.getCanvas().style.cursor = "";
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
      source?.setData(roadFeatures(roads, selectedRoadId));
    };
    if (map.isStyleLoaded()) update();
    else map.once("load", update);
  }, [roads, selectedRoadId]);

  return (
    <div className="dashboard-map">
      <div
        aria-label="도로 접근성 점수 지도. 우선 개선 도로 목록에서도 같은 구간을 선택할 수 있어요."
        className="dashboard-map__canvas"
        ref={containerRef}
        role="img"
      />
      <div aria-hidden className="dashboard-map__legend">
        <span>
          <i className="is-good" />
          양호
        </span>
        <span>
          <i className="is-normal" />
          보통
        </span>
        <span>
          <i className="is-caution" />
          주의
        </span>
        <span>
          <i className="is-poor" />
          불편
        </span>
      </div>
    </div>
  );
}
