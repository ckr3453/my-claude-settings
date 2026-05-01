---
name: blog-writer
description: |
  코딩 경험을 캐주얼 에세이 스타일의 기술 블로그 포스트(삽질기/의사결정기/TIL/회고)로 변환하고 Jekyll 파일까지 생성한다.
  두 가지 모드: git 이력 분석 기반과 인터뷰 기반.
  API 레퍼런스, 튜토리얼/가이드("~하세요" 체), 뉴스 형식 글에는 사용하지 않는다.
argument-hint: "[<기간: 오늘|이번 주|지난달>]"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Bash(git *)", "AskUserQuestion"]
---

# 블로그 라이터 (Blog Writer)

**핵심 원칙**: 교과서가 아니라 개발자의 체험담. "~했더니 ~되더라" 스타일.

## 사용하지 않는 경우

- 기술 문서/API 레퍼런스 작성
- 뉴스/리포트 형식의 글
- 코드 변경 없는 순수 이론 정리
- 튜토리얼/가이드 형식 ("~하세요" 체)

---

## 포스트 유형 (4가지)

| 유형 | 핵심 | 신호 |
|------|------|------|
| **삽질기** | 문제 해결 과정을 시간순으로 | 에러, 디버깅, fix 커밋, revert |
| **의사결정기** | 왜 이 기술을 선택했는지 | A vs B, 설정/의존성 변경 |
| **TIL** | 짧고 밀도 있는 하나의 발견 | 새로 배운 것, 단일 파일 변경 |
| **회고** | 기간/프로젝트를 돌아보며 성장 정리 | 프로젝트 마무리, 대규모 변경 |

상세 템플릿: `references/post-type-templates.md`

---

## AI 행동 규칙

### 1. 모드 선택

| 트리거 | 모드 |
|--------|------|
| `/blog` | **Mode A** (git 분석) |
| `/blog-interview` | **Mode B** (인터뷰) |

- Mode A는 현재 디렉토리가 git 저장소일 때만 실행
- git 저장소가 아니면 자동으로 Mode B로 전환하고 사용자에게 안내

### 2. 공통 워크플로우

```
글감 수집 → 주제 후보 2~3개 제시 → [사용자 선택] ①
→ 포스트 유형 확인 → [사용자 승인] ②
→ 초안 생성 → [사용자 리뷰] ③
→ 수정 반영 → Jekyll 파일 생성
```

**사용자 확인 ① 주제 선택:**

```
AskUserQuestion(
  question: "어떤 주제로 글을 쓸까요?",
  header: "주제 선택",
  options: [
    {label: "<후보 1 제목>", description: "<유형 + 근거>"},
    {label: "<후보 2 제목>", description: "<유형 + 근거>"},
    {label: "<후보 3 제목>", description: "<유형 + 근거>"}
  ]
)
```

**사용자 확인 ② 포스트 유형 확인:**

```
AskUserQuestion(
  question: "포스트 유형은?",
  header: "유형",
  options: [
    {label: "<추천 유형>", description: "<선택 이유>"},
    {label: "삽질기", description: "문제 해결 과정"},
    {label: "의사결정기", description: "기술 선택 근거"},
    {label: "TIL", description: "짧은 발견"},
    {label: "회고", description: "기간/프로젝트 회고"}
  ]
)
```

**사용자 확인 ③ 초안 리뷰:** 초안 전체를 대화에 출력하고 피드백을 자유 텍스트로 받는다.

### 3. Mode A: Git 분석

**실행 순서:**

1. 사용자 발화에서 시간 범위 추출 ("오늘" → 1일, "이번 주" → 7일, "지난달" → 30일, 없으면 기본 3일)
2. 특정 브랜치 언급이 있으면 `git log main..HEAD`, 아니면 `git log --oneline --since="{범위}" --no-merges`로 커밋 수집
3. `git diff --stat`으로 주요 변경 파일 파악
4. 핵심 파일의 diff를 읽고 변경 패턴 분석
5. 커밋 메시지 키워드로 유형 추정
6. 주제 후보 2~3개 생성 → 위 "사용자 확인 ①"

각 후보 형식:

```
[유형] 제목 후보
- 근거: 어떤 커밋/변경에서 도출했는지
- 핵심 변경: 글의 중심이 될 내용
```

### 4. Mode B: 인터뷰

**실행 순서:**

1. `AskUserQuestion`으로 오프닝:
   ```
   AskUserQuestion(
     question: "최근 개발하면서 기억에 남는 경험이 있나요?",
     header: "글감",
     options: [
       {label: "삽질/디버깅", description: "에러나 문제 해결 과정"},
       {label: "기술 선택", description: "A vs B 고민"},
       {label: "새로 배운 것", description: "TIL/발견"},
       {label: "프로젝트 회고", description: "기간/성장 돌아보기"}
     ]
   )
   ```
2. 응답에 따라 포스트 유형 추정
3. `references/interview-questions.md`의 유형별 질문 세트를 `AskUserQuestion`으로 1개씩 순차 진행 (최소 3개, 최대 5개)
4. 답변을 종합하여 주제 후보 2~3개 생성 → 위 "사용자 확인 ①"

