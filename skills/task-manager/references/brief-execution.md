# /brief 실행 절차

`/brief` 슬래시 명령 호출 시 현재 상태를 확인하고 다음 행동을 제안한다.

## 실행

```bash
python ~/.claude/skills/task-manager/scripts/brief.py <프로젝트 루트> [--json]
```

스크립트가 `.claude/tasks/`를 Glob 기반으로 집계하여 케이스(`uninitialized` / `empty` / `in_progress` / `all_complete`)와 로드맵별 진행률·blocked_by 상태를 반환한다.

- 기본 출력: 사람이 읽는 마크다운 — 사용자에게 그대로 전달
- `--json`: 구조화 JSON — LLM이 케이스별 행동 결정에 사용

## 케이스별 핵심 행동 (스크립트 출력 후)

| Case | 상황 | 핵심 행동 |
|------|------|----------|
| `uninitialized` | `.claude/tasks/` 없음 | `init_project.py` 실행 안내 |
| `empty` | `active/` 비어있음 | 새 로드맵 제안 (PLAN 인터뷰) |
| `in_progress` (미기록 작업 감지) | git log에는 있는데 태스크 기록 없음 | `completed/` 이동 제안 |
| `in_progress` (태스크 있음) | active/ 로드맵에 진행 중인 태스크 | 로드맵별 진행률 + 다음 태스크 제안 |
| `all_complete` | 모든 태스크 `completed/` | 로드맵 아카이빙 제안 |
