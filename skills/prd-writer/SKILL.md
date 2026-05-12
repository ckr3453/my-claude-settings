---
name: prd-writer
description: |
  제품/피처의 비개발 층위(WHY/WHO/WHAT — 문제·유저·유즈케이스·가정·범위·지표)를 인터뷰 기반으로 정의해 .claude/prd/PRD.md를 생성한다.
  단순 버그 수정, 리팩토링, UI 없는 소규모 개선에는 사용하지 않는다.
triggers: /prd, /prd-interview
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash(python *)", "Bash(git log *)", "Task", "AskUserQuestion"]
---

# PRD Writer

## 사용하지 않는 경우

- **단순 버그 수정** — PRD 불필요, 바로 수정
- **기존 API 리팩토링** — PRD 불필요
- **UI 없는 소규모 개선** — PRD 오버헤드가 이점보다 큼

---

## AI 행동 규칙

### 0. 사전 점검

1. 현재 작업 디렉토리가 프로젝트 루트인지 확인
2. `.claude/prd/PRD.md` 존재 여부 확인 (없으면 레거시 위치 `PRD.md`도 확인)
   - 있으면 AskUserQuestion으로 처리 방향 확인:
     ```
     AskUserQuestion(
       question: "기존 PRD.md가 있습니다. 어떻게 진행할까요?",
       header: "기존 PRD",
       options: [
         {label: "업데이트", description: "기존 PRD.md를 인터뷰로 보강"},
         {label: "새로 작성", description: "기존 PRD.md를 덮어쓰고 신규 작성"},
         {label: "다른 이름으로", description: ".claude/prd/PRD-<feature>.md로 별도 저장"}
       ]
     )
     ```
   - 없으면 신규 작성 모드 진입

### 1. 코드베이스 선스캔

프로젝트 맥락 파악 (태스크 분해 목적이 아님):

1. `README.md`, `package.json` / `pom.xml` / `build.gradle` 등 메타 파일 읽기
2. 주요 디렉토리 구조 파악 (Glob)
3. `git log --oneline -20` — 최근 작업 흐름 파악

### 2. 인터뷰 실행

**라운드 구성** (질문 풀: `references/question-bank.md`):

- **라운드 1: 문제 정의** — 카테고리 1 (필수 2-3개)
- **라운드 2: 유저와 유즈케이스** — 카테고리 3
- **라운드 3: 범위** — 카테고리 4
- **라운드 4: 가정** — 카테고리 5
- **라운드 5: 성공 지표** — 카테고리 6
- **라운드 6 (UI 있는 피처만): 화면 & 플로우** — 카테고리 7
- **라운드 7 (선택): 존재론적 심화** — 답변에 모호한 부분이 있을 때만 진입 (카테고리 2)

**진행 원칙:**

- 한 라운드에 질문 **최대 3-4개**
- 답변이 모호하면 "구체 예시 하나만" 요청
- **가정 뒤집기**: "X는 당연히 ~다"에 "만약 그게 틀렸다면?" 던질 수 있다
- 답이 모호하면 "정말 그런가요?" 재검증 가능
- 답변을 받으면 내부적으로 해당 섹션에 초안 누적
- **라운드 종료 시 Refine Gate 실행** (필수, 아래 "2.1 Refine Gate" 섹션 참조)
- 사용자가 "충분해" / "진행해" / "됐어"라고 하면 종료
- AI도 충분하다 판단하면 종료 제안 가능

### 2.1 Refine Gate (라운드 종료 시 1회)

각 라운드 마지막에 그 라운드의 모든 답변을 4필드로 구조화하고 사용자에게 누락/수정 확인을 받는다.

**목적:** 답변에 묻혀있는 제약(Constraints)·범위 밖(Out of scope)을 드러내, 후속 examiner 검토와 PRD 저장 시 사용자 의도를 보존한다.

**4필드 구조:**
- **Decision**: 이 라운드에서 결정된 내용 (카테고리별 한 줄씩)
- **Reasoning**: 사용자가 그렇게 결정한 이유 (답변에 명시됐을 때만; 추측 금지). 비어있으면 "(이유 미진술)"로 표기.
- **Constraints**: 결정에 붙는 제약 (법적 요구, 도메인 한계, 외부 의존). 없으면 "(없음)".
- **Out of scope**: 사용자가 명시적으로 범위 밖이라 한 항목. PRD에서 특히 중요. 없으면 "(없음)".

**호출 형식:**

```
AskUserQuestion(
  question: "이번 라운드 답변을 다음과 같이 정리했어요. 빠진 거 있나요?\n\nDecision: ...\nReasoning: ...\nConstraints: ...\nOut of scope: ...",
  header: "라운드 정리",
  options: [
    {label: "그대로 진행", description: "이 4필드 그대로 PRD에 반영"},
    {label: "Constraints 추가", description: "제약 조건 추가 입력"},
    {label: "Out of scope 추가", description: "범위 밖 항목 추가 입력"},
    {label: "다시 쓸래", description: "재구성 필요"}
  ]
)
```

> 4필드 본문은 `question`에 넣어 AskUserQuestion description 길이 한계를 피한다. `description`은 짧은 라벨만.

**규칙:**

