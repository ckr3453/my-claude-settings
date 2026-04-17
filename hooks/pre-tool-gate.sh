#!/bin/bash
# PreToolUse: 파괴적·돌이킬 수 없는 명령을 실행 전에 차단
#
# 원칙: 최소한의 블록 리스트. false positive를 줄이기 위해 정말 치명적이고
# 복구 불가능한 명령만 차단한다. 경고 수준은 post-tool-check.sh가 담당.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# Bash 도구만 대상 (파일 편집은 post-tool-check.sh의 CRITICAL_PATTERNS가 담당)
[ "$TOOL" != "Bash" ] && exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$CMD" ] && exit 0

block() {
  echo "BLOCKED: $1" >&2
  echo "차단된 명령: $CMD" >&2
  echo "다른 접근을 시도하거나 사용자에게 확인을 받으세요." >&2
  exit 2
}

# ─── 1. 루트/홈 전체 삭제 (rm -rf /, /*, ~) ───
# rm + -rf 계열 플래그 + 위험 경로 (정확히 해당 루트/홈만, subpath는 허용)
# 위험 경로 뒤에는 반드시 공백/종료/터미네이터가 와야 매치 (subpath의 `/`가 오면 매치 안 됨)
RM_FLAG='(-[a-zA-Z]*[rR][a-zA-Z]*[fF][a-zA-Z]*|-[a-zA-Z]*[fF][a-zA-Z]*[rR][a-zA-Z]*)'
DANGER_PATHS='(/\*|/home|/Users|/usr|/etc|/var|/bin|/sbin|/boot|/dev|~|\$HOME)'
PATH_END='($|[[:space:]]|[;|&])'
if echo "$CMD" | grep -qE "\brm[[:space:]]+${RM_FLAG}[[:space:]]+${DANGER_PATHS}${PATH_END}" || \
   echo "$CMD" | grep -qE "\brm[[:space:]]+${RM_FLAG}[[:space:]]+/${PATH_END}"; then
  block "rm -rf로 루트/홈/시스템 디렉토리 전체 삭제: 돌이킬 수 없음"
fi

# ─── 2. 디스크 직접 쓰기 (dd of=/dev/*) ───
if echo "$CMD" | grep -qE '\bdd\s+[^|&;]*of=/dev/'; then
  block "dd of=/dev/*: 디스크 파괴"
fi

# ─── 3. 파일시스템 포맷 (mkfs, mkfs.ext4 등) ───
if echo "$CMD" | grep -qE '\bmkfs(\.\w+)?\b'; then
  block "mkfs: 파일시스템 포맷은 데이터 영구 손실"
fi

# ─── 4. 원격 스크립트 파이프 실행 (curl|sh, wget|bash) ───
if echo "$CMD" | grep -qE '\b(curl|wget)\b[^|&;]*\|\s*(sudo\s+)?(bash|sh|zsh|dash)\b'; then
  block "curl/wget | sh: 검증되지 않은 원격 스크립트 실행"
fi

# ─── 5. main/master 브랜치에 force push ───
if echo "$CMD" | grep -qE '\bgit\s+push\s+[^&;]*(--force|[[:space:]]-f[[:space:]])[^&;]*\b(main|master)\b' || \
   echo "$CMD" | grep -qE '\bgit\s+push\s+[^&;]*\b(main|master)\b[^&;]*(--force|[[:space:]]-f[[:space:]])'; then
  block "git push --force main/master: 원격 히스토리 파괴"
fi

# ─── 6. DROP DATABASE / DROP TABLE / TRUNCATE (raw SQL via psql/mysql 등) ───
# psql/mysql/sqlite3가 명령에 있고 + DROP TABLE/DATABASE 또는 TRUNCATE가 있으면 차단
if echo "$CMD" | grep -qiE '\b(psql|mysql|mysqladmin|sqlite3)\b' && \
   echo "$CMD" | grep -qiE '(drop[[:space:]]+(database|table)|truncate[[:space:]]+table)'; then
  block "SQL DROP/TRUNCATE via CLI: 데이터 영구 손실. 마이그레이션 도구를 사용하세요."
fi

# ─── 7. .env / credentials 파일 내용 출력 (cat, less, tail, head 등) ───
if echo "$CMD" | grep -qE '\b(cat|less|more|tail|head|bat)\s+[^|&;]*(\.env($|[^a-zA-Z0-9])|credentials\.(json|yml|yaml)|id_rsa|id_ed25519|\.pem\b|\.key\b)'; then
  block "시크릿 파일 출력: 컨텍스트에 비밀이 노출될 수 있음. 필요한 값을 구체적으로 요청하세요."
fi

exit 0
