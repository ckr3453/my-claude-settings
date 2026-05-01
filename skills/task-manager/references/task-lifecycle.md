# 태스크 라이프사이클

## 1. 태스크 시작

`task_transition.py`(인자 없이) 또는 Stage 6의 호출 결과로 `in_progress/`에 태스크 파일이 들어와 있는 상태에서 시작.

1. 태스크 파일의 컨텍스트 필드(`read:`, `tree:`)가 있으면 로딩
2. 사이즈별로 접근 방식 확인 (Stage 2)

## 2. 태스크 시작 전 접근 방식 확인

사이즈별로 확인 깊이가 다르다:

- **S 태스크**: "이 메서드를 수정하면 될 것 같은데, 진행할까요?" 수준
- **M 태스크**: 관련 코드 탐색 → 접근법 제시 → 승인 후 실행
- **L 태스크**: 사용자와 대화로 요구사항 구체화 → 세부 태스크로 분해 → pending/에 추가

## 3. 검증 체크리스트 생성 (M/L 태스크)

접근 방식 확인 시, 완료 기준을 원자적 검증 항목으로 분해하여 사용자에게 제시한다.

**사용자 승인은 반드시 `AskUserQuestion`으로 받는다:**

```
AskUserQuestion(
  question: "검증 체크리스트가 적절한가요?\n{체크리스트 목록}",
  header: "체크리스트",
  options: [
    {label: "승인", description: "이대로 implementer에 위임"},
    {label: "수정 필요", description: "체크리스트를 다시 다듬는다"},
    {label: "취소", description: "태스크를 in_progress/에서 pending/으로 되돌린다"}
  ]
)
```

승인된 체크리스트를 태스크 파일 `## 검증 체크리스트` 섹션에 기록한 후에만 implementer 위임을 시작한다.
완료 기준이 이미 원자적이면 (S 태스크 등) 이 단계 생략.

## 4. 구현 위임 (implementer 서브에이전트)

실제 코드 변경은 메인 세션이 직접 하지 않고 `implementer` 서브에이전트에게 위임한다.

```
Task(
  subagent_type: "implementer",
  description: "{태스크 제목}",
  prompt: 아래 템플릿
)
```

**프롬프트 템플릿:**

```
## 태스크 파일
{in_progress/*.md 태스크 파일 경로}

## 요구사항
{태스크 파일의 "목표" 및 "완료 기준" 섹션}

## 검증 체크리스트
{승인된 원자적 항목들, 없으면 "없음"}

## 프로젝트 컨텍스트
- 루트: {프로젝트 루트 경로}
- 관련 파일: {태스크 파일의 "컨텍스트" 섹션에 명시된 read/tree}

구현 완료 후 변경 파일 목록과 요약을 반환하세요.
```

서브에이전트 종료 후:
- **완료 보고** → Stage 5(태스크 완료)로 진행
- **막힘 보고** → 사용자에게 상황 보고 + 다음 행동 논의. (막힘 신호 정의는 `~/.claude/agents/implementer.md`의 "막히면 멈춘다" 섹션 참조)

## 5. 태스크 완료 후 처리

implementer 완료 보고를 사용자에게 그대로 전달한다. 검증 진행 여부 / 재위임 / 다음 행동은 메인 에이전트(또는 사용자)가 결정한다 — **task-manager는 검증 단계에 직접 관여하지 않는다**.

(implementer 종료 시 hook이 메인 에이전트에게 검증 안내 메시지를 주입한다. task-manager는 그 흐름에 끼어들지 않는다.)

검증이 완료되었거나 사용자가 "이 태스크 완료 처리"를 명시한 시점에 `task_transition.py`로 상태 전이:

```bash
python ~/.claude/skills/task-manager/scripts/task_transition.py <프로젝트 루트> --complete-only
```

스크립트가 `in_progress/`의 태스크를 `completed/`로 이동하고 완료일을 파일 하단에 기록한다.

## 6. 다음 태스크 시작 여부 확인

태스크 완료 처리 후 `pending/`에 unblocked 태스크가 남아있으면, 자동으로 시작하지 않고 사용자에게 묻는다:

```
AskUserQuestion(
  question: "다음 태스크 '{태스크 제목}'을 시작할까요?",
  header: "다음 태스크",
  options: [
    {label: "시작", description: "in_progress/로 이동하고 접근 방식 확인 단계로 진입"},
    {label: "나중에", description: "여기서 멈춘다"},
    {label: "다른 태스크 선택", description: "pending/ 목록을 보여주고 사용자가 지정"}
  ]
)
```

"시작" 선택 시:
```bash
python ~/.claude/skills/task-manager/scripts/task_transition.py <프로젝트 루트>
```
(인자 없이 호출하면 in_progress/ 비어있음을 확인하고 다음 unblocked 태스크를 in_progress/로 이동)

## 7. 로드맵 완료

모든 태스크가 `completed/`에 있을 때 (Stage 6에서 다음 unblocked 태스크가 없는 시점):

```bash
python ~/.claude/skills/task-manager/scripts/task_transition.py <프로젝트 루트> --archive-roadmap <로드맵명>
```

스크립트가 PLAN.md의 모든 `## Phase N:` 헤더 끝에 ✅를 추가하고 `active/{로드맵}/` → `completed/{로드맵}/`로 이동한다.
