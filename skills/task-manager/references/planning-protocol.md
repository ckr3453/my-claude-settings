# 계획 프로토콜 (인터뷰 → 스펙 → 분해)

새 프로젝트 또는 새 로드맵 시작 시 전체 플로우.

---

## 인터뷰

1. 사용자 요청 수신 (새 프로젝트 또는 새 로드맵)
2. 최소 3라운드 적응적 질문 (`interview-framework.md`)
3. 라운드 사이에 코드베이스 탐색 (Glob/Read)

## 스펙 결정화

4. SPEC.md 초안 작성 → 사용자에게 제시
5. 사용자 승인 또는 수정 요청 (최대 3회 리비전)
6. `approved: YYYY-MM-DD` 기록 → `.claude/tasks/SPEC.md` 저장

## 분해

7. 각 AC → 1개 이상의 태스크로 분해
8. Phase 그룹핑 → ROADMAP.md 작성
9. 의존성 매핑 (blocked_by) → pending/에 태스크 생성
10. 사용자 최종 승인

---

## 핵심 규칙

- **SPEC.md 승인 전 태스크 생성 금지**
- SPEC.md는 승인 후 불변. 요구사항 변경 시 SPEC-v2.md 생성
- 1회성 단순 작업에는 이 프로토콜 생략

---

## SPEC.md 템플릿

```markdown
# Spec: [프로젝트/기능명]

approved: [YYYY-MM-DD / 미승인]

## 본질 (Essence)
[1-2문장. 표면적 요청이 아닌 실제 달성 목표]

## 범위 (Scope)
### 포함
- [구체적 포함 항목]

### 제외
- [명시적 제외 항목]

## 제약 (Constraints)
- [기술: 언어, 프레임워크, 인프라]
- [시간/리소스]
- [호환성]

## 수용 기준 (Acceptance Criteria)
- [ ] [검증 가능한 동사로 끝나는 기준]
- [ ] ...

## 인터뷰 로그
### Q1: [질문]
A: [답변 요약]
...
```

## 아카이빙

로드맵 아카이빙 시 SPEC.md를 `archive/roadmap-v{N}/SPEC.md`로 함께 이동.
