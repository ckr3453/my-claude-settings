---
name: global-economy-report
description: |
  48시간 이내 세계 경제 이슈를 수집/분석하여 이메일로 보고서를 전송하는 스킬.
  해외 주요 경제 매체와 국내 경제 뉴스에서 핵심 이슈를 요약 제공.
  사용 시점: 경제 리포트 요청, 경제 뉴스 수집, /global-economy-report 명령,
  cron/스케줄러 자동 실행, "경제 소식", "증시 뉴스", "글로벌 경제" 요청 시 반드시 이 스킬 사용.
---

# Global Economy Report Skill

세계 경제 이슈를 수집, 분석하여 마크다운 보고서 생성 후 이메일 전송.

## ⛔ 실행 모드 제약

- **절대 plan mode를 사용하지 말 것. 계획서 작성 없이 즉시 실행할 것.**
- 이 스킬은 비대화형(`-p`) 모드에서 스케줄러로 자동 실행된다.
- plan mode에 진입하면 승인할 사용자가 없어 작업이 완전히 실패한다.
- EnterPlanMode 도구를 절대 호출하지 말 것.

## 파이프라인

```
Step 0: 날짜 계산                     → references/date-filtering.md
Step 1: 수집 (국내 WebFetch + 해외 WebSearch) → references/execution-steps.md
Step 2: 날짜 필터링                   → references/date-filtering.md
Step 3: 보고서 생성                   → references/report-template.md
Step 4: 이메일 전송                   → scripts/send_email.py
```

**반드시 아래 순서로 진행한다:**

1. **`references/date-filtering.md`를 Read** — Step 0 날짜 계산 명령과 필터링 규칙을 로드
2. **`references/execution-steps.md`를 Read** — Step 1-A (국내 크롤링), Step 1-B (해외 검색) 절차를 로드
3. Step 0의 bash 명령으로 오늘/어제 날짜 계산
4. Step 1-A → Step 1-B 순차 실행 (병렬 호출 금지)
5. 수집 결과에 날짜 필터링 적용
6. **`references/report-template.md`를 Read** — 템플릿 로드 후 `/tmp/global_economy_report_YYYYMMDD.md`로 저장
7. `scripts/send_email.py`로 이메일 전송

검색 대상 매체/URL 목록은 `references/sources.md` 참조.

## 보고서 섹션 구조

보고서는 **해외**와 **국내**를 명확히 구분하여 작성한다.

### 🌍 해외
1. 주요 경제 뉴스 — 글로벌 핵심 경제 이슈
2. 증시 — S&P500, 나스닥, 다우, 유럽/아시아 주요 지수
3. 중앙은행 정책 — Fed, ECB, BOJ 등 통화정책
4. 산업별 동향 — 주요 산업 섹터 뉴스
5. 무역/통상 — 관세, FTA, 국제 통상 이슈
6. 투자 동향 — M&A, IPO, VC 투자 등

### 🇰🇷 국내
1. 주요 경제 뉴스 — 국내 핵심 경제 이슈
2. 증시/환율 — 코스피, 코스닥, 원/달러 환율
3. 한국은행 정책 — 금리, 통화정책
4. 산업별 동향 — 국내 주요 산업 뉴스
5. 무역/통상 — 수출입, FTA, 통상 이슈
6. 투자 동향 — 국내 M&A, IPO, VC 투자 등

### 공통
- 추천 읽을거리 — 국내외 심층 기사/분석 (중복 금지)

## 에러 처리 원칙

- **병렬 호출 금지**: WebFetch/WebSearch를 동시에 여러 개 호출하면 하나 실패 시 전체 실패
- **순차 실행**: 한 번에 하나씩 호출하여 에러 격리
- **요청 간 최소 3초 간격**: rate limiting 방지
- **재시도**: WebFetch 실패 → 5초 대기 후 1회 재시도 → WebSearch 폴백 → 건너뛰고 다음 소스
- **한 소스 실패해도 계속 진행**: 검색 결과 없는 섹션은 생략, 전체 실패 시 "오늘은 데이터를 수집할 수 없습니다" 보고서 생성

## 보고서 작성 규칙

1. **한국어 작성**, 각 항목 2-3문장 핵심 요약
2. **출처 명시**: 모든 항목에 URL 포함, 날짜 없으면 제외
3. **중복 제거**: 같은 뉴스는 가장 신뢰도 높은 1개만 채택. 동일 URL 2번 등장 금지. 추천 읽을거리에는 다른 섹션 항목 절대 금지
4. **섹션 생략**: 48시간 이내 뉴스가 없는 섹션은 생략 (빈 섹션 > 오래된 뉴스)
5. **내용 없으면 솔직하게**: "오늘은 특별한 소식이 없습니다" 표기

## ⛔ 최종 체크리스트 (보고서 생성 전)

- ⛔ 2일 전 이상의 항목 없는가? (Step 0의 오늘/어제 날짜로 검증)
- ⛔ 동일 URL 중복 없는가?
- ⛔ 같은 사건을 여러 항목으로 반복 기술하지 않았는가?

## 이메일 설정

`scripts/config.json` 필요 (Gmail 앱 비밀번호 사용).
