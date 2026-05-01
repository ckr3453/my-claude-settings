---
name: verifier
description: |
  구현 결과를 요구사항 대비 증거 기반으로 검증한다.
  3단계 파이프라인(기계적 게이트 → Verifier 증거 대조 → Adversary 반박 검증)을 서브에이전트로 실행하여 메인 에이전트의 확증 편향과 컨텍스트 오염을 방지한다.
---

# 검증자 (Verifier)

## 파이프라인 개요

```
Stage 1: 기계적 게이트 (메인 에이전트가 스크립트 호출)
  → 빌드 + 테스트
  → FAIL 시 사용자에게 보고하고 멈춤

Stage 2: Verifier (verifier 서브에이전트)
  → 요구사항 분해 → 증거 대조 → 변경 영향 → 잔여물 점검
  → FAIL 시 사용자에게 보고하고 멈춤

Stage 3: Adversary (adversary 서브에이전트)
  → Verifier의 PASS 판정을 독립적으로 반박 시도
  → PASS를 FAIL로 내릴 수 있지만, FAIL을 PASS로 올릴 수 없음
```

각 단계 통과 시에만 다음 단계 진행. 어느 단계든 FAIL이면 전체 FAIL.

---

## Stage 1: 기계적 게이트

메인 에이전트가 `scripts/run-stage1.sh`를 호출한다.

```bash
bash ~/.claude/skills/verifier/scripts/run-stage1.sh <프로젝트 루트>
```

스크립트가 빌드 도구를 자동 감지하고 테스트를 실행한다. 결과는 stdout 한 줄 구조화 요약 + 종료 코드로 반환된다.

### 결과 처리

| 종료 코드 | 의미 | 메인 에이전트 행동 |
|---|---|---|
| 0 | PASS (빌드 + 테스트 통과) | Stage 2 진행. stdout 첫 줄을 Stage 2 프롬프트에 그대로 전달. |
| 1 | FAIL | **즉시 중단**. stdout 전체를 사용자에게 그대로 보고. Stage 2/3 호출하지 않는다. 수정은 verifier의 책임이 아니다. |
| 2 | SKIP (빌드 도구 미감지) | AskUserQuestion으로 진행 여부 확인 (아래 참조). |

**SKIP 시 AskUserQuestion:**

```
AskUserQuestion(
  question: "빌드 도구를 감지하지 못했습니다. 테스트 없이 코드 증거만으로 검증을 진행할까요?",
  header: "Stage 1 SKIP",
  options: [
    {label: "Stage 2 진행", description: "기계적 게이트 없이 verifier 서브에이전트가 코드 증거만으로 검증"},
    {label: "중단", description: "검증을 중단하고 사용자가 별도 처리"}
  ]
)
```

---

## Stage 2: Verifier (서브에이전트)

### 컨텍스트 수집

서브에이전트에게 넘길 컨텍스트를 준비한다:

1. **검증 대상** — 아래 중 해당하는 것을 수집:
   - 태스크 파일 경로 (`.claude/tasks/` 하위)
   - 태스크 파일이 없으면: 사용자의 원래 요청을 요약
2. **프로젝트 루트 경로**
3. **PLAN 경로** — `active/{로드맵}/PLAN.md`가 존재하면 경로 포함
4. **Stage 1 결과** — `run-stage1.sh` stdout 첫 줄

### 서브에이전트 생성

```
Agent(
  subagent_type: "verifier",
  description: "검증: {검증 대상 요약}",
  prompt: 아래 템플릿
)
```

**프롬프트 템플릿:**

```
## 검증 대상
- 프로젝트 루트: {프로젝트 루트 경로}
- 태스크 파일: {태스크 파일 경로 또는 "없음"}
- 사용자 요청: {태스크 파일이 없을 경우 원래 요청 요약}
- PLAN 경로: {PLAN 경로 또는 "없음"}

## Stage 1 (기계적 게이트) 결과
{run-stage1.sh stdout 첫 줄 — 예: "Stage 1 PASS — gradle (./gradlew test), 12s"}
재실행하지 마세요.

## 검증 프로토콜
`~/.claude/skills/verifier/verifier-prompt.md`를 Read하고 거기 명시된 4단계 절차(요구사항 분해 → 증거 대조 → 변경 영향 → 잔여물 점검)와 보고 형식을 정확히 따르세요.

## 출력
프로토콜에 명시된 형식으로 검증 결과 보고서를 반환하세요.
```

### 결과 처리

- **FAIL** → 즉시 중단. Verifier 보고서를 사용자에게 그대로 전달하고 멈춘다.
- **PASS** → Verifier 보고서를 보존하고 Stage 3으로 진행.

---

## Stage 3: Adversary (서브에이전트)

Verifier가 PASS를 준 경우에만 실행한다.

### 서브에이전트 생성

```
Agent(
  subagent_type: "adversary",
  description: "반박 검증: {검증 대상 요약}",
  prompt: 아래 템플릿
)
```

**프롬프트 템플릿:**

```
## 검증 대상
- 프로젝트 루트: {프로젝트 루트 경로}
- 태스크 파일: {태스크 파일 경로 또는 "없음"}
- 사용자 요청: {태스크 파일이 없을 경우 원래 요청 요약}

## Verifier 보고서
{Stage 2 Verifier의 전체 보고서를 여기에 붙여넣기}

## 반박 프로토콜
`~/.claude/skills/verifier/adversary-prompt.md`를 Read하고 거기 명시된 5가지 반박 관점(증거 재검증, 테스트 품질, 누락 요구사항, 변경 영향 재검토, 통합 관점)과 보고 형식을 정확히 따르세요.

## 출력
프로토콜에 명시된 형식으로 반박 검증 결과 보고서를 반환하세요.
```

### 결과 처리

- **Adversary가 FAIL 항목을 발견** → 전체 FAIL. 보고서를 사용자에게 그대로 전달하고 멈춘다.
- **Adversary가 반박 실패 (PASS 유지)** → 최종 PASS.

---

## 최종 처리

사용자에게 아래를 그대로 전달한다:

1. **Stage 1 결과** (`run-stage1.sh` 출력)
2. **Stage 2 Verifier 보고서** (재해석 금지)
3. **Stage 3 Adversary 보고서** (재해석 금지)
4. **최종 판정**: 3단계 모두 통과 시 PASS, 하나라도 실패 시 FAIL

---

## 금지 사항

- 어느 Stage든 FAIL 시 메인 에이전트가 자동 수정을 시도하지 않는다 — 사용자에게 보고하고 멈춘다
- 서브에이전트의 FAIL 판정을 메인 에이전트가 PASS로 뒤집지 않는다
- 검증 결과를 요약하거나 긍정적으로 재해석하지 않는다
