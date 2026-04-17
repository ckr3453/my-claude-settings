---
name: task-manager
description: |
  장기 프로젝트의 태스크 상태를 디렉토리 기반으로 추적·관리하는 스킬.
  사용 시점: /brief로 현재 상태 확인, 중단된 작업 재개, 태스크 파일 생성 및 분해,
  pending/→in_progress/→completed/ 폴더 이동으로 상태 변경, 진행률 집계 및 보고,
  새 프로젝트 시작 시 PLAN.md 작성·승인 및 로드맵 설정, 완료 태스크 아카이빙.
  "다음 뭐해", "어디까지 했지", "이어서", "계속해줘", "뭐 남았어", "상태 확인", "브리핑" 같은 요청 시 반드시 이 스킬 사용.
  .claude/tasks/ 디렉토리가 있는 프로젝트에서 작업할 때 항상 참조.
  사용하지 않는 경우: 1회성 단순 작업(5분 이내, 단일 파일), 질문/조사(코드 변경 없음), 독립적 핫픽스.
---

# 태스크 매니저

**디렉토리 구조가 태스크 상태의 단일 진실 공급원(SSOT).**

- `active/{로드맵}/pending/` — 대기 중
- `active/{로드맵}/in_progress/` — 작업 중
- `active/{로드맵}/completed/` — 완료

## 디렉토리 구조

```
.claude/
├── CLAUDE.md                              # 프로젝트 컨텍스트
└── tasks/
    ├── active/                            # 진행 중인 로드맵 (여러 개 가능)
    │   └── h2-migration/
    │       ├── PLAN.md                    # 요구사항 + Phase 구조 통합
    │       ├── pending/
    │       ├── in_progress/
    │       └── completed/
    └── completed/                         # 완료된 로드맵
        └── some-old-work/
            ├── PLAN.md
            └── ...
```

## 워크플로우 개요

- **새 로드맵** → 코드베이스 선스캔 → 인터뷰(모호함 해소까지) → PLAN.md 승인 → 태스크 파일 생성 → pending/ 이동
- **태스크 시작** → in_progress/ 이동 → 접근 방식 확인 → **implementer 서브에이전트에 구현 위임** → `/verifier` 스킬로 검증 → completed/ 이동
- **M/L 태스크** → 검증 체크리스트 제시 → 사용자 승인 필수 → 구현 위임

**2단 구조**: 메인 세션은 대화·계획·검증·커밋을 담당하고, 실제 코드 변경은 `implementer` 서브에이전트가 수행한다. 이 분리로 메인 컨텍스트가 구현 디테일로 오염되는 것을 방지한다.

상세 절차는 상황에 따라 아래 참조 파일을 Read한다:

| 상황 | 참조 파일 |
|------|----------|
| 새 로드맵 시작 (PLAN 인터뷰) | `references/plan-interview.md` |
| 태스크 시작/완료/접근 방식 확인 | `references/task-lifecycle.md` |
| `/brief`, 상태 확인, 브리핑 요청 | `references/brief-execution.md` |

## PLAN.md 포맷

새 로드맵의 PLAN은 아래 포맷으로 작성한다. 상세 인터뷰 절차는 `references/plan-interview.md` 참조.

```markdown
# {로드맵 이름}

## 배경
(왜 하는지, 제약조건)

## 요구사항
- R1. ...
- R2. ...

## Phase 1: {이름}
- R1 관련 태스크들

## Phase 2: {이름}
- R2 관련 태스크들

## 범위 밖
- ...
```

## 태스크 파일 포맷

```markdown
# [태스크 제목]

- phase: [N]
- size: [S/M/L]
- blocked_by: [파일명]  (없으면 생략)

## 목표
- 구현할 기능

## 완료 기준
- [ ] {주어}가 {동작}한다

## 검증 체크리스트 (M/L 태스크, 태스크 시작 시 생성)
- [ ] 원자적 검증 항목

## 컨텍스트 (선택)
- read: src/.../관련파일.kt
- tree: src/.../관련디렉토리/
```

상태 필드 없음. **파일이 어느 디렉토리에 있느냐 = 상태.**

| 필드 | 설명 |
|------|------|
| phase | 소속 Phase 번호 |
| size | S (< 1hr), M (1-4hr), L (4hr+) |
| blocked_by | 선행 태스크 파일명 (completed/에 있으면 unblocked) |
| 컨텍스트 | `read:` 파일 Read, `tree:` 디렉토리 Glob. in_progress/ 이동 직후 자동 로딩 |

파일명: `{번호}-{설명}.md`, 독립 태스크: `ind-{번호}-{설명}.md`, 긴급: `urgent-{번호}-{설명}.md`

## 병렬 실행

| 조건 | 처리 |
|------|------|
| 독립 태스크 ≤ 2개 | 순차 (기본) |
| 독립 태스크 ≥ 3개 + 모두 S/M + 파일 겹침 없음 | 경량 병렬 (Task run_in_background, 최대 3개) |
| 사용자가 명시 요청 | 팀 병렬 (TeamCreate) |

**의심스러우면 순차. TeamCreate는 사용자 요청 시에만.**

## 스크립트

| 스크립트 | 용도 |
|---------|------|
| `init_project.py` | .claude/ 구조 초기화 |
| `task_transition.py` | 태스크 완료 → 다음 시작 |

```bash
python3 ~/.claude/skills/task-manager/scripts/init_project.py <project-root>
```