### 5. 초안 생성

사용자가 주제와 유형을 확인하면 초안을 생성한다.

1. 블로그 저장소에서 같은 유형의 기존 포스트 1~2개를 Read하여 톤과 구조를 참고
2. `references/writing-style-guide.md`의 문체 규칙 적용
3. `references/post-type-templates.md`의 해당 유형 골격 사용
4. `references/jekyll-format.md`의 front matter 포맷 적용
5. 초안 전체를 대화에 출력 (파일 생성 X) → 위 "사용자 확인 ③"

**초안에 반드시 포함:**
- Jekyll front matter (title, categories, date, last_modified_at, toc, toc_sticky, excerpt)
- 유형별 골격에 맞는 본문 구조
- 캐주얼 에세이 문체 ("~했다", "~더라")
- 코드 블록 (관련 코드가 있는 경우, 10줄 이내)

**초안에 포함하지 않는 것:**
- 이모지/이모티콘
- "~합니다" 경어체
- "~에 대해 알아보겠습니다" 같은 도입부
- 이미지 플레이스홀더

### 6. 수정 사이클

- **부분 수정**: 해당 부분만 수정하여 전체 초안 재출력
- **톤/방향 수정**: 문체 가이드 재적용하여 재작성
- **수정 3회 이상**: AskUserQuestion으로 방향 재확인:
  ```
  AskUserQuestion(
    question: "수정이 3회를 넘었습니다. 어떻게 진행할까요?",
    header: "수정 방향",
    options: [
      {label: "전체 재작성", description: "방향을 다시 잡고 초안 새로"},
      {label: "세부 조정만", description: "현재 버전 유지하며 미세 수정"},
      {label: "이대로 진행", description: "수정 종료, 파일 생성"}
    ]
  )
  ```
- **"됐어" / "이대로"**: 수정 종료, 파일 생성 단계로

### 7. Jekyll 파일 생성

**블로그 저장소 경로:**
- memory에 블로그 저장소 경로가 저장되어 있으면 그대로 사용
- 없으면 AskUserQuestion으로 경로 1회 확인 후 memory에 저장:
  ```
  AskUserQuestion(
    question: "블로그 저장소 경로는? (이후 세션에서 재확인 없이 사용)",
    header: "블로그 경로",
    options: [
      {label: "<후보 경로 1>", description: "기본값/추정 경로"},
      {label: "직접 입력", description: "사용자가 경로 입력"}
    ]
  )
  ```

**기존 카테고리에 글 쓰기 (포스트 1개만 생성):**
1. 카테고리에 맞는 하위 디렉토리 선택 (`_posts/{카테고리 경로}/`)
2. 파일명: `YYYY-MM-DD-slug.md` (slug는 언더스코어 구분)
3. 파일 내용: front matter + 확정된 본문

**새 카테고리 만들기 (사용자 확인 필수, 3개 파일 생성/수정):**
1. **아카이브 페이지 생성**: `_pages/categories/{섹션}/category-{name}.md`
2. **사이드바 수정**: `_includes/nav_list_main`에 카테고리 항목 추가
3. **포스트 작성**: `_posts/{섹션}/{name}/YYYY-MM-DD-slug.md`

새 카테고리가 필요한 글감이면, 주제 선택(①) 시점에 AskUserQuestion으로 카테고리 생성 여부도 함께 확인한다.

상세 포맷 및 템플릿: `references/jekyll-format.md`

### 8. 에러 복구

**git 저장소가 아닌 경우 (Mode A):**

```
AskUserQuestion(
  question: "현재 디렉토리가 git 저장소가 아닙니다. 어떻게 진행할까요?",
  header: "Mode 전환",
  options: [
    {label: "Mode B로 전환", description: "인터뷰 모드로 글감 발굴"},
    {label: "취소", description: "여기서 멈춤"}
  ]
)
```

**git 커밋이 부족한 경우:**

```
AskUserQuestion(
  question: "최근 {N}일간 커밋이 부족합니다. 어떻게 진행할까요?",
  header: "커밋 부족",
  options: [
    {label: "기간 7일로 확대", description: "최근 7일 커밋으로 재시도"},
    {label: "기간 14일로 확대", description: "최근 2주 커밋으로 재시도"},
    {label: "Mode B로 전환", description: "인터뷰 모드로 글감 발굴"}
  ]
)
```

**블로그 저장소 경로가 유효하지 않은 경우:**

```
AskUserQuestion(
  question: "지정한 경로에 _posts 디렉토리가 없습니다. 어떻게 할까요?",
  header: "경로 오류",
  options: [
    {label: "_posts 디렉토리 생성", description: "신규 블로그 초기화"},
    {label: "경로 다시 입력", description: "다른 경로로 시도"},
    {label: "취소", description: "파일 생성 중단"}
  ]
)
```

**초안 생성 중 문맥 부족:** 부족한 정보를 구체적으로 안내하고 추가 질문 2~3개로 보충 후 재시도.
