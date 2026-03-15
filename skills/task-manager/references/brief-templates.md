# /brief 상황별 응답 템플릿

## Case 1: 미초기화

```
브리핑

.claude/ 구조가 없습니다.

→ 초기화:
  python3 ~/.claude/skills/task-manager/scripts/init_project.py <project-root>
→ 그 다음 CLAUDE.md, ROADMAP.md를 작성하세요.
```

## Case 1.5: 구조 있지만 SPEC 없음

```
브리핑

프로젝트 구조는 있지만 SPEC.md가 없습니다.

CLAUDE.md: [있음/없음]

→ 스펙 인터뷰를 시작할까요? (요구사항 구체화 → SPEC.md → ROADMAP → 태스크)
```

## Case 2: 큐 비어있음

```
브리핑

프로젝트 구조는 있지만 태스크가 없습니다.

SPEC.md: [있음(승인됨) / 있음(미승인) / 없음]
ROADMAP.md: [있음/없음]

→ SPEC 없음: 스펙 인터뷰부터 시작
→ SPEC 미승인: SPEC.md 승인 대기
→ SPEC 승인됨 + ROADMAP 없음: ROADMAP.md 작성 제안
→ SPEC 승인됨 + ROADMAP 있음: 태스크 분해 제안
```

## Case 3: 미기록 작업 감지

```
브리핑

Phase: Phase 2B — Firestore 동기화

미기록 작업 감지:
   최근 커밋: feat(sync): implement TaskSyncService
   해당 태스크가 아직 completed/에 없습니다.

→ completed/로 이동할까요?
```

## Case 4: 태스크 있음

```
브리핑

Phase: Phase 2B — Firestore 동기화

대기: 4  |  진행 중: 1  |  완료: 7  (7/12)

진행 중:
   → 009-sync-repository.md (다른 세션 작업 중)

다음 대기:
   → 010-sync-conflict-resolver.md (M)

→ 다음 태스크를 시작할까요?
```

## Case 5: Phase 전체 완료

```
브리핑

Phase 2B: 모든 태스크 완료!

→ Phase 2B를 아카이빙하고 Phase 3으로 진행할까요?
  (단일 세션에서 실행 권장)
```

## Case 6: 로드맵 전체 완료

```
브리핑

Roadmap v1: 모든 Phase 완료!

Phase 1~6 (총 N개 태스크)

→ 로드맵 아카이빙 후 새 로드맵을 작성할까요?
  (자동으로 다음 Phase를 만들지 않습니다)
```
