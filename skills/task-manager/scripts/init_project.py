#!/usr/bin/env python3
"""Initialize project with Task Manager structure (directory-based)."""

import argparse
from pathlib import Path

ROADMAP_TEMPLATE = '''# Roadmap

## Phase 1: (이름)
(목표 설명)

## Phase 2: (이름)
(목표 설명)
'''


def init_project(project_root: Path):
    """Initialize Task Manager structure."""
    claude_dir = project_root / '.claude'

    dirs = [
        claude_dir,
        claude_dir / 'tasks',
        claude_dir / 'tasks' / 'queue',
        claude_dir / 'tasks' / 'queue' / 'pending',
        claude_dir / 'tasks' / 'queue' / 'in_progress',
        claude_dir / 'tasks' / 'queue' / 'completed',
        claude_dir / 'tasks' / 'archive',
    ]

    for d in dirs:
        d.mkdir(parents=True, exist_ok=True)
        print(f"  생성: {d}")

    # ROADMAP.md
    roadmap_path = claude_dir / 'tasks' / 'ROADMAP.md'
    if not roadmap_path.exists():
        roadmap_path.write_text(ROADMAP_TEMPLATE, encoding='utf-8')
        print(f"  생성: {roadmap_path}")
    else:
        print(f"  건너뜀 (이미 존재): {roadmap_path}")

    # .gitkeep for empty queue directories
    for subdir in ['pending', 'in_progress', 'completed']:
        gitkeep = claude_dir / 'tasks' / 'queue' / subdir / '.gitkeep'
        if not gitkeep.exists():
            gitkeep.write_text('', encoding='utf-8')

    claude_md = claude_dir / 'CLAUDE.md'
    if not claude_md.exists():
        print(f"\n  CLAUDE.md가 없습니다. 프로젝트 정보를 작성하세요.")

    print(f"\n초기화 완료: {claude_dir}")
    print("\n다음 단계:")
    print("1. CLAUDE.md 작성 (기술 스택, 컨벤션)")
    print("2. ROADMAP.md 작성 (Phase별 목표)")
    print("3. queue/pending/에 태스크 파일 생성")
    print("4. /brief 실행")


def main():
    parser = argparse.ArgumentParser(description='Initialize Task Manager structure')
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
    exit(main())
