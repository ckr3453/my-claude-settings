# 시작하기

## 신규 프로젝트

```
1. init_project.py <project-root>      → .claude/tasks/ 구조 생성
2. CLAUDE.md 작성                        → 기술 스택, 아키텍처, 컨벤션
3. PLAN 인터뷰 (AskUserQuestion)        → 최소 3라운드 질문
4. PLAN.md 작성 + 승인                   → 요구사항 + Phase 구조 확정
5. Phase 1 태스크 분해 → pending/        → 태스크 파일 생성
6. /brief                                → 첫 태스크 확인 후 시작
```

## 기존 프로젝트

```
1. init_project.py <project-root>      → .claude/tasks/ 구조 생성
2. CLAUDE.md 작성                        → 코드베이스 분석 후 정리
3. PLAN 인터뷰 (AskUserQuestion)        → 기존 맥락 + 이슈 파악
4. PLAN.md 작성 + 승인                   → 요구사항 + Phase 구조 확정
5. Phase 1 태스크 분해 → pending/        → 태스크 파일 생성
6. /brief                                → 첫 태스크 확인 후 시작
```

## 산발적 요청 처리

진행 중 산발적 요청이 들어오면:
- **긴급** → pending/에 `urgent-` 접두사로 태스크 파일 생성
- **비긴급** → pending/에 `ind-` 접두사로 독립 태스크 파일 생성
