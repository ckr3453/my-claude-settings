---
name: ui-prototyper
description: |
  PRD.md(또는 직접 입력)를 기반으로 정적 HTML 목업 variants를 생성하고 브라우저에서 확인.
  사용 시점: /prototype으로 목업 생성, /prototype-iterate로 variant 개선,
  /prototype-gallery로 갤러리 다시 열기,
  "목업 만들어", "UI 확인", "화면 비교", "프로토타입" 같은 요청 시 사용.
  prd-writer 이후 선택적으로 실행. UI 없는 피처에는 사용하지 않는다.
triggers: /prototype, /prototype-iterate, /prototype-gallery
---

# UI Prototyper

**정적 HTML 목업을 생성해 브라우저에서 눈으로 확인한다. "하나 말고 셋을 탐색".**

텍스트 스펙만으로는 "이게 맞나?" 판단이 불가능하다.
목업 3개를 띄워놓고 비교하면 10배 빠르다.

## 사용하지 않는 경우

- **UI 없는 피처** — 백엔드 API, 인프라, 배치 작업
- **이미 디자인이 확정된 경우** — 목업 탐색 불필요
- **실제 코드 재활용 목적** — 목업은 탐색용이지 코드 재활용용이 아님

---

## 생성 원칙

- **단일 HTML 파일** — 빌드 스텝 없음
- **Tailwind CDN** — `<script src="https://cdn.tailwindcss.com"></script>`
- **더미 데이터만** — 실 DB/API 접근 금지
- **프로젝트 코드와 독립** — 실제 컴포넌트 분석/참조 금지
- **한국어 콘텐츠** 기본
- **인터랙션 최소화** — 탭 전환, 토글 정도만. 라우팅 금지

더미 데이터 패턴: `references/dummy-data.md`
디자인 원칙: `references/design-principles.md`

---

## AI 행동 규칙 (반드시 준수)

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

### 2. Variant 3개 생성 (핵심)

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
bash ~/.claude/skills/ui-prototyper/scripts/serve.sh <project-root>/.prototypes
```

- 기존 서버가 실행 중이면 재활용, 브라우저 새로고침 안내
- 서버 종료 방법 안내

사용자에게 출력:
```
프로토타입 생성 완료!

갤러리: http://localhost:8765/<feature-name>/gallery.html

서버 종료: kill $(cat .claude/prototypes/.server.pid)
```

### 5. .gitignore 안내

`.claude/prototypes/`가 프로젝트 `.gitignore`에 없으면:
"`.claude/prototypes/`를 .gitignore에 추가하시겠어요?" 물음

### 6. 다음 단계 안내

- "어떤 variant가 마음에 드나요?"
- "개선이 필요하면 `/prototype-iterate v1 <피드백>` 실행하세요."
- "PRD에 반영할 인사이트가 생기면 `/prd` 재실행해서 업데이트하세요."

---

## /prototype — 신규 목업 생성

입력 수집 → 폴더 생성 → variant 3개 생성 → 갤러리 생성 → 서버 실행 → 안내

(위 행동 규칙 0~6 순서대로 실행)

## /prototype-iterate — variant 개선

사용 예: `/prototype-iterate v2 "필드명 truncate 말고 tooltip으로"`

1. 기존 `.claude/prototypes/<feature>/v2-<approach>/index.html` 읽기
2. 피드백 반영한 새 variant 생성
3. `v2-iter1/index.html` 또는 `v4-<new-approach>/index.html`로 저장 (사용자 선택)
4. 갤러리 업데이트
5. 서버 이미 실행 중이면 새로고침 안내, 아니면 서버 시작

## /prototype-gallery — 갤러리 다시 열기

1. `.claude/prototypes/` 하위 feature 폴더 목록 제시
2. 사용자가 선택하면 해당 갤러리 URL 안내 (서버 실행 중이면 바로, 아니면 서버 시작)

---

<!-- 확장 계획 (이번엔 미구현)
## 2단계: 도메인 특화 + lo-fi 모드
- references/domain-patterns.md (GIS, 농업 대시보드, 어드민 테이블)
- templates/lofi-wireframe.html (ASCII/단순 박스 모드)
- Superdesign MCP 연동 옵션

## 3단계: 외부 도구 통합
- shadcn/ui 연동
- Figma 내보내기
-->
