import type { RoadMapItem } from "@road-dna/contracts";
import { tokens } from "@road-dna/design-tokens";
import type { Feature, FeatureCollection, LineString } from "geojson";
import maplibregl, {
  type GeoJSONSource,
  type MapGeoJSONFeature,
} from "maplibre-gl";
import {
  useEffect,
  useRef,
  useState,
  type KeyboardEvent as ReactKeyboardEvent,
} from "react";
import { roadGeometryById, yongbongMapBounds } from "./demo-data";

interface RoadMapProps {
  onSelect: (roadSegmentId: string, trigger?: HTMLElement) => void;
  roads: RoadMapItem[];
  selectedRoadId: string | null;
}

const mapColors = {
  caution: tokens.semantic.light.mapCaution,
  good: tokens.semantic.light.mapGood,
  halo: tokens.semantic.light.surface,
  normal: tokens.semantic.light.mapNormal,
  poor: tokens.semantic.light.mapPoor,
  unknown: tokens.semantic.light.mapUnknown,
};

const roadFeatures = (
  roads: RoadMapItem[],
  selectedRoadId: string | null,
  keyboardRoadId: string | null,
): FeatureCollection<LineString> => ({
  features: roads.flatMap((road): Array<Feature<LineString>> => {
    const coordinates = roadGeometryById[road.roadSegmentId];
    if (!coordinates) return [];
    return [
      {
        geometry: {
          coordinates,
          type: "LineString",
        },
        properties: {
          grade: road.grade,
          keyboardActive: road.roadSegmentId === keyboardRoadId,
          movementType: road.movementType,
          roadName: road.roadName,
          roadSegmentId: road.roadSegmentId,
          score: road.score ?? -1,
          selected: road.roadSegmentId === selectedRoadId,
        },
        type: "Feature",
      },
    ];
  }),
  type: "FeatureCollection",
});

