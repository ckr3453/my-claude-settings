#!/bin/bash
# ─────────────────────────────────────────────────────────────
# 글로벌 Hook 설정 — bash 네이티브
# ─────────────────────────────────────────────────────────────
#
# ■ 정규식 가이드 (grep -E / ERE 기준)
#   .       임의 1문자           .*   0개 이상
#   [abc]   문자 클래스          [^a] 부정
#   (a|b)   OR 그룹              \b   단어 경계 (grep -P 필요)
#   ─────────────────────────────────────────────────────────
#   ⚠ 구분자가 | 이므로 정규식 안에서 리터럴 OR은 (a|b) 형태 사용
#     필드 분리는 첫 번째 | 기준이므로 패턴 내 | 는 안전
# ─────────────────────────────────────────────────────────────

# SKIP 메커니즘: .md 파일은 CRITICAL_PATTERNS 검사 제외
SKIP_EXTENSIONS=("md")

_should_skip() {
  local file="$1"
  local ext="${file##*.}"
  for skip_ext in "${SKIP_EXTENSIONS[@]}"; do
    [ "$ext" = "$skip_ext" ] && return 0
  done
  return 1
}

# 형식: "패턴 | 설명"
# 언어 무관 패턴만 유지. 환경변수 참조($)는 시크릿 패턴에서 제외
CRITICAL_PATTERNS=(
  'curl\s.*\|\s*(bash|sh|zsh)|wget\s.*\|\s*(bash|sh|zsh) | 원격 스크립트 파이프 실행'
  '(password|secret_key|api_key)\s*=\s*["\x27][^$] | 시크릿/인증정보 하드코딩'
  'chmod\s+777|chmod\s+a\+rwx | 과도한 퍼미션 부여'
  'sudo\s|SUID|setuid | 권한 상승'
)

# 형식: "패턴 | 설명"
# 범용 패턴만 유지. 언어 특정 패턴은 프로젝트 config에서 추가
WARNING_PATTERNS=(
  'TODO|FIXME|HACK|XXX | 미해결 마커'
  'disable.*eslint|noinspection|@Suppress|noqa|nolint | 린터 규칙 비활성화'
)

# 프로젝트별 오버라이드 지원
EXTRA_CRITICAL_PATTERNS=()
EXTRA_WARNING_PATTERNS=()

# 형식: "패턴 | 라벨 | 검사 중점"
LOCATIONS=(
  'src/(service|domain|core)/ | 서비스/도메인 | 비즈니스 로직 정합성'
  'src/(api|controller|route)/ | API 레이어 | 입력 검증, 에러 처리'
  'src/(repo|dao|model|entity)/ | 데이터 레이어 | 쿼리 안전성'
  '(test|spec|__tests__)/ | 테스트 | 커버리지, 경계값'
  'config/|\.config\. | 설정 파일 | 환경 분리, 시크릿 노출'
)

# 임계값
THRESHOLD_FIX=3    # 이하이면 즉시 수정 지시

# ─── config 로드 함수 ───
# 글로벌 먼저 로드 → 프로젝트 config 추가 로드 (병합)
_load_config() {
  local cwd="$1"
  if [ -n "$cwd" ] && [ -f "$cwd/.claude/hooks/config.sh" ]; then
    source "$cwd/.claude/hooks/config.sh"
    # 프로젝트 config에서 EXTRA 패턴이 정의되면 병합
    CRITICAL_PATTERNS+=("${EXTRA_CRITICAL_PATTERNS[@]}")
    WARNING_PATTERNS+=("${EXTRA_WARNING_PATTERNS[@]}")
  fi
}
