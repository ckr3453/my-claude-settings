#!/bin/bash
# my-claude-settings 셀프체크 — 운영 결함 자동 검출
#
# 검사 항목:
#   [1] dual-path sync — ~/.claude/ ↔ repo 간 hooks/agents/skills/statusline/settings 동기화
#   [2] SKILL.md references 무결성 — SKILL.md가 Read 지시하는 references/*.md 실재 여부
#   [3] hook 외부 명령 가용성 — hooks가 의존하는 jq/git/bash 등이 PATH에 있는지
#   [4] fragile 패턴 regression — 과거 제거된 macOS-위험 패턴(`timeout` 직접 호출 등)이 다시 들어왔는지
#
# Usage:
#   bash bin/doctor.sh
#
# Exit:
#   0 = 모든 검사 통과 (WARN은 허용)
#   1 = FAIL 1건 이상

set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
LIVE="$HOME/.claude"

PASS=0; WARN=0; FAIL=0

# ─── 색상 헬퍼 (NO_COLOR 환경변수 존중) ───
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  R='\033[0m'; GRN='\033[32m'; RED='\033[31m'; YEL='\033[33m'; DIM='\033[90m'; BLD='\033[1m'
else
  R=''; GRN=''; RED=''; YEL=''; DIM=''; BLD=''
fi

ok()   { printf "  ${GRN}✓${R} %s\n" "$1"; PASS=$((PASS+1)); }
bad()  { printf "  ${RED}✗${R} %s\n" "$1"; FAIL=$((FAIL+1)); }
warn() { printf "  ${YEL}⚠${R} %s\n" "$1"; WARN=$((WARN+1)); }
sec()  { printf "\n${BLD}[%s] %s${R}\n" "$1" "$2"; }

printf "${BLD}=== my-claude-settings doctor ===${R}\n"
printf "  ${DIM}repo:${R} %s\n" "$REPO"
printf "  ${DIM}live:${R} %s\n" "$LIVE"

# ─── [1] dual-path sync ───
sec 1 "dual-path sync (~/.claude/ ↔ repo)"
SYNC_TARGETS=("hooks" "agents" "skills" "statusline.sh" "settings.json")
for t in "${SYNC_TARGETS[@]}"; do
  if [ ! -e "$REPO/$t" ]; then
    warn "$t — repo에 없음"
    continue
  fi
  if [ ! -e "$LIVE/$t" ]; then
    bad "$t — live(~/.claude/)에 없음"
    continue
  fi
  if [ -d "$REPO/$t" ]; then
    DIFF=$(diff -rq "$LIVE/$t" "$REPO/$t" 2>&1)
    if [ -z "$DIFF" ]; then
      ok "$t/"
    else
      bad "$t/ — 비동기:"
      printf "%s\n" "$DIFF" | head -10 | sed 's/^/      /'
    fi
  else
    if diff -q "$LIVE/$t" "$REPO/$t" >/dev/null 2>&1; then
      ok "$t"
    else
      bad "$t — 비동기 (실행: diff $LIVE/$t $REPO/$t)"
    fi
  fi
done

# ─── [2] SKILL.md references 무결성 ───
sec 2 "SKILL.md references 무결성"
SKILLS_FOUND=0
while IFS= read -r skill; do
  SKILLS_FOUND=$((SKILLS_FOUND+1))
  rel="${skill#$REPO/}"
  skill_dir="$(dirname "$skill")"
  refs=$(grep -oE 'references/[a-zA-Z0-9_./-]+\.md' "$skill" 2>/dev/null | sort -u)
  if [ -z "$refs" ]; then
    ok "$rel ${DIM}(refs 없음)${R}"
    continue
  fi
  missing=""
  count=0
  while IFS= read -r ref; do
    count=$((count+1))
    [ ! -f "$skill_dir/$ref" ] && missing+="$ref "
  done <<< "$refs"
  if [ -z "$missing" ]; then
    ok "$rel ${DIM}($count refs OK)${R}"
  else
    bad "$rel — 누락: $missing"
  fi
done < <(find "$REPO/skills" -name "SKILL.md" 2>/dev/null)
[ $SKILLS_FOUND -eq 0 ] && warn "skills/ 디렉토리에 SKILL.md 없음"

# ─── [3] hook 외부 명령 가용성 ───
sec 3 "hook 외부 명령 가용성"
for cmd in jq git bash; do
  if command -v "$cmd" >/dev/null 2>&1; then
    path=$(command -v "$cmd")
    ok "$cmd ${DIM}→ $path${R}"
  else
    bad "$cmd — PATH에 없음 (일부 hook 실패 위험)"
  fi
done

# ─── [4] fragile 패턴 regression ───
sec 4 "fragile 패턴 regression"

# 4a. macOS에서 `timeout`/`gtimeout` raw 호출 (이전 결함 패턴)
#     run_with_timeout 같은 함수 정의는 제외 (`[^_a-zA-Z]`로 단어 경계 흉내)
TIMEOUT_HITS=$(grep -rnE '(^|[^_a-zA-Z])(timeout|gtimeout)[[:space:]]+[0-9]+' "$REPO/hooks/" 2>/dev/null | grep -vE 'command -v|TIMEOUT_BIN=|# ')
if [ -z "$TIMEOUT_HITS" ]; then
  ok "hooks에 timeout/gtimeout 직접 호출 없음"
else
  bad "hooks에서 timeout/gtimeout 직접 호출 발견 (macOS GNU coreutils 미설치 시 exit 127):"
  printf "%s\n" "$TIMEOUT_HITS" | head -5 | sed 's/^/      /'
fi

# 4b. completion-checker가 빌드를 다시 돌리지 않는지 (책임은 /verifier Stage 1)
BUILD_HITS=$(grep -nE 'gradlew build|mvn (compile|install|package|verify)|npm run build' "$REPO/hooks/completion-checker.sh" 2>/dev/null)
if [ -z "$BUILD_HITS" ]; then
  ok "completion-checker에 빌드 명령 없음 ${DIM}(책임: /verifier Stage 1)${R}"
else
  bad "completion-checker에 빌드 명령 발견 (의도: Stop 훅은 위생 검사만):"
  printf "%s\n" "$BUILD_HITS" | sed 's/^/      /'
fi

# ─── 요약 ───
printf "\n${BLD}=== 요약 ===${R}\n"
printf "  ${GRN}PASS${R}: %d\n" "$PASS"
printf "  ${YEL}WARN${R}: %d\n" "$WARN"
printf "  ${RED}FAIL${R}: %d\n" "$FAIL"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
