# my-claude-settings

Claude Code의 개인 설정 파일 모음입니다.
여러 머신에서 동일한 Claude Code 환경을 유지하기 위해 git으로 관리합니다.

## 구조

```
├── CLAUDE.md              # 글로벌 코딩 규칙 (TDD, 최소 변경 원칙 등)
├── settings.json          # Claude Code 설정 (hooks, permissions, language 등)
├── agents/                # 커스텀 서브에이전트 (현재 0종, 10종 _archive)
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

### 프로젝트별 패턴 추가

프로젝트 루트에 `.claude/hooks/config.sh`를 만들면 언어별 패턴을 추가할 수 있습니다:

```bash
# .claude/hooks/config.sh (프로젝트 레벨)
EXTRA_CRITICAL_PATTERNS=(
  'eval\(|exec\( | 임의 코드 실행'
)
EXTRA_WARNING_PATTERNS=(
  'System\.out | 디버그 출력 잔존'
  'Thread\.sleep | 하드코딩 슬립'
)
```

## Agents

범용 직군형 에이전트 10종은 `_archive/`로 이동했습니다. 빌트인 subagent_type(Explore, Plan 등)으로 충분하며, 필요 시 구체적 용도의 에이전트를 추가합니다.

## Skills

Claude Code에서 슬래시 명령(`/skill-name`)으로 호출하는 커스텀 스킬입니다.

| 스킬 | 명령 | 용도 |
|------|------|------|
| **verifier** | `/verify` | 요구사항 대비 4단계 증거 기반 검증. PASS 시 자동 커밋 |
| **task-manager** | `/brief`, `/task-manager` | 디렉토리 기반 태스크 추적. PLAN 인터뷰 → 태스크 분해 → 순차 실행 |
| **blog-writer** | `/blog`, `/blog-interview` | git 이력 또는 인터뷰 기반 기술 블로그 포스트 생성 |
| **tech-decision** | `/tech-decision` | 커뮤니티 의견 기반 기술 선택 의사결정 지원 |
| **ai-trends-report** | `/ai-trends-report` | AI 기술 트렌드 수집/분석 이메일 보고서 |
| **global-economy-report** | `/global-economy-report` | 글로벌 경제 이슈 수집/분석 이메일 보고서 |

## 기본 워크플로우

```
작업 요청 → 구현 (훅이 자동 보호) → completion-checker(자동) → /verify → 커밋
```

장기 작업은 `/task-manager`로 로드맵을 세운 후 태스크 단위로 진행합니다.

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
