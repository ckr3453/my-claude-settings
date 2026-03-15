# my-claude-settings

Claude Code의 개인 설정 파일 모음입니다.
여러 머신에서 동일한 Claude Code 환경을 유지하기 위해 git으로 관리합니다.

## 구조

```
├── CLAUDE.md              # 글로벌 코딩 규칙 (TDD, 최소 변경 원칙 등)
├── settings.json          # Claude Code 설정 (hooks, permissions, language 등)
├── agents/                # 커스텀 서브에이전트 (10종)
├── hooks/                 # 도구 실행 전후 훅 스크립트
└── skills/                # 커스텀 스킬 (6종)
```

## CLAUDE.md

프로젝트 전반에 적용되는 코딩 원칙을 정의합니다.

- **TDD** — 서비스 로직/비즈니스 규칙은 테스트 먼저 (Red → Green → Refactor)
- **단순 설계** — Make it work, make it right, make it fast
- **최소 변경 원칙** — 요청과 직접 관련 없는 코드는 건드리지 않음
- **Workflow Rules** — 같은 파일 3회 편집 시 멈춤, 테스트 3회 실패 시 대안 제시

## Agents

특정 도메인에 특화된 서브에이전트 정의입니다. Claude Code가 `Agent` 도구 사용 시 자동으로 로드합니다.

| Agent | 역할 |
|-------|------|
| `api-designer` | REST/GraphQL API 아키텍처 설계, OpenAPI 명세 |
| `code-reviewer` | 코드 품질, 보안 취약점, 성능 최적화 리뷰 |
| `database-administrator` | PostgreSQL/MySQL/MongoDB/Redis 운영, 고가용성 |
| `debugger` | 복잡한 이슈 진단, 근본 원인 분석 |
| `java-architect` | Spring/Java 17+ 엔터프라이즈 애플리케이션 설계 |
| `kotlin-specialist` | Kotlin 코루틴, 멀티플랫폼, Android |
| `qa-expert` | 테스트 전략, 품질 메트릭, 자동화율 70%+ 목표 |
| `refactoring-specialist` | 안전한 코드 변환, 설계 패턴 적용, 복잡도 감소 |
| `spring-boot-engineer` | Spring Boot 3+ 마이크로서비스, 리액티브, 클라우드 네이티브 |
| `test-automator` | 테스트 프레임워크 설계, CI/CD 통합 |

## Hooks

도구 실행 전후에 자동으로 실행되는 검사 스크립트입니다.

| Hook | 트리거 | 역할 |
|------|--------|------|
| `completion-checker.sh` | `Stop` | 변경 파일 종합 검사 (빌드/린트, 경고 패턴, 레이어 분류) |
| `prompt_workflow_guide.sh` | `UserPromptSubmit` | 구현 작업 감지 시 plan mode 및 task-manager 사용 안내 |
| `post-tool-check.sh` | `PostToolUse` (Edit/Write/Bash) | 보안 패턴 차단, 파괴적 명령 경고 |
| `subagent-report-check.sh` | `SubagentStop` | 에이전트 완료 시 리뷰/QA/테스트 리마인더 |
| `config.sh` | - | 공통 설정 (차단 패턴, 경고 패턴, 임계값) |

## Skills

Claude Code에서 슬래시 명령(`/skill-name`)으로 호출하는 커스텀 스킬입니다.

### ai-trends-report

48시간 이내 AI 기술 트렌드를 수집/분석하여 이메일로 보고서를 전송합니다.
국내외 주요 AI 커뮤니티와 기사에서 핵심 이슈를 요약합니다.

### blog-writer

코딩 작업 경험을 캐주얼 에세이 스타일의 기술 블로그 포스트로 변환합니다.
- **Mode A** (`/blog`): git 이력 분석 기반
- **Mode B** (`/blog-interview`): 인터뷰 기반

### global-economy-report

48시간 이내 글로벌 경제 이슈를 수집/분석하여 이메일로 보고서를 전송합니다.
해외 주요 경제 매체와 국내 경제 뉴스를 분리하여 제공합니다.

### task-manager

장기 프로젝트의 태스크 상태를 디렉토리 기반(`pending/in_progress/completed`)으로 추적합니다.
- `/brief` — 현재 상태 확인
- 중단된 작업 재개, 로드맵 설정 지원

### tech-decision

기술 선택/비교를 돕는 스킬입니다. 인터뷰로 현황을 파악한 후
Stack Overflow, Reddit, Hacker News 등 커뮤니티의 실제 의견을 수집/분석하여 근거 기반 추천을 제공합니다.

### verifier

작업 결과를 요구사항 대비 증거 기반으로 검증합니다 (4단계 프로토콜).
1. 요구사항 분해 → 2. 코드 증거 대조 → 3. 변경 영향 리뷰 → 4. 정성적 코드 리뷰

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
