# /brief 실행 절차

사용자가 `/brief`, "브리핑", "상태 확인", "어디까지 했지" 등을 요청할 때 현재 상태를 확인하고 다음 행동을 제안한다.

## 실행 순서

```
1. .claude/tasks/ 존재 확인
2. CLAUDE.md 읽기
3. Glob active/*/PLAN.md → 각 로드맵 파악
4. Glob active/*/{pending,in_progress,completed}/*.md → 상태 집계
5. pending 중 blocked_by가 있는 파일만 Read
6. git log --oneline -5 (미기록 작업 감지)
7. 로드맵별 브리핑 + 다음 행동 제안
```

**핵심: Glob으로 상태 집계. 파일 내용은 최소한으로만 읽어 토큰 절약.**

## 케이스별 핵심 행동

| Case | 상황 | 핵심 행동 |
|------|------|----------|
| 1 | 미초기화 (.claude/tasks/ 없음) | `init_project.py` 안내 |
| 2 | active/ 비어있음 | 새 로드맵 제안 |
| 3 | 미기록 작업 감지 (git log에는 있는데 태스크 기록 없음) | completed/ 이동 제안 |
| 4 | 태스크 있음 | 로드맵별 진행률 + 다음 태스크 제안 |
| 5 | 로드맵 완료 (모든 태스크 completed/) | 아카이빙 제안 |
