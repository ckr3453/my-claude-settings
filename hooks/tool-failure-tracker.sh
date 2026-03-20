#!/bin/bash
# PostToolUseFailure: 반복 실패 감지 + CLAUDE.md 규칙 자동 강제
# - Edit 실패 3회 (같은 파일): "멈추고 접근 방식을 재고하라"
# - Bash(test) 실패 3회: "현재 접근을 중단하고 대안을 제시하라"
# - 모든 도구 5회: "에러 메시지를 정확히 읽고 근본 원인을 분석하라"

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
[ -z "$TOOL" ] && exit 0

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
[ -z "$SESSION_ID" ] && SESSION_ID="$$"

# 60초 윈도우 기반 추적
NOW=$(date +%s)
WINDOW=60

# 대상 파일 식별 (도구명 + 대상 파일 조합으로 추적)
case "$TOOL" in
  Edit|Write|Read)
    TARGET=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
    ;;
  Bash)
    TARGET="bash_cmd"
    ;;
  *)
    TARGET="general"
    ;;
esac

# 파일 해시 (경로를 안전한 파일명으로)
FILE_HASH=$(echo -n "${TOOL}:${TARGET}" | md5 -q 2>/dev/null || echo -n "${TOOL}:${TARGET}" | md5sum | cut -d' ' -f1)
STATE_FILE="/tmp/.claude-fail-${SESSION_ID}-${FILE_HASH}"

# 상태 파일에 타임스탬프 추가
echo "$NOW" >> "$STATE_FILE"

# 윈도우 내 실패 횟수 계산 (오래된 항목 제거)
CUTOFF=$((NOW - WINDOW))
FAIL_COUNT=0
TEMP_FILE=$(mktemp)
while IFS= read -r ts; do
  if [ "$ts" -ge "$CUTOFF" ] 2>/dev/null; then
    echo "$ts" >> "$TEMP_FILE"
    ((FAIL_COUNT++))
  fi
done < "$STATE_FILE"
mv "$TEMP_FILE" "$STATE_FILE"

# ─── 규칙별 메시지 주입 ───

# Edit 실패 3회 (같은 파일)
if [ "$TOOL" = "Edit" ] && [ "$FAIL_COUNT" -ge 3 ]; then
  echo "[STAGNATION] 같은 파일을 ${FAIL_COUNT}회 Edit 실패했습니다. 멈추고 접근 방식을 재고하세요. 파일을 다시 Read한 후 재시도하세요."
  rm -f "$STATE_FILE"
  exit 0
fi

# Bash(test) 실패 3회
if [ "$TOOL" = "Bash" ] && [ "$FAIL_COUNT" -ge 3 ]; then
  echo "[STAGNATION] 테스트/명령이 ${FAIL_COUNT}회 연속 실패했습니다. 현재 접근을 중단하고 대안을 제시하세요."
  rm -f "$STATE_FILE"
  exit 0
fi

# 모든 도구 5회 실패
if [ "$FAIL_COUNT" -ge 5 ]; then
  echo "[STAGNATION] ${TOOL}이(가) ${FAIL_COUNT}회 실패했습니다. 에러 메시지를 정확히 읽고 근본 원인을 분석하세요. 같은 방식으로 재시도하지 마세요."
  rm -f "$STATE_FILE"
  exit 0
fi

exit 0
