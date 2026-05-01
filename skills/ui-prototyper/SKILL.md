---
name: ui-prototyper
description: |
  PRD.md 또는 사용자 직접 입력을 기반으로 서로 다른 접근의 정적 HTML 목업 3개(variants)를 생성하고 갤러리로 비교한다.
  Tailwind CDN + 단일 HTML 파일 + 더미 데이터만 사용 (실 DB/API 접근 금지).
  백엔드/인프라 등 UI 없는 피처, 디자인이 이미 확정된 경우에는 사용하지 않는다.
triggers: /prototype, /prototype-iterate, /prototype-gallery
---

# UI Prototyper

## 사용하지 않는 경우

- **UI 없는 피처** — 백엔드 API, 인프라, 배치 작업
- **실제 코드 재활용 목적** — 목업은 탐색용이지 코드 재활용용이 아님

---

## 생성 원칙

- **빌드 스텝 없음** (단일 HTML, Tailwind CDN)
- **프로젝트 코드와 독립** — 실제 컴포넌트 분석/참조 금지
- **한국어 콘텐츠** 기본
- **인터랙션 최소화** — 탭 전환, 토글 정도만. 라우팅 금지

더미 데이터 패턴: `references/dummy-data.md`
디자인 원칙: `references/design-principles.md`

---

## AI 행동 규칙

### 0. 입력 수집

**경로 A (PRD 기반):**
1. `.claude/prd/PRD.md` 존재 확인 (없으면 레거시 위치 `PRD.md`도 확인)
2. "7. 화면 & 플로우" 섹션 추출
3. 주요 화면 목록과 핵심 동선 파악
4. 섹션이 비어있거나 "해당 없음"이면 경로 B로 전환

**경로 B (직접 입력):**
사용자에게 짧은 입력 요청:
- 피처명 (예: "data-comparison")
- 주요 화면 목록 (예: "대시보드, 상세 비교, 결과 공유")
- 핵심 동선 한 줄

### 1. Feature 폴더 생성

프로젝트 루트에:
```
.claude/prototypes/
└── <feature-name>/
    ├── gallery.html
    ├── v1-<approach>/
    │   └── index.html
    ├── v2-<approach>/
    │   └── index.html
    └── v3-<approach>/
        └── index.html
```

### 2. Variant 3개 생성

각 variant는 **정말로 다른 접근**이어야 한다. 색만 다른 건 불가.

**생성 체크리스트:**
- [ ] 각 variant가 서로 다른 레이아웃/구조 접근
- [ ] 단일 HTML 파일 (`index.html`)
- [ ] Tailwind CDN 포함
- [ ] 더미 데이터 인라인 (JSON `<script>` 또는 하드코딩)
- [ ] 한국어 콘텐츠
- [ ] 반응형 (`md:`, `lg:` breakpoint 활용)
- [ ] 상태 케이스 최소 1개 (빈 상태, 로딩, 에러 중)
- [ ] 상단 주석으로 "이 variant의 핵심 아이디어" 명시

HTML 스켈레톤: `templates/base.html`

### 3. 갤러리 페이지 생성

`.claude/prototypes/<feature>/gallery.html`:
- 3개 variant를 iframe으로 나란히 로드
- 각 variant의 접근 방식 설명
- 데스크톱 3열, 모바일 세로 스택

갤러리 스켈레톤: `templates/gallery.html`

### 4. 로컬 서버 실행 및 브라우저 오픈

```bash
bash ~/.claude/skills/ui-prototyper/scripts/serve.sh <project-root>/.claude/prototypes
bash ~/.claude/skills/ui-prototyper/scripts/open-gallery.sh <feature-name>
```

- `serve.sh`: `.server.pid`에 기록된 기존 서버가 있으면 종료하고 새로 시작 (포트 8765). PID는 `.server.pid`에 기록.
- `open-gallery.sh`: OS별 명령(`open`/`xdg-open`/`start`)으로 갤러리 URL을 브라우저에 자동 오픈.

사용자에게 출력:
```
프로토타입 생성 완료!

갤러리: http://localhost:8765/<feature-name>/gallery.html
서버 종료: kill $(cat .claude/prototypes/.server.pid)
```

### 5. .gitignore 안내

`.claude/prototypes/`가 프로젝트 `.gitignore`에 없으면 AskUserQuestion으로 추가 여부 확인:

```
AskUserQuestion(
  question: ".claude/prototypes/를 .gitignore에 추가할까요?",
  header: ".gitignore",
  options: [
    {label: "추가", description: ".claude/prototypes/ 항목을 .gitignore에 추가"},
    {label: "건너뛰기", description: ".gitignore 변경 안 함"}
  ]
)
```

### 6. 다음 단계 안내

- "어떤 variant가 마음에 드나요?"
- "개선이 필요하면 `/prototype-iterate v1 <피드백>` 실행하세요."

---

## /prototype-iterate — variant 개선

사용 예: `/prototype-iterate v2 "필드명 truncate 말고 tooltip으로"`

1. 기존 `.claude/prototypes/<feature>/v2-<approach>/index.html` 읽기
2. AskUserQuestion으로 저장 방식 확인:
   ```
   AskUserQuestion(
     question: "피드백 반영한 새 variant를 어디에 저장할까요?",
     header: "저장 위치",
     options: [
       {label: "v2-iter1/", description: "기존 v2의 개선판 (같은 approach 유지)"},
       {label: "v4-<new-approach>/", description: "새 approach로 별도 variant 추가"}
     ]
   )
   ```
3. 새 variant 생성 + 선택된 위치에 저장
4. 갤러리 업데이트
5. 갤러리 새로고침 안내 (브라우저 탭에서 F5). 서버가 죽었으면 `serve.sh` 재호출.

## /prototype-gallery — 갤러리 다시 열기

`.claude/prototypes/` 하위 feature 폴더 목록을 AskUserQuestion으로 제시:

```
AskUserQuestion(
  question: "어떤 feature의 갤러리를 열까요?",
  header: "Feature 선택",
  options: [
    {label: "<feature-1>", description: "{feature-1} 갤러리 열기"},
    {label: "<feature-2>", description: "{feature-2} 갤러리 열기"}
  ]
)
```

선택 후:
```bash
bash ~/.claude/skills/ui-prototyper/scripts/serve.sh <project-root>/.claude/prototypes
bash ~/.claude/skills/ui-prototyper/scripts/open-gallery.sh <selected-feature>
```
