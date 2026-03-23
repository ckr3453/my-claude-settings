---
name: tech-decision
description: |
  기술 선택/비교를 돕는 스킬. 인터뷰로 현황을 파악하고, Stack Overflow/Reddit/HN 등
  커뮤니티의 실제 의견을 수집/분석하여 근거 기반 추천을 제공.
  사용 시점: "A vs B 뭐가 나아?", "DB 뭐 쓸까", "프레임워크 추천", "기술 스택 고민",
  "인프라 선택", /tech-decision 명령 시 반드시 이 스킬 사용.
  단순 사용법 질문이 아닌, 기술 선택의 의사결정이 필요한 상황에서 트리거.
---

# 기술 의사결정 지원

커뮤니티 실제 의견 기반으로 기술을 비교하고 추천합니다.

## AI 행동 규칙 (반드시 준수)

### 1. 인터뷰 우선 원칙
- **첫 단계는 항상 인터뷰**: `AskUserQuestion` 도구를 사용하여 체계적으로 정보 수집
- **수집 항목**:
  1. 의사결정 영역 (인프라/데이터베이스/프론트엔드/백엔드/기타)
  2. 현재 상황 및 맥락
  3. 제약사항 (예산, 팀 역량, 시간, 기존 스택)
  4. 우선순위 (성능/개발속도/비용/학습곡선)

### 2. 커뮤니티 기반 의사결정
- **커뮤니티 근거 우선**: 개인적 선호나 일반론만으로 추천하지 않음
- **근거 기반 판단**: 웹 검색으로 수집한 커뮤니티 의견을 근거로, 사용자 맥락에 맞게 종합 판단
- **웹 검색 필수**: 다음 커뮤니티에서 실제 의견 수집
  - **일반 기술**: Stack Overflow, Reddit (r/programming, r/webdev, r/devops), Hacker News, Dev.to
  - **국내**: GeekNews, OKKY
- **AI 플랫폼 제외**: OpenAI, Anthropic, Google AI 등의 AI 플랫폼 커뮤니티는 제외
- **검색 키워드**: "latest", "recent", "current", "best practices" 등 범용 키워드 사용 (특정 연도 지양)

### 3. 다각도 분석
- **최소 3개 옵션**: 3개 이상의 기술/솔루션 비교
- **비교 기준**:
  - 장점/단점
  - 학습 곡선
  - 커뮤니티 활성도
  - 유지보수성
  - 비용 (라이선스, 인프라)
  - 팀 역량 적합성

### 4. 근거 명시 원칙
- **모든 추천에 출처 포함**: 웹 검색 결과의 URL과 요약 제시
- **커뮤니티 의견 인용**: "Stack Overflow에서 X명이 Y를 추천" 형식
- **트레이드오프 명시**: "만약 Z를 우선시한다면, A 대신 B를 고려할 수 있습니다"

### 5. 보고서 구조 (최종 출력)

보고서 형식은 `references/report-template.md` 참조.

## 워크플로우

### 워크플로우 1: 기술 선택 지원

1. **인터뷰 시작**
   ```
   사용자: /tech-decision
   AI: AskUserQuestion으로 의사결정 영역, 현황, 제약사항 수집
   ```

2. **커뮤니티 조사** — 최소 5개 소스에서 의견 수집
   ```
   WebSearch("PostgreSQL vs MySQL 2024 site:stackoverflow.com")
   WebSearch("PostgreSQL vs MySQL reddit r/programming")
   WebSearch("PostgreSQL vs MySQL site:news.ycombinator.com")
   WebFetch("https://news.hada.io/search?q=PostgreSQL", prompt="PostgreSQL 관련 최근 토론 요약")
   ```

3. **분석 및 보고서 생성** — 보고서 구조에 따라 작성, 모든 추천에 커뮤니티 출처 포함

### 워크플로우 2: 빠른 비교 (간소화)

사용자가 이미 2-3개의 후보를 제시한 경우:

1. **제약사항만 확인**: AskUserQuestion으로 우선순위/제약사항만 수집
2. **후보 기술 집중 조사**: 제시된 기술들만 웹 검색
3. **비교표 생성**: 간단한 장단점 비교표 제공

