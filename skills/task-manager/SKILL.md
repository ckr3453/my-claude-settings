---
name: task-manager
description: |
  장기 프로젝트의 태스크 상태를 디렉토리 기반으로 추적하는 스킬.
  사용 시점: /brief로 현재 상태 확인, 중단된 작업 재개, 태스크 완료 기록,
  새 프로젝트 시작 시 로드맵 설정, "다음 뭐해", "어디까지 했지", "이어서",
  "계속해줘", "뭐 남았어", "상태 확인", "브리핑" 같은 요청 시 반드시 이 스킬 사용.
  .claude/tasks/ 디렉토리가 있는 프로젝트에서 작업할 때 항상 참조.
---

# 태스크 매니저

**디렉토리 구조가 태스크 상태의 단일 진실 공급원(SSOT).**

- `queue/pending/` — 대기 중
- `queue/in_progress/` — 작업 중
- `queue/completed/` — 완료

## 사용하지 않는 경우

- **1회성 단순 작업** — 5분 이내, 단일 파일 수정
- **질문/조사** — 코드 변경 없이 정보 확인만
- **독립적 핫픽스** — 컨텍스트 없이 즉시 수정 가능한 버그

---

## 디렉토리 구조

```
.claude/
├── CLAUDE.md                         # 프로젝트 컨텍스트
└── tasks/
    ├── SPEC.md                       # 요구사항 명세 (승인 필수)
    ├── ROADMAP.md                    # Phase 개요
    ├── queue/
    │   ├── pending/
    │   ├── in_progress/
    │   └── completed/
    └── archive/
        └── roadmap-v1/
            ├── SPEC.md               # 아카이빙 시 함께 이동
            ├── roadmap.md
            └── phase-xxx.md
```

시작하기: `references/getting-started.md`

---

## 스펙 정의 (태스크 생성 전 필수)

새 프로젝트 또는 새 로드맵 시작 시:

1. 인터뷰 (최소 3라운드)    → 요구사항 구체화
2. SPEC.md 작성            → 사용자 승인 필수
3. AC → 태스크 분해        → pending/에 생성

**SPEC.md 승인 없이 태스크 생성 금지.**

인터뷰 프레임워크: `references/interview-framework.md`
계획 프로토콜: `references/planning-protocol.md`

---

## 태스크 파일

```markdown
# SWL 보고서 쿼리 구현

- phase: 4
- size: M
- blocked_by: 003-multi-template  (없으면 생략)

## 목표
- SwlPipePointRepository 네이티브 쿼리 추가

## 완료 기준
- [ ] GET /v1/swl-pipes가 200을 반환한다
- [ ] 단위 테스트가 통과한다
```

상태 필드 없음. **파일이 어느 디렉토리에 있느냐 = 상태.**
크기: S (< 1hr), M (1-4hr), L (4hr+)

상세 포맷: `references/task-format.md`

---

## AI 행동 규칙 (반드시 준수)

### 0. 스펙 인터뷰 (새 프로젝트/로드맵 시작 시)

1. 본질(Essence) 질문으로 시작 → 최소 3라운드 적응적 질문
2. 라운드 사이에 코드베이스 탐색 (Glob/Read)으로 맥락 파악
3. 인터뷰 완료 → SPEC.md 초안 작성 → 사용자 승인 대기
4. 승인 후 AC를 태스크로 분해 → ROADMAP.md → pending/에 생성
5. **승인 없이 태스크 생성 금지. 1회성 작업이면 생략.**

상세: `references/planning-protocol.md`, `references/interview-framework.md`

### 1. 태스크 시작

1. `pending/`에서 가장 작은 번호의 unblocked 태스크 선택
2. 해당 파일을 `in_progress/`로 이동 (`mv`)
3. 작업 시작

### 2. 태스크 완료

1. `/verify`를 실행하여 요구사항 대비 검증 (필수)
2. PASS 후 `completed/`로 이동, 파일 하단에 완료일 기록
3. FAIL 시: 1차 자동 수정 → 재검증, 2차 실패 시 사용자에게 원인과 대안 제시 (3회 이상 자동 재시도 금지)
4. 해당 Phase 전체 완료 시 → 섹션 3 아카이빙 즉시 실행

