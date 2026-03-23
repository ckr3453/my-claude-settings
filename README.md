# my-claude-settings

Claude Code의 개인 설정 파일 모음입니다.
여러 머신에서 동일한 Claude Code 환경을 유지하기 위해 git으로 관리합니다.

## 구조

```
├── CLAUDE.md              # 글로벌 코딩 규칙 (TDD, 최소 변경 원칙 등)
├── settings.json          # Claude Code 설정 (hooks, permissions, language 등)
├── agents/                # 커스텀 에이전트 (1종 + 10종 _archive)
├── hooks/                 # 도구 실행 전후 훅 스크립트 (4종)
└── skills/                # 커스텀 스킬 (6종)
```

## 설계 원칙

- **훅 중심**: 자동화할 수 있는 것은 훅으로. 에이전트/스킬은 최소한으로
- **언어 무관**: 글로벌 설정은 특정 언어에 종속되지 않음. 언어별 패턴은 프로젝트 config에서 추가
- **SKILL.md 우선**: 스킬 동작에 필수적인 규칙은 SKILL.md에 직접 포함. references는 큰 참조 데이터에만 사용

## CLAUDE.md

프로젝트 전반에 적용되는 코딩 원칙을 정의합니다.

- **TDD** — 서비스 로직/비즈니스 규칙은 테스트 먼저 (Red → Green → Refactor)
- **단순 설계** — Make it work, make it right, make it fast
- **최소 변경 원칙** — 요청과 직접 관련 없는 코드는 건드리지 않음
- **Workflow Rules** — 같은 파일 3회 편집 시 멈춤, 테스트 3회 실패 시 대안 제시

## Hooks

도구 실행 전후에 자동으로 실행되는 검사 스크립트입니다.

| Hook | 트리거 | 역할 |
|------|--------|------|
| `post-tool-check.sh` | `PostToolUse` (Edit/Write/Bash) | 보안 패턴 차단 (시크릿, 권한 상승 등), 파괴적 명령 경고, 변경 파일 기록 |
| `tool-failure-tracker.sh` | `PostToolUseFailure` (*) | 60초 윈도우 내 반복 실패 감지. Edit 3회/Bash 3회/전체 5회 시 stagnation 경고 주입 |
| `completion-checker.sh` | `Stop` | 변경 파일 종합 검사 (빌드 자동감지, 경고 패턴), 이슈 리포트 |
| `config.sh` | - | 공통 설정 (차단/경고 패턴, SKIP 확장자, 프로젝트별 오버라이드 지원) |

### 프로젝트별 오버라이드

프로젝트 루트에 `.claude/hooks/` 파일을 만들면 검사 패턴과 빌드/린트 명령을 오버라이드할 수 있습니다:

```bash
# .claude/hooks/config.sh — 검사 패턴 추가
EXTRA_CRITICAL_PATTERNS=(
  'eval\(|exec\( | 임의 코드 실행'
)
EXTRA_WARNING_PATTERNS=(
  'System\.out | 디버그 출력 잔존'
  'Thread\.sleep | 하드코딩 슬립'
)
```

```bash
# .claude/hooks/commands.sh — 빌드/린트 명령 오버라이드
BUILD_CMD="./gradlew build -x test 2>&1"
LINT_CMD="./gradlew ktlintCheck 2>&1"
```

## Agents

범용 직군형 에이전트 10종은 `_archive/`로 이동했습니다. 빌트인 subagent_type(Explore, Plan 등)으로 충분하며, 독립 컨텍스트가 필요한 경우에만 커스텀 에이전트를 사용합니다.

| 에이전트 | 용도 |
|---------|------|
| **examiner** | PLAN.md 비판적 검토. 독립 컨텍스트에서 논리적 허점, 빠진 전제, 실패 가능성을 다양한 관점으로 검토 |

## Skills

Claude Code에서 슬래시 명령(`/skill-name`)으로 호출하는 커스텀 스킬입니다.

