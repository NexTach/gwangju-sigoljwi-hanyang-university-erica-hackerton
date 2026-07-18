import {
  Accessibility,
  ArrowRight,
  Baby,
  CircleHelp,
  Footprints,
  MapPin,
  Moon,
  Route,
  Sun,
  TriangleAlert,
} from "lucide-react";
import { useEffect, useState } from "react";
import {
  Alert,
  Badge,
  BottomCTA,
  BottomSheet,
  Button,
  ConfidenceBar,
  EmptyState,
  ListHeader,
  ListRow,
  Metric,
  Navigation,
  RoadScanRibbon,
  ScoreGauge,
  SegmentedControl,
  Skeleton,
  Surface,
  Switch,
  Tabs,
  TextField,
  Toast,
  ToastRegion,
} from "@road-dna/ui";

type Movement = "WHEELCHAIR" | "STROLLER" | "WALKING";

const palette = [
  ["Route Cobalt", "#3563E9"],
  ["Trace Cyan", "#19B8B2"],
  ["Barrier Coral", "#F04452"],
  ["Survey Amber", "#F59F00"],
  ["City Ink", "#191F28"],
  ["Map Snow", "#F7F8FA"],
] as const;

export function Catalog() {
  const [dark, setDark] = useState(false);
  const [movement, setMovement] = useState<Movement>("WHEELCHAIR");
  const [sheetOpen, setSheetOpen] = useState(false);
  const [toastVisible, setToastVisible] = useState(false);
  const [loading, setLoading] = useState(false);
  const [tab, setTab] = useState("foundation");

  useEffect(() => {
    document.documentElement.dataset.rdTheme = dark ? "dark" : "light";
  }, [dark]);

  return (
    <div className="catalog-shell">
      <Navigation
        actions={
          <Button
            aria-label={dark ? "라이트 모드로 전환" : "다크 모드로 전환"}
            leading={dark ? <Sun size={18} /> : <Moon size={18} />}
            onClick={() => setDark((value) => !value)}
            size="small"
            tone="ghost"
          >
            {dark ? "Light" : "Dark"}
          </Button>
        }
        subtitle="v1.0 · Web component catalog"
        title="Road DNA Design"
      />

      <main>
        <section className="catalog-hero">
          <div>
            <span className="catalog-kicker">CITY ACCESSIBILITY INTERFACE</span>
            <h1>
              움직임을
              <br />
              도시의 언어로.
            </h1>
            <p>
              명료한 행동과 신뢰 가능한 상태 표현을 바탕으로, 이동 중 방해를
              최소화하는 Road DNA의 제품 언어입니다.
            </p>
          </div>
          <Surface className="catalog-hero__signal" padding="large">
            <RoadScanRibbon state="active" />
            <div className="catalog-signal-readout">
              <span>ROAD ANALYSIS</span>
              <strong>ACTIVE</strong>
              <code>35.1595 · 126.8526</code>
            </div>
          </Surface>
        </section>

        <Tabs
          activeId={tab}
          ariaLabel="카탈로그 섹션"
          className="catalog-tabs"
          items={[
            { id: "foundation", label: "Foundation" },
            { id: "actions", label: "Actions" },
            { id: "data", label: "Road data" },
            { id: "states", label: "States" },
          ]}
          onChange={setTab}
        />

        <section className="catalog-section" id="foundation">
          <ListHeader
            description="원색이 아닌 의미 토큰으로만 제품 상태를 표현합니다."
            title="Foundation"
          />
          <div className="catalog-palette">
            {palette.map(([name, value]) => (
              <div className="catalog-swatch" key={name}>
                <span style={{ backgroundColor: value }} />
                <strong>{name}</strong>
                <code>{value}</code>
              </div>
            ))}
          </div>
          <div className="catalog-type">
            <Surface>
              <span className="catalog-label">DISPLAY · SUIT</span>
              <div className="catalog-display">Score 87</div>
            </Surface>
            <Surface>
              <span className="catalog-label">BODY · PRETENDARD</span>
              <p>이 길은 최근 7일간 14번 분석되었어요.</p>
              <code>ACCEL_Z 1.842 m/s²</code>
            </Surface>
          </div>
        </section>

        <section className="catalog-section" id="actions">
          <ListHeader
            description="각 화면의 주 행동은 하나이며, 처리 중 중복 실행을 막습니다."
            title="Actions & selection"
          />
          <Surface className="catalog-grid">
            <div className="catalog-group">
              <span className="catalog-label">BUTTON</span>
              <Button
                leading={<Route size={20} />}
                loading={loading}
                onClick={() => {
                  setLoading(true);
                  window.setTimeout(() => setLoading(false), 700);
                }}
              >
                측정 시작
              </Button>
              <Button onClick={() => setSheetOpen(true)} tone="secondary">
                이동 유형 선택
              </Button>
              <Button onClick={() => undefined} tone="danger">
                측정 종료
              </Button>
              <Button disabled onClick={() => undefined}>
                사용할 수 없음
              </Button>
            </div>
            <div className="catalog-group catalog-group--wide">
              <span className="catalog-label">SEGMENTED CONTROL</span>
              <SegmentedControl<Movement>
                ariaLabel="이동 유형"
                items={[
                  {
                    icon: <Accessibility size={20} />,
                    label: "휠체어",
                    value: "WHEELCHAIR",
                  },
                  {
                    icon: <Baby size={20} />,
                    label: "유모차",
                    value: "STROLLER",
                  },
                  {
                    icon: <Footprints size={20} />,
                    label: "보행",
                    value: "WALKING",
                  },
                ]}
                onChange={setMovement}
                value={movement}
              />
              <TextField
                helpText="5m~1,000m 사이로 입력해 주세요."
                label="검색 반경"
                min={5}
                suffix="m"
                type="number"
                defaultValue={500}
              />
              <Switch checked={dark} label="다크 모드" onChange={setDark} />
            </div>
          </Surface>
        </section>

        <section className="catalog-section" id="data">
          <ListHeader
            description="점수와 함께 등급·표본·신뢰도를 항상 노출합니다."
            title="Road data"
          />
          <div className="catalog-score-grid">
            <Surface className="catalog-score-card" padding="large">
              <ScoreGauge score={87} />
              <div>
                <Badge dot tone="success">
                  휠체어 · 양호
                </Badge>
                <h3>광주광역시청 앞 보행로</h3>
                <ConfidenceBar value={0.82} />
              </div>
            </Surface>
            <Surface className="catalog-score-card" padding="large">
              <ScoreGauge score={null} />
              <div>
                <Badge tone="neutral">UNKNOWN</Badge>
                <h3>아직 분석되지 않은 길</h3>
                <p>첫 이동 데이터가 쌓이면 점수를 계산해요.</p>
              </div>
            </Surface>
          </div>
          <div className="catalog-metrics">
            <Metric
              label="분석 거리"
              trend="지난주보다 18% 증가"
              value="12.8 km"
            />
            <Metric label="이동 장벽 후보" trend="검토 대기 7건" value="28" />
            <Metric label="HIGH 신뢰도" trend="전체 후보의 39%" value="11" />
          </div>
          <Surface padding="none">
            <ListRow
              description="휠체어 기준 · 신뢰도 82%"
              leading={<MapPin />}
              onClick={() => undefined}
              title="광주광역시청 앞 보행로"
              trailing={<Badge tone="success">87 · 양호</Badge>}
            />
            <ListRow
              description="최근 7일간 14회 반복 감지"
              leading={<TriangleAlert />}
              onClick={() => undefined}
              title="상무중앙로 횡단보도 진입부"
              trailing={<Badge tone="warning">53 · 주의</Badge>}
            />
          </Surface>
        </section>

        <section className="catalog-section" id="states">
          <ListHeader
            description="실패와 빈 상태는 사용자가 다음에 할 일을 말합니다."
            title="Feedback & states"
          />
          <div className="catalog-feedback">
            <Alert title="위치 신뢰도가 낮아요" tone="warning">
              GPS 정확도가 낮아 점수에는 아직 반영하지 않았어요.
            </Alert>
            <Alert title="측정을 시작했어요" tone="success">
              휴대폰을 휠체어에 고정하고 평소처럼 이동해 주세요.
            </Alert>
            <RoadScanRibbon state="idle" />
            <RoadScanRibbon state="active" />
            <RoadScanRibbon state="impact" />
            <Button
              onClick={() => {
                setToastVisible(true);
                window.setTimeout(() => setToastVisible(false), 2200);
              }}
              tone="secondary"
            >
              감지 Toast 보기
            </Button>
          </div>
          <div className="catalog-state-grid">
            <Surface>
              <Skeleton height={20} width="52%" />
              <div style={{ height: 12 }} />
              <Skeleton height={72} />
            </Surface>
            <Surface>
              <EmptyState
                action={
                  <Button
                    leading={<ArrowRight size={18} />}
                    onClick={() => undefined}
                  >
                    주변 도로 분석하기
                  </Button>
                }
                description="이 지역의 첫 접근성 데이터를 만들어 주세요."
                icon={<CircleHelp size={28} />}
                title="아직 분석된 길이 없어요"
              />
            </Surface>
          </div>
        </section>
      </main>

      <BottomCTA description="컴포넌트 계약은 모바일과 웹에서 같은 의미를 사용합니다.">
        <Button fullWidth onClick={() => setSheetOpen(true)} size="large">
          Bottom sheet 확인
        </Button>
      </BottomCTA>

      <BottomSheet
        description="측정 데이터는 선택한 유형의 점수에만 반영돼요."
        footer={
          <Button fullWidth onClick={() => setSheetOpen(false)} size="large">
            {movement === "WHEELCHAIR"
              ? "휠체어"
              : movement === "STROLLER"
                ? "유모차"
                : "보행"}
            로 측정
          </Button>
        }
        onClose={() => setSheetOpen(false)}
        open={sheetOpen}
        title="어떻게 이동하시나요?"
      >
        <SegmentedControl<Movement>
          ariaLabel="이동 유형"
          items={[
            { icon: <Accessibility />, label: "휠체어", value: "WHEELCHAIR" },
            { icon: <Baby />, label: "유모차", value: "STROLLER" },
            { icon: <Footprints />, label: "보행", value: "WALKING" },
          ]}
          onChange={setMovement}
          value={movement}
        />
      </BottomSheet>

      {toastVisible && (
        <ToastRegion>
          <Toast message="이동 충격 패턴을 감지했어요" tone="warning" />
        </ToastRegion>
      )}
    </div>
  );
}
