---
name: tech-decision
description: |
  Stack Overflow, Reddit, Hacker News, GeekNews 등 커뮤니티 의견을 수집해 최소 3개 옵션을 비교하는 근거 기반 의사결정 보고서를 생성한다.
  단순 사용법 질문이 아닌, 둘 이상의 기술/솔루션 중 선택이 필요한 의사결정 상황에서 사용한다.
argument-hint: "[<후보 1> vs <후보 2> ...]"
allowed-tools: ["Read", "Write", "WebSearch", "WebFetch", "AskUserQuestion"]
---

# 기술 의사결정 지원

## AI 행동 규칙

### 1. 인터뷰 우선 원칙

첫 단계는 항상 인터뷰. **의사결정 영역**과 **우선순위**는 AskUserQuestion으로, **현재 상황·맥락·제약사항**은 자유 텍스트로 받는다.

```
AskUserQuestion(
  questions: [
    {
      question: "의사결정 영역은?",
      header: "영역",
      options: [
        {label: "인프라", description: "서버/클라우드/컨테이너"},
        {label: "데이터베이스", description: "RDB/NoSQL/캐시"},
        {label: "프론트엔드", description: "프레임워크/빌드 도구"},
        {label: "백엔드", description: "프레임워크/언어"}
      ]
    },
    {
      question: "가장 중요한 우선순위는?",
      header: "우선순위",
      options: [
        {label: "성능", description: "처리 속도/응답 시간"},
        {label: "개발 속도", description: "빠른 구현/생산성"},
        {label: "비용", description: "라이선스/인프라 비용"},
        {label: "학습 곡선", description: "팀 학습 부담 최소화"}
      ]
    }
  ]
)
```

이후 자유 텍스트로 **현재 상황·맥락**과 **제약사항(예산, 팀 역량, 시간, 기존 스택)**을 받는다.

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

1. **인터뷰** — 위 "1. 인터뷰 우선 원칙" 절차대로 영역·우선순위·현황·제약 수집
2. **커뮤니티 조사** — 최소 5개 소스에서 의견 수집:
   ```
   WebSearch("PostgreSQL vs MySQL site:stackoverflow.com")
   WebSearch("PostgreSQL vs MySQL reddit r/programming")
   WebSearch("PostgreSQL vs MySQL site:news.ycombinator.com")
   WebSearch("PostgreSQL vs MySQL latest best practices")
   WebFetch("https://news.hada.io/search?q=PostgreSQL", prompt="PostgreSQL 관련 최근 토론 요약")
   ```
3. **분석 및 보고서 생성** — `references/report-template.md`에 따라 작성, 모든 추천에 커뮤니티 출처 포함

### 워크플로우 2: 빠른 비교 (간소화)

사용자가 이미 2-3개의 후보를 제시한 경우 워크플로우 1을 단축한다:

1. **인터뷰 단축** — 영역/우선순위는 사용자 메시지에서 추론, AskUserQuestion으로 우선순위만 확인 + 자유 텍스트로 제약사항 수집
2. **후보 기술 집중 조사** — 제시된 기술들만 웹 검색 (워크플로우 1의 2단계와 동일 형식)
3. **분석 및 보고서 생성** — 워크플로우 1의 3단계와 동일