| 스킬 | 명령 | 용도 |
|------|------|------|
| **verifier** | `/verify` | 요구사항 대비 4단계 증거 기반 검증. PASS 시 자동 커밋 |
| **task-manager** | `/brief`, `/task-manager` | 디렉토리 기반 태스크 추적. 코드베이스 선스캔 → 소크라테스식 인터뷰 → 태스크 분해 → 순차 실행 |
| **blog-writer** | `/blog`, `/blog-interview` | git 이력 또는 인터뷰 기반 기술 블로그 포스트 생성 |
| **tech-decision** | `/tech-decision` | 커뮤니티 의견 기반 기술 선택 의사결정 지원 |
| **ai-trends-report** | `/ai-trends-report` | AI 기술 트렌드 수집/분석 이메일 보고서 |
| **global-economy-report** | `/global-economy-report` | 글로벌 경제 이슈 수집/분석 이메일 보고서 |

## 워크플로우

```
요청 → TDD 사이클 (CLAUDE.md) + 보안/실패 감지 (훅) → completion-checker → /verify → 커밋
```

### 단계별 흐름

**1. 작업 요청**

단순 작업은 바로 요청합니다. 장기 작업은 `/brief`로 태스크를 분해한 후 순차 진행합니다. 새 로드맵 시작 시 코드베이스 선스캔 → 소크라테스식 인터뷰(최소 3라운드, 확인형 질문 + 가정 뒤집기) → PLAN.md 작성 → `examiner` 에이전트로 비판적 검토(선택) → 승인 → 태스크 분해.

CLAUDE.md의 "목표 기반 실행"에 따라 요청은 검증 가능한 목표로 변환됩니다:
- "유효성 검사 추가" → "잘못된 입력에 대한 테스트 작성 후 통과시키기"
- "버그 수정" → "재현 테스트 작성 후 통과시키기"

**2. 구현**

CLAUDE.md 규칙에 따라 TDD 사이클(Red → Green → Refactor)을 진행합니다. 이와 별도로, 매 Edit/Write/Bash마다 훅이 자동 실행됩니다:

| 시점 | 동작 |
|------|------|
| Edit/Write 직후 | `post-tool-check` — 보안 패턴 차단 + 변경 파일 누적 기록 |
| Bash 직후 | `post-tool-check` — 파괴적 명령(`rm -rf /`, `push --force` 등) 경고 |
| 도구 실패 시 | `tool-failure-tracker` — 60초 내 반복 실패 감지 → stagnation 경고 주입, 접근 전환 강제 |

**3. 완료 검사 (자동)**

Claude가 작업을 마치고 멈추면 `completion-checker`가 자동 실행됩니다:

1. **빌드** — gradlew / pom.xml / package.json 자동 감지 후 실행 (프로젝트 `commands.sh`로 오버라이드 가능)
2. **경고 패턴** — 변경 파일에서 TODO/FIXME, 린터 비활성화 등 검사
3. **레이어 분류** — 변경 파일을 서비스/API/데이터/테스트/설정 레이어로 분류하여 리포트

결과에 따라:
- 이슈 0건 → 훅이 Claude에게 `/verify` 실행을 지시 → Claude가 `/verify` 실행
- 이슈 N건 → 이슈 리포트 출력 → Claude가 수정 → 다시 완료 검사 → 이슈 0건이면 `/verify`

**4. 검증 → 커밋**

`/verify`가 4단계 검증(요구사항 분해 → 코드 증거 대조 → 변경 영향 리뷰 → 코드 리뷰)을 수행합니다. PASS 시 자동 커밋됩니다.


## 사용법

### 설치

`~/.claude/` 디렉토리에 이 레포의 내용을 배치합니다.

```bash
# 방법 1: 심링크 (권장)
ln -s /path/to/my-claude-settings ~/.claude

# 방법 2: 복사
cp -r /path/to/my-claude-settings/* ~/.claude/
```

### 이메일 리포트 설정

`ai-trends-report`와 `global-economy-report` 스킬은 SMTP를 통한 이메일 발송 기능을 포함합니다.

```bash
# config.json.example을 복사하여 실제 값을 입력
cp skills/ai-trends-report/scripts/config.json.example skills/ai-trends-report/scripts/config.json
cp skills/global-economy-report/scripts/config.json.example skills/global-economy-report/scripts/config.json
```

`config.json`은 `.gitignore`에 포함되어 커밋되지 않습니다.
