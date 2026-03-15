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

# 형식: "패턴 | 설명"
CRITICAL_PATTERNS=(
  'eval\(|exec\(|system\(|child_process|subprocess\.call|os\.system | 임의 코드 실행 함수'
  'BEGIN\s*\{|END\s*\{|getline | awk 인젝션 위험 패턴'
  'curl\s.*\|\s*(bash|sh|zsh)|wget\s.*\|\s*(bash|sh|zsh) | 원격 스크립트 파이프 실행'
  '\.env|credentials|secret_key|api_key|password\s*= | 시크릿/인증정보 하드코딩'
  'chmod\s+777|chmod\s+a\+rwx | 과도한 퍼미션 부여'
  'sudo\s|SUID|setuid | 권한 상승'
  'innerHTML\s*=|document\.write\(|v-html | XSS 취약점'
  'SELECT.*FROM.*WHERE.*\$|INSERT.*VALUES.*\$ | SQL 인젝션'
)

# 형식: "패턴 | 설명"
WARNING_PATTERNS=(
  'TODO|FIXME|HACK|XXX | 미해결 마커'
  'console\.log|print\(|fmt\.Print|System\.out | 디버그 출력 잔존'
  'any\b|as\s+any | TypeScript any 타입 사용'
  'sleep\s*\(|time\.sleep|Thread\.sleep | 하드코딩 슬립'
  'catch\s*\(\s*\)|except\s*: | 빈 예외 처리'
  'disable.*eslint|noinspection|@Suppress | 린터 규칙 비활성화'
  '\.only\(|fdescribe|fit\( | 테스트 포커스 잔존'
)

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
THRESHOLD_AGENT=4  # 이상이면 에이전트 추천
