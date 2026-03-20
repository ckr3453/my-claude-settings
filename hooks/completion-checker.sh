#!/bin/bash
# Stop: 변경 파일 종합 검사 + 리포트

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$CWD" ] && exit 0

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CHANGED="/tmp/.claude-changed-${SESSION_ID:-$$}"
[ -f "$CHANGED" ] || exit 0

# config 로드
source ~/.claude/hooks/config.sh
_load_config "$CWD"

# ─── 빌드 명령 자동 감지 ───
BUILD_CMD=""
LINT_CMD=""

# commands.sh에서 먼저 시도
COMMANDS_FILE="$CWD/.claude/hooks/commands.sh"
if [ -f "$COMMANDS_FILE" ]; then
  BUILD_CMD=$(grep -m1 '^BUILD_CMD=' "$COMMANDS_FILE" | cut -d= -f2- | tr -d '"' | tr -d "'")
  LINT_CMD=$(grep -m1 '^LINT_CMD=' "$COMMANDS_FILE" | cut -d= -f2- | tr -d '"' | tr -d "'")
fi

# commands.sh에 없으면 빌드 도구 자동 감지
if [ -z "$BUILD_CMD" ]; then
  if [ -f "$CWD/gradlew" ]; then
    BUILD_CMD="./gradlew build -x test 2>&1"
  elif [ -f "$CWD/pom.xml" ]; then
    BUILD_CMD="mvn compile -q 2>&1"
  elif [ -f "$CWD/package.json" ]; then
    BUILD_CMD="npm run build --if-present 2>&1"
  fi
fi

REPORT=""
ISSUE_COUNT=0

# ─── 빌드/린트 실행 ───
if [ -n "$BUILD_CMD" ]; then
  build_out=$(cd "$CWD" && timeout 20 bash -c "$BUILD_CMD" 2>&1)
  if [ $? -ne 0 ]; then
    REPORT+="[빌드 실패]\n$build_out\n\n"
    ((ISSUE_COUNT++))
  fi
fi
if [ -n "$LINT_CMD" ]; then
  lint_out=$(cd "$CWD" && timeout 20 bash -c "$LINT_CMD" 2>&1)
  if [ $? -ne 0 ]; then
    REPORT+="[린트 경고]\n$lint_out\n\n"
    ((ISSUE_COUNT++))
  fi
fi

# ─── WARNING_PATTERNS 검사 (변경 파일만) ───
WARNINGS=""
while IFS= read -r filepath; do
  [ -f "$filepath" ] || continue
  for entry in "${WARNING_PATTERNS[@]}"; do
    pattern="${entry%% |*}"
    desc="${entry##*| }"
    matches=$(grep -nE "$pattern" "$filepath" 2>/dev/null)
    if [ -n "$matches" ]; then
      while IFS= read -r line; do
        line_num="${line%%:*}"
        WARNINGS+="  WARNING: $desc — $filepath:$line_num\n"
        ((ISSUE_COUNT++))
      done <<< "$matches"
    fi
  done
done < "$CHANGED"

[ -n "$WARNINGS" ] && REPORT+="[경고 패턴]\n$WARNINGS\n"

# ─── LOCATIONS 레이어 분류 ───
LAYERS=""
while IFS= read -r filepath; do
  for entry in "${LOCATIONS[@]}"; do
    loc_pattern=$(echo "$entry" | cut -d'|' -f1 | xargs)
    loc_label=$(echo "$entry" | cut -d'|' -f2 | xargs)
    loc_focus=$(echo "$entry" | cut -d'|' -f3 | xargs)
    if echo "$filepath" | grep -qE "$loc_pattern"; then
      LAYERS+="  [$loc_label] $filepath — 중점: $loc_focus\n"
      break
    fi
  done
done < "$CHANGED"

[ -n "$LAYERS" ] && REPORT+="[레이어 분류]\n$LAYERS\n"

# ─── .changed-files 삭제 (1회성) ───
rm -f "$CHANGED"

# ─── 실패 추적 파일도 정리 ───
rm -f /tmp/.claude-fail-${SESSION_ID}-* 2>/dev/null

# ─── 결과 분기 ───
if [ $ISSUE_COUNT -eq 0 ]; then
  echo "[시스템 지시] /verify로 요구사항 충족을 확인하세요."
elif [ $ISSUE_COUNT -gt 0 ]; then
  echo -e "[검사 결과: ${ISSUE_COUNT}건]\n${REPORT}"
  echo "[시스템 지시] 위 이슈를 수정하세요. 수정 후 /verify로 요구사항 충족을 확인하세요."
fi

exit 0
