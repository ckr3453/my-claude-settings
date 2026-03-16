# 기술 검증 자동 탐지

## 원칙

- 기술 검증은 **요구사항 충족의 필수 증거**다
- 탐지되면 반드시 실행한다. 실패 시 관련 항목은 PASS 불가
- 탐지된 것이 없으면 Phase 1-3 코드 증거만으로 검증 완료
- 기술 검증 통과만으로 요구사항 충족이 보장되지는 않음 (코드 증거도 필요)
- 프로젝트 루트에서 파일 존재 여부로 자동 탐지한다

---

## 탐지 규칙

프로젝트 루트에서 아래 파일을 순서대로 탐색합니다:

| 탐지 파일 | 프레임워크 | 실행 명령어 |
|-----------|-----------|-----------|
| `build.gradle.kts` 또는 `build.gradle` | Gradle (Kotlin/Java) | `./gradlew test` |
| `detekt.yml` 또는 `detekt.yaml` (Gradle 프로젝트) | detekt (정적 분석) | `./gradlew detekt` |
| `pom.xml` | Maven (Java) | `mvn test` |
| `package.json` (scripts.test 존재) | Node.js | `npm test` |
| `Cargo.toml` | Rust | `cargo test` |
| `pyproject.toml` 또는 `setup.py` 또는 `pytest.ini` | Python | `pytest` |
| `go.mod` | Go | `go test ./...` |
| `Makefile` (test 타겟 존재) | Make | `make test` |
| `mix.exs` | Elixir | `mix test` |
| `Gemfile` | Ruby | `bundle exec rspec` |
| `*.sln` 또는 `*.csproj` | .NET | `dotnet test` |

### 복수 탐지 시

여러 빌드 파일이 존재하면 **가장 먼저 매칭된 것만 실행**합니다.
모노레포 등 특수 구조에서는 사용자에게 어떤 명령어를 실행할지 확인합니다.

---

## Windows 호환

Windows 환경에서는 래퍼 스크립트를 우선 탐지합니다:

| Unix | Windows |
|------|---------|
| `./gradlew test` | `./gradlew.bat test` 또는 `gradlew test` |
| `npm test` | `npm test` (동일) |
| `make test` | 탐지하되 실행 전 확인 |

---

## 실행 규칙

1. **변경 관련 테스트만 실행** — 전체 테스트가 아닌, 변경된 파일과 관련된 테스트만 실행
2. **타임아웃 적용** — 5분(300초) 초과 시 중단하고 결과 보고
3. **실패 시 상세 출력** — 어떤 테스트가 실패했는지 포함
4. **이미 실행됐으면 생략** — 작업 중 테스트를 이미 실행했다면 그 결과를 참조

## 관련 테스트 탐지

전체 테스트 대신 변경과 관련된 테스트만 실행하여 효율을 높입니다.

### git 사용 가능 시 (기본)

1. `git diff --name-only`로 변경 파일 목록 수집
2. 변경 파일에 대응하는 테스트 파일 탐색:
   - `{ClassName}` → `{ClassName}Test`, `{ClassName}Spec`, `test_{class_name}`
   - `src/main/` → `src/test/` 경로 대응
3. 대응 테스트가 있으면 해당 테스트만 실행:
   - Gradle: `./gradlew test --tests "*ClassName*"`
   - Maven: `mvn test -Dtest=ClassNameTest`
   - Jest: `npx jest --testPathPattern="className"`
   - pytest: `pytest tests/test_class_name.py`
4. 대응 테스트를 찾을 수 없으면 전체 테스트 실행

### git 미사용 시 (폴백)

git이 없거나 diff를 구할 수 없는 경우:

1. 검증 항목에서 관련 클래스/파일명 추출
2. 해당 클래스에 대응하는 테스트 파일을 Glob으로 탐색
3. 찾은 테스트만 실행
4. 못 찾으면 전체 테스트 실행
