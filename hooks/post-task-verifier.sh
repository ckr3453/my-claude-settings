#!/bin/bash
# PostToolUse(Task): implementer 서브에이전트 종료 시 메인 세션에 /verifier 실행 강제
#
# SubagentStop decision:block은 서브에이전트 자신에게 reason을 주입하므로
# 메인 세션 강제에는 부적합. PostToolUse(Task) decision:block은 메인 에이전트가
# Task 결과를 수령하는 시점에 reason을 다음 행동 지시로 주입한다.

INPUT=$(cat)

# matcher가 이미 Task/Agent를 필터링하므로 tool_name 체크 생략.
# subagent_type 기준으로만 분기.
SUBAGENT=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty' 2>/dev/null)
[ "$SUBAGENT" != "implementer" ] && exit 0

jq -n '{
  decision: "block",
  reason: "implementer 서브에이전트가 구현을 완료했습니다. 태스크 파일을 completed/로 이동하거나 사용자에게 완료 보고하기 전에 반드시 /verifier 스킬을 실행해 4단계 검증 프로토콜(요구사항 분해 → 증거 대조 → 변경 영향 → 잔여물 점검)을 수행하세요. PASS 전까지 다음 태스크로 넘어가지 마세요. FAIL이면 implementer에게 재위임 후 재검증."
}'
exit 0
