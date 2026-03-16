# 태스크 파일 포맷

## 파일명 규칙

```
{번호}-{간략한-설명}.md

ind-{번호}-{설명}.md          # 독립 태스크
urgent-{번호}-{설명}.md       # 긴급 태스크
```

## 템플릿

```markdown
# [태스크 제목]

- phase: [N]
- size: [S/M/L]
- blocked_by: [파일명]  (없으면 생략)

## 목표
- 구현할 기능 1
- 구현할 기능 2

## 완료 기준
- 검증 가능한 동사로 끝나야 함
- [ ] {주어}가 {동작}한다  (예: GET /v1/users가 200을 반환한다)

## 검증 체크리스트 (M/L 태스크, 태스크 시작 시 생성)
- [ ] SwlPipeController에 GET 매핑이 존재한다
- [ ] SwlPipeService에 조회 메서드가 존재한다
- [ ] 정상 응답 시 200 + 데이터를 반환한다
- [ ] SwlPipeServiceTest가 존재하고 통과한다

## 컨텍스트 (선택)
- read: src/.../관련파일.kt
- tree: src/.../관련디렉토리/

## 메모
(작업 중 메모, 없으면 생략)

completed: YYYY-MM-DD  (완료 시 추가)
```

## 필드 설명

| 필드 | 필수 | 설명 |
|------|------|------|
| phase | O | 소속 Phase 번호 |
| size | O | S (< 1hr), M (1-4hr), L (4hr+) |
| blocked_by | X | 선행 태스크 파일명 (해당 태스크가 completed/에 있으면 unblocked) |
| 목표 | O | 이 태스크가 달성할 것 |
| 완료 기준 | O | 검증 가능한 동사로 끝나야 함 |
| 검증 체크리스트 | X | 태스크 시작 시 완료 기준에서 분해, 사용자 승인 후 기록. S 태스크는 생략 가능 |
| 컨텍스트 | X | 태스크 시작 시 자동 로딩할 파일/디렉토리 목록 |
| 메모 | X | 작업 중 메모 |
| completed | X | 완료일 (completed/로 이동 시 추가) |

## 컨텍스트 섹션

태스크 시작 시 관련 파일을 자동 로딩하기 위한 선택적 섹션입니다.

```markdown
## 컨텍스트
- read: src/main/kotlin/.../SomeService.kt
- read: src/main/kotlin/.../SomeEntity.kt
- tree: src/main/kotlin/.../domain/some/
```

- `read:` — 해당 파일을 Read로 읽음
- `tree:` — 해당 디렉토리를 Glob으로 구조 파악

**태스크를 `in_progress/`로 이동한 직후, 컨텍스트 섹션의 항목을 자동 로딩합니다.**
새 세션에서 재개할 때도 동일하게 로딩합니다.

## 복잡도 기준

| 수준 | 예상 파일 수 | 설명 |
|------|-------------|------|
| S | 1-2 | 단일 엔티티 또는 간단한 엔드포인트 |
| M | 3-5 | API + 서비스 레이어 |
| L | 5-8 | 여러 연관 API (분할 검토) |

## blocked_by 해석

`blocked_by`에 명시된 파일이 `completed/` 디렉토리에 존재하면 unblocked로 판단합니다.

```
/brief 시:
1. Glob active/*/pending/*.md
2. blocked_by가 있는 파일만 Read
3. blocked_by 파일이 active/*/completed/에 있는지 Glob으로 확인
4. 없으면 blocked → 건너뜀
5. 있으면 unblocked → 실행 가능
```