### 3. Phase 아카이빙

Phase의 모든 태스크가 `completed/`에 있을 때 (단일 세션에서 실행):

1. `completed/`의 해당 Phase 파일들을 `archive/roadmap-v{N}/phase-{name}.md`로 요약 병합
2. `completed/`에서 해당 파일들 삭제
3. ROADMAP.md에서 해당 Phase에 ✅ 표시

### 4. 로드맵 아카이빙

모든 Phase가 ✅일 때 (단일 세션에서 실행):

1. SPEC.md를 `archive/roadmap-v{N}/SPEC.md`로 복사 후 삭제
2. ROADMAP.md를 `archive/roadmap-v{N}/roadmap.md`로 복사
3. 새 ROADMAP.md 생성 (이전 로드맵 링크 포함)
4. 자동으로 새 Phase를 만들지 않음 — 사용자 입력 대기

### 5. 태스크 시작 전 접근 방식 확인

- S 태스크: "이 메서드를 수정하면 될 것 같은데, 진행할까요?" 수준
- M 태스크: 관련 코드 탐색 → 접근법 제시 → 승인 후 실행
- L 태스크: 사용자와 대화로 요구사항 구체화 → 세부 태스크로 분해 → pending/에 추가

**검증 체크리스트 생성 (M/L 태스크):**
접근 방식 확인 시, 완료 기준을 원자적 검증 항목으로 분해하여 사용자에게 제시한다.
**반드시 사용자 승인을 받아야 한다. 승인 없이 구현 진행 금지.**
사용자가 수정을 요청하면 반영 후 재승인을 받는다.
승인된 체크리스트를 태스크 파일에 기록한 후에만 구현을 시작한다.
완료 기준이 이미 원자적이면 (S 태스크 등) 생략한다.

```
접근 방식 확인 → 검증 체크리스트 제시 → 사용자 승인 (필수) → 태스크 파일에 기록 → 구현
```

### 6. 세션 종료 시 인수인계

1. 현재 진행 상황을 대화에 직접 요약 (완료한 것, 남은 것, 블로커)

---

## /brief - 상태 확인

### 실행 순서

```
1. .claude/tasks/ 존재 확인
2. CLAUDE.md, ROADMAP.md 읽기
3. Glob queue/{pending,in_progress,completed}/*.md
4. pending 중 blocked_by가 있는 파일만 Read
5. git log --oneline -5 (미기록 작업 감지)
6. 브리핑 + 다음 행동 제안
```

**핵심: Glob으로 상태 집계. 파일 내용은 최소한으로만 읽어 토큰 절약.**

| Case | 상황 | 핵심 행동 |
|------|------|----------|
| 1 | 미초기화 | init_project.py 안내 |
| 2 | 큐 비어있음 | ROADMAP.md 작성 제안 |
| 3 | 미기록 작업 감지 | completed/ 이동 제안 |
| 4 | 태스크 있음 | 진행률 + 다음 태스크 제안 |
| 5 | Phase 완료 | 아카이빙 제안 |
| 6 | 로드맵 완료 | 로드맵 아카이빙 제안 |

상세 템플릿: `references/brief-templates.md`

---

## 병렬 실행

| 조건 | 처리 |
|------|------|
| 독립 태스크 ≤ 2개 | 순차 (기본) |
| 독립 태스크 ≥ 3개 + 모두 S/M + 파일 겹침 없음 | 경량 병렬 (Task run_in_background) |
| 사용자가 명시 요청 | 팀 병렬 (TeamCreate) |

**의심스러우면 순차. TeamCreate는 사용자 요청 시에만.**

상세 규칙 + 동시성: `references/parallel-rules.md`

---

## 스크립트

| 스크립트 | 용도 |
|---------|------|
| `init_project.py` | .claude/ 구조 초기화 |
| `task_transition.py` | 태스크 완료 → 다음 시작 |

```bash
python3 ~/.claude/skills/task-manager/scripts/init_project.py <project-root>
```

ROADMAP.md 포맷: `references/roadmap-format.md`
