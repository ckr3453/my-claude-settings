# 기술 검증 자동 탐지 규칙

## 탐지 표

프로젝트 루트에서 아래 파일을 순서대로 탐색 (가장 먼저 매칭된 것만 실행):

| 탐지 파일 | 실행 명령어 |
|-----------|-----------|
| `build.gradle.kts` / `build.gradle` | `./gradlew test` |
| `pom.xml` | `mvn test` |
| `package.json` (scripts.test 존재) | `npm test` |
| `Cargo.toml` | `cargo test` |
| `pyproject.toml` / `pytest.ini` | `pytest` |
| `go.mod` | `go test ./...` |

## 실행 규칙

- **변경 관련 테스트만 실행** — `git diff --name-only`로 변경 파일 수집 → 대응 테스트 파일 탐색 → 해당 테스트만 실행
- 대응 테스트를 찾을 수 없으면 전체 테스트 실행
- 타임아웃 5분. 실패 시 1회 재시도 후 결과 보고
- 이미 실행됐으면 그 결과 참조
