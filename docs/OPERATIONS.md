# Road DNA 운영·배포 런북

## 운영 토폴로지

```text
Cloudflare Flexible TLS
  → host nginx :80
  → /road-dna/* → 127.0.0.1:18080
  → dashboard nginx container :8080
      ├─ static React dashboard
      ├─ /api/*  → api:3000
      ├─ /docs/* → api:3000
      └─ /health → api:3000
  → existing MySQL :3306, dedicated road_dna schema only
  → existing password-protected Redis :6379
```

서버 작업 경로는 `~/Downloads/road-dna/deploy`다. API와 Dashboard는 `road-dna`
Compose 프로젝트와 `road-dna` 브리지 네트워크에만 생성된다. 기존 MySQL/Redis
컨테이너나 다른 스키마의 설정을 변경하지 않는다.

## 보안 경계

- API 이미지: 고정 digest의 Node 22 Alpine, `node` 사용자, 읽기 전용 루트
- Dashboard: 고정 digest의 nginx-unprivileged, UID 101, 읽기 전용 루트
- API 포트는 호스트에 공개하지 않는다.
- Dashboard는 `127.0.0.1:18080`에만 바인딩하고 호스트 nginx가 프록시한다.
- `.env` 권한은 `0600`; 저장소·GHCR 이미지·Actions 로그에 넣지 않는다.
- `MYSQL_DATABASE=road_dna`가 아니면 API와 마이그레이션이 즉시 실패한다.
- Actions SSH 키에는 OpenSSH `restrict` 옵션을 적용한다.

## 자동 배포

`.github/workflows/cd-onprem.yml`은 `main` push 또는 수동 실행 시:

1. API/Dashboard를 `linux/amd64`와 `linux/arm64`로 빌드한다.
2. 커밋 SHA 태그로 GHCR에 push한다.
3. `deploy/`만 서버에 동기화하고 서버의 `.env`는 보존한다.
4. 마이그레이션, 보관기간 정리, 최초 시연 데이터 seed를 실행한다.
5. 새 Compose 릴리스를 기동하고 내부·공개 health check를 확인한다.
6. 실패하면 직전 `release.env.previous` 이미지로 되돌린다.

필수 저장소 Secrets:

- `ONPREM_HOST`
- `ONPREM_USER`
- `ONPREM_SSH_PRIVATE_KEY`
- `ONPREM_KNOWN_HOSTS`

## 수동 운영

```bash
cd ~/Downloads/road-dna/deploy
./deploy.sh
docker compose --env-file .env --env-file release.env \
  -f docker-compose.prod.yml ps
docker compose --env-file .env --env-file release.env \
  -f docker-compose.prod.yml logs --tail=120 api dashboard
curl -fsS http://127.0.0.1:18080/health
```

공개 확인:

```bash
curl -fsS https://kimtaeeun.site/road-dna/health
curl -fsS 'https://kimtaeeun.site/road-dna/api/v1/roads/nearby?latitude=35.17882&longitude=126.90051&radius=2000&movementType=WHEELCHAIR'
```

## 롤백

`release.env.previous`가 있으면:

```bash
cd ~/Downloads/road-dna/deploy
ROAD_DNA_RELEASE_FILE="$PWD/release.env.previous" ./deploy.sh
cp release.env.previous release.env
```

마이그레이션은 전진·멱등 방식으로 작성한다. 파괴적 스키마 변경이 필요한 릴리스는
호환 기간과 별도 백업 절차를 추가하기 전 자동 배포하지 않는다.

## 장애 확인 순서

1. `/road-dna/health`의 `database`, `redis`가 모두 `true`인지 확인
2. `docker compose ps`에서 API/Dashboard가 `healthy`인지 확인
3. API 로그의 DB 접속·Redis 인증 오류 확인
4. `nginx -t` 후 `/road-dna/` 프록시 포트 확인
5. Cloudflare 원본은 HTTP이므로 애플리케이션 컨테이너에 인증서를 설치하지 않음

지도 타일은 MVP에서 OpenStreetMap 공개 타일과 명시적 attribution을 사용한다.
운영 트래픽이 커지면 `ROAD_DNA_TILE_URL`로 정책에 맞는 공급자나 자체 타일
서비스로 교체한다.
