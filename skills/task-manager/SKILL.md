---
name: task-manager
description: |
  .claude/tasks/ 디렉토리 기반으로 장기 프로젝트의 로드맵·태스크 상태를 추적한다.
  PLAN.md 작성, 태스크 파일 생성/분해, pending→in_progress→completed 폴더 이동으로 상태 전이, 진행률 집계, /brief 실행을 담당.
  1회성 단순 작업, 질문/조사, 독립 핫픽스에는 사용하지 않는다.
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash(python *)", "Task", "AskUserQuestion"]
---

# 태스크 매니저

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

## 참조 파일

상황에 따라 아래 파일을 Read한다:

| 상황 | 참조 파일 |
|------|----------|
| 새 로드맵 시작 (PLAN 인터뷰) | `references/plan-interview.md` |
| 태스크 시작/완료/접근 방식 확인 | `references/task-lifecycle.md` |
| `/brief` 호출 | `references/brief-execution.md` |

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

| 필드 | 설명 |
|------|------|
| phase | 소속 Phase 번호 |
| size | S (< 1hr), M (1-4hr), L (4hr+) |
| blocked_by | 선행 태스크 파일명 (completed/에 있으면 unblocked) |
| 컨텍스트 | `read:` 파일 Read, `tree:` 디렉토리 Glob. in_progress/ 이동 직후 자동 로딩 |

파일명: `{번호}-{설명}.md`, 독립 태스크: `ind-{번호}-{설명}.md`, 긴급: `urgent-{번호}-{설명}.md`

## 스크립트

| 스크립트 | 용도 | 호출 시점 |
|---------|------|----------|
| `init_project.py` | `.claude/tasks/{active,completed}/` 구조 초기화 | brief 결과가 `uninitialized`일 때 사용자 안내 |
| `task_transition.py` | `in_progress/` → `completed/` 이동 + 다음 unblocked 태스크 → `in_progress/` | 사용자가 "태스크 완료 처리" 명시 시 |
| `brief.py` | `.claude/tasks/` 상태 집계 (Glob 기반) → 케이스 + 로드맵별 진행률 반환 | `/brief` 호출 시 |

```bash
python ~/.claude/skills/task-manager/scripts/brief.py <project-root>
python ~/.claude/skills/task-manager/scripts/init_project.py <project-root>
python ~/.claude/skills/task-manager/scripts/task_transition.py <project-root>
```
