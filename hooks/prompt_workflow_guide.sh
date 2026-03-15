#!/bin/bash
# UserPromptSubmit: plan-guard 강화 — 구현 작업 감지 시 계획 수립 안내

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)
[ -z "$PROMPT" ] && exit 0

# 바이패스: 슬래시 명령, "간단:" 접두사
echo "$PROMPT" | grep -qE '^\s*/' && exit 0
echo "$PROMPT" | grep -qE '^\s*간단:' && exit 0

# 구현/리팩토링 키워드 감지
if echo "$PROMPT" | grep -qE '구현|만들어|추가해|수정해|리팩토링|고쳐|작성해'; then
  # 단순 질문 제외
  if ! echo "$PROMPT" | grep -qE '뭐야|알려줘|설명해|왜|어떻게 돼|어떻게돼|확인해'; then
    echo "[시스템 지시] 구현 작업이 감지되었습니다. /task-manager로 계획을 수립한 후 진행하세요."
  fi
fi

exit 0
