#!/bin/bash
# SubagentStop: 에이전트 완료 리마인더

INPUT=$(cat)
AGENT=$(echo "$INPUT" | jq -r '.agent_name // empty' 2>/dev/null)
[ -z "$AGENT" ] && exit 0

case "$AGENT" in
  *code-review*|*code_review*)
    echo "[리마인더] code-reviewer 완료. 지적 사항을 반영하고 /verify로 확인하세요." ;;
  *qa-expert*|*qa_expert*)
    echo "[리마인더] qa-expert 완료. 테스트 커버리지와 품질 이슈를 확인하세요." ;;
  *test-automator*|*test_automator*)
    echo "[리마인더] test-automator 완료. 자동화 테스트 결과를 검토하세요." ;;
esac

exit 0
