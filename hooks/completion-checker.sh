#!/bin/bash
# Stop: 변경 파일 위생 검사 + 리포트
# 빌드/테스트는 /verifier Stage 1이 담당. 이 hook은 변경 파일의 코드 위생 패턴만 빠르게 검사한다.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$CWD" ] && exit 0

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CHANGED="/tmp/.claude-changed-${SESSION_ID:-$$}"
[ -f "$CHANGED" ] || exit 0

# config 로드
source ~/.claude/hooks/config.sh
_load_config "$CWD"

REPORT=""
ISSUE_COUNT=0

# ─── WARNING_PATTERNS 검사 (변경 파일만, .md 등은 SKIP_EXTENSIONS로 제외) ───
WARNINGS=""
while IFS= read -r filepath; do
  [ -f "$filepath" ] || continue
  _should_skip "$filepath" && continue
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
    loc_pattern="${entry%% |*}"
    rest="${entry#* | }"
    loc_label="${rest%% |*}"
    loc_focus="${rest#* | }"
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
# 빌드/테스트는 /verifier Stage 1이 담당. 이 hook은 위생 이슈만 보고.
if [ $ISSUE_COUNT -gt 0 ]; then
  echo -e "[검사 결과: ${ISSUE_COUNT}건]\n${REPORT}" >&2
  echo "[시스템 지시] 위 이슈를 수정하세요." >&2
  exit 2
fi

exit 0