- Refine Gate는 **답변 내부의 누락(Constraints/Out of scope)만** 본다. 전제 검증·실패 시나리오·대안 제시는 examiner 책임이므로 여기서 묻지 않는다.
- "Constraints 추가" / "Out of scope 추가" 선택 시 두 번째 AskUserQuestion으로 누락 텍스트를 받는다.
- "다시 쓸래" 선택 시 4필드를 새로 작성해 다시 확인한다. 무한 루프 방지를 위해 같은 라운드에서 2회까지만 재구성하고, 그래도 사용자가 거부하면 그 라운드의 답변을 원문 그대로 보존하고 다음 라운드로 진행한다.
- Reasoning 필드는 *사용자가 직접 말한 이유만* 적는다. AI 추론 금지. 비어있으면 "(이유 미진술)"로 표기.

**다층 방어:** Refine Gate는 *사용자 인지 보조* 1차 검출. examiner는 산출물 기반 *흐름 정합성* 2차 검출. 두 단계는 시점·정보·검출 방식이 다른 보완 관계 (중첩 아님).

**Refine 결과 보존:** 라운드 종료 후 4필드는 대화 내부적으로 누적, 인터뷰 완료 시점에 PRD.md의 `### C. 인터뷰 정리` (라운드별 4필드 원본) 섹션에 그대로 박는다. 본문은 4필드를 자연스러운 서술로 PRD 해당 섹션에 반영.

**부담 평가 (향후 결정):** Refine Gate 의무화로 인한 AskUserQuestion 호출 증가(라운드당 +1회, 보강 시 +2~3회, 최대 7라운드 = 최대 ~21회)는 2026-05-12 사용자 합의("써보고 불편하면 그때 바꾸자")에 따라 운영하며 평가한다. 부담 지표는 향후 결정.

**금기:**

- 기술 스택 질문 ("React? Vue?", "DB 뭐 쓸까요?") 절대 금지 — PRD는 비개발 층위(WHY/WHO/WHAT)만
- 구현 방법 질문 ("어떻게 처리할까요?") 금지
- 모호한 일반론 허용 금지 → 구체화 재질의

### 3. PRD.md 파일 생성

1. 인터뷰로 누적한 초안을 템플릿(`templates/prd.md`) 기반으로 PRD.md 파일에 작성. 각 라운드의 Refine 4필드를 PRD 본문(1~7장)에 자연스러운 서술로 반영하고, 원본은 `### C. 인터뷰 정리`에 라운드별로 그대로 박는다.
2. `.claude/prd/PRD.md`로 저장 (기본). `.claude/prd/` 폴더가 없으면 생성.
3. 여러 PRD 공존 시 AskUserQuestion으로 파일명 확인:
   ```
   AskUserQuestion(
     question: "기존 PRD.md가 있어 여러 PRD가 공존하게 됩니다. 파일명은?",
     header: "PRD 파일명",
     options: [
       {label: "PRD-<feature>.md", description: "feature명으로 별도 저장 (사용자가 feature명 입력)"},
       {label: "기존 PRD.md 덮어쓰기", description: "기존 파일 교체"}
     ]
   )
   ```
4. 작성일에 실제 날짜 기입, 상태는 `Draft`

### 4. 가정 검증 (Ambiguity 체크)

작성된 PRD.md를 `scripts/check_ambiguity.py`로 구조 검증:

```bash
python ~/.claude/skills/prd-writer/scripts/check_ambiguity.py <PRD.md 경로>
```

스크립트가 7개 main 섹션 존재 + 필수 항목 수(유즈케이스 ≥3, 정량 지표 ≥1, Out of scope ≥3, 가정 ≥3, 주요 화면 ≥1) + TBD/미정 표현 카운트(참고)를 확인하고 판정을 반환한다.

- **명확** → 다음 단계 (examiner 검토)
- **애매** (1-2개 미충족) → 미충족 항목을 보고하고 AskUserQuestion으로 보강 여부 확인:
  ```
  AskUserQuestion(
    question: "다음 항목이 부족합니다: {미충족 항목 목록}. 보강할까요?",
    header: "PRD 보강",
    options: [
      {label: "보강 인터뷰", description: "부족한 섹션만 추가 라운드 진행 후 PRD.md 업데이트 → 재검증"},
      {label: "이대로 진행", description: "현재 상태로 examiner 검토 진행"},
      {label: "취소", description: "PRD.md는 Draft로 남기고 종료"}
    ]
  )
  ```
- **불충분** (3개 이상 미충족) → 추가 인터뷰 라운드 권장

### 5. examiner 검토 (필수)

PRD.md 작성 완료 후 examiner 에이전트를 호출한다 (사용자 confirm 없이 자동):

```
Agent(
  subagent_type: "examiner",
  description: "PRD 검토",
  prompt: "다음 PRD.md의 논리적 허점, 빠진 전제, 실패 가능성을 검토해줘.\n\n{PRD.md 전체}"
)
```

결과를 `PRD.md` 하단의 `## 부록`에 `### D. 검토 의견` 서브섹션으로 추가하고 사용자에게 그대로 전달한다.

---

## /prd-interview — 인터뷰만 재실행

기존 PRD.md가 있을 때 특정 섹션만 보강:

1. 기존 PRD.md 읽기
2. 부족한 섹션 식별 (`check_ambiguity.py`로 미충족 항목 추출)
3. 해당 섹션에 대한 인터뷰만 진행
4. PRD.md 업데이트
