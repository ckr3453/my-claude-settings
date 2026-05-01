#!/usr/bin/env bash
# verifier Stage 1 — 빌드 도구 자동 감지 + 테스트 실행
#
# Usage:
#   bash run-stage1.sh [project-root]
#
# Output (stdout, 한 줄 구조화 요약):
#   PASS 시: "Stage 1 PASS — {tool} ({command}), {duration}s"
#   FAIL 시: "Stage 1 FAIL — {tool} ({command}), exit={code}, {duration}s"
#           이어서 마지막 30줄을 `--- 마지막 30줄 ---` 구분선과 함께 출력
#   SKIP 시: "Stage 1 SKIP — 빌드 도구 미감지" (stderr)
#
# Exit:
#   0 = PASS (빌드+테스트 통과)
#   1 = FAIL (빌드 또는 테스트 실패)
#   2 = SKIP (빌드 도구 미감지 — 메인 에이전트가 사용자에게 진행 여부 확인)

set -uo pipefail

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT" || { echo "Stage 1 SKIP — 디렉토리 진입 실패: $PROJECT_ROOT" >&2; exit 2; }

# 도구 감지 (가장 먼저 매칭된 것만 실행)
if [[ -f "build.gradle.kts" || -f "build.gradle" ]]; then
  TOOL="gradle"
  CMD="./gradlew test"
elif [[ -f "pom.xml" ]]; then
  TOOL="maven"
  CMD="mvn test"
elif [[ -f "package.json" ]] && grep -q '"test"' package.json; then
  TOOL="npm"
  CMD="npm test"
elif [[ -f "Cargo.toml" ]]; then
  TOOL="cargo"
  CMD="cargo test"
elif [[ -f "pyproject.toml" || -f "pytest.ini" ]]; then
  TOOL="pytest"
  CMD="pytest"
elif [[ -f "go.mod" ]]; then
  TOOL="go"
  CMD="go test ./..."
else
  echo "Stage 1 SKIP — 빌드 도구 미감지 (탐색: build.gradle/pom.xml/package.json/Cargo.toml/pyproject.toml/pytest.ini/go.mod)" >&2
  exit 2
fi

# 실행 (타임아웃 5분)
START=$(date +%s)
OUTPUT=$(timeout 300 bash -c "$CMD" 2>&1)
EXIT_CODE=$?
END=$(date +%s)
DURATION=$((END - START))

if [[ $EXIT_CODE -eq 0 ]]; then
  echo "Stage 1 PASS — $TOOL ($CMD), ${DURATION}s"
  exit 0
else
  echo "Stage 1 FAIL — $TOOL ($CMD), exit=$EXIT_CODE, ${DURATION}s"
  echo "--- 마지막 30줄 ---"
  echo "$OUTPUT" | tail -30
  exit 1
fi
