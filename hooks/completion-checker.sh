#!/bin/bash
# Stop: 변경 파일 종합 검사 + 리포트

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -z "$CWD" ] && exit 0

CHANGED="$CWD/.claude/.changed-files"
[ -f "$CHANGED" ] || exit 0

# config 로드
if [ -f "$CWD/.claude/hooks/config.sh" ]; then
  source "$CWD/.claude/hooks/config.sh"
else
  source ~/.claude/hooks/config.sh
fi

# commands.sh에서 빌드/린트 명령 추출 (source 안 함, grep으로 안전하게)
COMMANDS_FILE="$CWD/.claude/hooks/commands.sh"
if [ -f "$COMMANDS_FILE" ]; then
  BUILD_CMD=$(grep -m1 '^BUILD_CMD=' "$COMMANDS_FILE" | cut -d= -f2- | tr -d '"' | tr -d "'")
  LINT_CMD=$(grep -m1 '^LINT_CMD=' "$COMMANDS_FILE" | cut -d= -f2- | tr -d '"' | tr -d "'")
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
        WARNINGS+="  ⚠ $desc — $filepath:$line_num\n"
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
      LAYERS+="  📁 [$loc_label] $filepath — 중점: $loc_focus\n"
      break
    fi
  done
done < "$CHANGED"

[ -n "$LAYERS" ] && REPORT+="[레이어 분류]\n$LAYERS\n"

# ─── .changed-files 삭제 (1회성) ───
rm -f "$CHANGED"

# ─── 결과 분기 ───
if [ $ISSUE_COUNT -eq 0 ]; then
  echo "[시스템 지시] /verify로 요구사항 충족을 확인하세요."
elif [ $ISSUE_COUNT -le $THRESHOLD_FIX ]; then
  echo -e "[검사 결과: ${ISSUE_COUNT}건]\n${REPORT}"
  echo "[시스템 지시] 위 이슈를 수정하세요."
else
  echo -e "[검사 결과: ${ISSUE_COUNT}건]\n${REPORT}"
  echo "[시스템 지시] 이슈가 ${ISSUE_COUNT}건입니다. code-reviewer, qa-expert, test-automator 에이전트 활용을 권장합니다."
fi

exit 0
