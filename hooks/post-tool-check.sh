#!/bin/bash
# PostToolUse: 보안 critical 차단 + 변경 파일 기록

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
[ -z "$TOOL" ] && exit 0

# ─── config 로드 ───
source ~/.claude/hooks/config.sh

CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$CWD" ] && _load_config "$CWD"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CHANGED="/tmp/.claude-changed-${SESSION_ID:-$$}"

# ─── Edit / Write: 보안 검사 + 파일 기록 ───
if [ "$TOOL" = "Edit" ] || [ "$TOOL" = "Write" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
  [ -z "$FILE_PATH" ] && exit 0

  # 변경 파일 기록
  grep -qxF "$FILE_PATH" "$CHANGED" 2>/dev/null || echo "$FILE_PATH" >> "$CHANGED"

  # SKIP 체크 (.md 등 + 훅 스크립트 자체)
  _should_skip "$FILE_PATH" && exit 0
  case "$FILE_PATH" in */.claude/hooks/*) exit 0 ;; esac

  # CRITICAL_PATTERNS 검사 (파일이 존재할 때만)
  [ -f "$FILE_PATH" ] || exit 0
  for entry in "${CRITICAL_PATTERNS[@]}"; do
    pattern="${entry%% |*}"
    desc="${entry##*| }"
    match=$(grep -nE "$pattern" "$FILE_PATH" 2>/dev/null | head -1)
    if [ -n "$match" ]; then
      line_num="${match%%:*}"
      echo "BLOCKED: $desc — $FILE_PATH:$line_num" >&2
      exit 2
    fi
  done
  exit 0
fi

# ─── Bash: 파괴적 명령 경고 ───
if [ "$TOOL" = "Bash" ]; then
  CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
  [ -z "$CMD" ] && exit 0
  if echo "$CMD" | grep -qE 'rm\s+-rf\s+/|drop\s+(table|database)|truncate\s+table|--force\s+push|reset\s+--hard|push\s+--force'; then
    echo "WARNING: 파괴적 명령이 감지되었습니다: 실행 전 영향 범위를 확인하세요."
  fi
  exit 0
fi

exit 0
