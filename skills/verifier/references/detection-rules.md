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

## 테스트 존재 여부 확인 규칙

각 검증 항목에 대해 해당 동작을 검증하는 테스트가 존재하는지 확인한다:

1. `git diff --name-only`로 변경된 소스 파일 수집
2. 각 소스 파일에 대응하는 테스트 파일 탐색 (예: `FooService.kt` → `FooServiceTest.kt`)
3. 테스트 파일 내에서 검증 항목과 관련된 테스트 메서드가 있는지 grep으로 확인
4. 결과를 검증 보고서의 각 항목에 기록:
   - 테스트 존재 + 통과 → PASS 가능
   - 테스트 존재 + 실패 → FAIL
   - 테스트 미존재 → ⚠️ PARTIAL (테스트 미작성)

**verifier는 테스트를 작성하지 않는다.** 테스트가 없으면 PARTIAL로 판정하고 "테스트 미작성" 사실만 보고한다.
