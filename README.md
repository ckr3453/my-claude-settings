# my-claude-settings

Claude Code의 개인 설정 파일 모음 (agents, hooks, skills, settings).

여러 머신에서 동일한 Claude Code 환경을 유지하기 위해 관리합니다.

## 구조

```
├── CLAUDE.md                  # 글로벌 코딩 규칙 및 원칙
├── settings.json              # Claude Code 설정
├── agents/                    # 커스텀 서브에이전트 정의
├── hooks/                     # 도구 실행 전후 훅 스크립트
└── skills/                    # 커스텀 스킬
    ├── ai-trends-report/      # AI 트렌드 리포트 수집/발송
    ├── blog-writer/           # 코딩 작업 → 블로그 포스트 변환
    ├── global-economy-report/ # 글로벌 경제 리포트 수집/발송
    ├── task-manager/          # 장기 프로젝트 태스크 추적
    ├── tech-decision/         # 기술 선택 의사결정 지원
    └── verifier/              # 작업 결과 검증
```

## 사용법

`~/.claude/` 디렉토리에 이 레포의 내용을 배치합니다.

```bash
# 방법 1: 심링크
ln -s /path/to/my-claude-settings ~/.claude

# 방법 2: 복사
cp -r /path/to/my-claude-settings/* ~/.claude/
```

## 이메일 리포트 설정

`ai-trends-report`와 `global-economy-report` 스킬은 이메일 발송 기능을 포함합니다.

```bash
# config.json.example을 복사하여 실제 값을 입력
cp skills/ai-trends-report/scripts/config.json.example skills/ai-trends-report/scripts/config.json
cp skills/global-economy-report/scripts/config.json.example skills/global-economy-report/scripts/config.json
```

`config.json`은 `.gitignore`에 포함되어 커밋되지 않습니다.
