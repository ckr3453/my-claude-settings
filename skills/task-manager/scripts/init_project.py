#!/usr/bin/env python3
"""task-manager 프로젝트 초기화 — .claude/tasks/{active,completed} 구조 생성."""

import argparse
import sys
from pathlib import Path


def init_project(project_root: Path) -> None:
    claude_dir = project_root / '.claude'

    dirs = [
        claude_dir,
        claude_dir / 'tasks',
        claude_dir / 'tasks' / 'active',
        claude_dir / 'tasks' / 'completed',
    ]

    for d in dirs:
        d.mkdir(parents=True, exist_ok=True)
        print(f"  생성: {d}")

    for sub in ['active', 'completed']:
        gk = claude_dir / 'tasks' / sub / '.gitkeep'
        if not gk.exists():
            gk.write_text('', encoding='utf-8')

    claude_md = claude_dir / 'CLAUDE.md'
    if not claude_md.exists():
        print(f"\n  CLAUDE.md가 없습니다. 프로젝트 정보를 작성하세요.")

    print(f"\n초기화 완료: {claude_dir}")
    print("\n다음 단계:")
    print("1. CLAUDE.md 작성 (기술 스택, 컨벤션)")
    print("2. /prd 또는 PLAN 인터뷰로 첫 로드맵 시작")
    print("   (로드맵별 폴더는 active/{로드맵}/ 구조로 PLAN 인터뷰 후 생성)")


def main() -> int:
    parser = argparse.ArgumentParser(description='Initialize task-manager structure')
    parser.add_argument('project_root', nargs='?', default='.',
                        help='Project root directory (default: current)')
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()

    if not project_root.exists():
        print(f"디렉토리 없음: {project_root}")
        return 1

    init_project(project_root)
    return 0


if __name__ == '__main__':
    sys.exit(main())