export function RoadMap({ onSelect, roads, selectedRoadId }: RoadMapProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const onSelectRef = useRef(onSelect);
  const [keyboardRoadId, setKeyboardRoadId] = useState<string | null>(
    selectedRoadId ?? roads[0]?.roadSegmentId ?? null,
  );

  useEffect(() => {
    onSelectRef.current = onSelect;
  }, [onSelect]);

  useEffect(() => {
    if (selectedRoadId) {
      setKeyboardRoadId(selectedRoadId);
      return;
    }
    if (
      keyboardRoadId === null ||
      !roads.some((road) => road.roadSegmentId === keyboardRoadId)
    ) {
      setKeyboardRoadId(roads[0]?.roadSegmentId ?? null);
    }
  }, [keyboardRoadId, roads, selectedRoadId]);

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return undefined;
    const map = new maplibregl.Map({
      bounds: [
        [yongbongMapBounds.minimumLongitude, yongbongMapBounds.minimumLatitude],
        [yongbongMapBounds.maximumLongitude, yongbongMapBounds.maximumLatitude],
      ],
      cooperativeGestures: true,
      container: containerRef.current,
      fitBoundsOptions: { padding: 42 },
      maxZoom: 20,
      minZoom: 9,
      style: "https://tiles.openfreemap.org/styles/liberty",
    });
    map.getCanvas().tabIndex = -1;
    map.keyboard.disable();
    map.on("load", () => {
      map.addSource("road-dna", {
        data: roadFeatures([], null, null),
        type: "geojson",
      });
      map.addLayer({
        id: "road-dna-halo",
        layout: { "line-cap": "round", "line-join": "round" },
        paint: {
          "line-color": mapColors.halo,
          "line-opacity": 0.92,
          "line-width": [
            "case",
            ["boolean", ["get", "selected"], false],
            14,
            ["boolean", ["get", "keyboardActive"], false],
            12,
            9,
          ],
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
            mapColors.good,
            "NORMAL",
            mapColors.normal,
            "CAUTION",
            mapColors.caution,
            "POOR",
            mapColors.poor,
            mapColors.unknown,
          ],
          "line-opacity": [
            "case",
            ["boolean", ["get", "selected"], false],
            1,
            0.9,
          ],
          "line-width": [
            "case",
            ["boolean", ["get", "selected"], false],
            8,
            ["boolean", ["get", "keyboardActive"], false],
            7,
            6,
          ],
        },
        source: "road-dna",
        type: "line",
      });
      map.addLayer({
        id: "road-dna-hit-area",
        layout: { "line-cap": "round", "line-join": "round" },
        paint: {
          "line-color": mapColors.unknown,
          "line-opacity": 0,
          "line-width": 24,
        },
        source: "road-dna",
        type: "line",
      });
      const roadIdFromEvent = (
        event: maplibregl.MapLayerMouseEvent & {
          features?: MapGeoJSONFeature[];
        },
      ): string | null => {
        const roadSegmentId = event.features?.[0]?.properties.roadSegmentId;
        return typeof roadSegmentId === "string" ? roadSegmentId : null;
      };
      map.on("click", "road-dna-hit-area", (event) => {
        const roadSegmentId = roadIdFromEvent(event);
        if (!roadSegmentId) return;
        setKeyboardRoadId(roadSegmentId);
        onSelectRef.current(roadSegmentId, containerRef.current ?? undefined);
      });
      map.on("mouseenter", "road-dna-hit-area", (event) => {
        map.getCanvas().style.cursor = "pointer";
        const roadSegmentId = roadIdFromEvent(event);
        if (roadSegmentId) setKeyboardRoadId(roadSegmentId);
      });
      map.on("mouseleave", "road-dna-hit-area", () => {
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
      source?.setData(roadFeatures(roads, selectedRoadId, keyboardRoadId));
    };
    if (map.isStyleLoaded()) update();
    else map.once("load", update);
  }, [keyboardRoadId, roads, selectedRoadId]);

  const keyboardRoad =
    roads.find((road) => road.roadSegmentId === keyboardRoadId) ?? roads[0];

  const handleKeyDown = (event: ReactKeyboardEvent<HTMLDivElement>) => {
    if (!roads.length) return;
    const currentIndex = Math.max(
      0,
      roads.findIndex((road) => road.roadSegmentId === keyboardRoadId),
    );
    if (
      event.key === "ArrowRight" ||
      event.key === "ArrowDown" ||
      event.key === "ArrowLeft" ||
      event.key === "ArrowUp"
    ) {
      event.preventDefault();
      const direction =
        event.key === "ArrowRight" || event.key === "ArrowDown" ? 1 : -1;
      const nextIndex =
        (currentIndex + direction + roads.length) % roads.length;
      const nextRoad = roads[nextIndex];
      if (nextRoad) setKeyboardRoadId(nextRoad.roadSegmentId);
      return;
    }
    if ((event.key === "Enter" || event.key === " ") && keyboardRoad) {
      event.preventDefault();
      onSelect(keyboardRoad.roadSegmentId, event.currentTarget);
    }
  };

  return (
    <div className="dashboard-map">
      <div
        aria-describedby="road-map-keyboard-help"
        aria-label={`도로 접근성 점수 지도${
          keyboardRoad
            ? `. 현재 ${keyboardRoad.roadName}, ${keyboardRoad.score ?? "점수 없음"}점`
            : ""
        }`}
        className="dashboard-map__canvas"
        onKeyDown={handleKeyDown}
        ref={containerRef}
        role="group"
        tabIndex={0}
      />
      <p className="sr-only" id="road-map-keyboard-help">
        화살표 키로 도로를 고르고 Enter 키로 상세 정보를 열 수 있어요.
      </p>
      <span aria-live="polite" className="sr-only">
        {keyboardRoad
          ? `${keyboardRoad.roadName}, 접근성 점수 ${
              keyboardRoad.score ?? "데이터 없음"
            }점`
          : "표시할 도로가 없어요"}
      </span>
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
