#!/usr/bin/env python3
"""태스크 상태 전이 — active/{로드맵}/{pending,in_progress,completed}/ 멀티 로드맵 구조.

Usage:
  python3 task_transition.py [project-root] [--roadmap NAME] [--complete-only] [--task FILENAME]

동작:
  --complete-only 없으면: in_progress/ 태스크를 completed/로 이동 → pending/ 다음 태스크를 in_progress/로 이동
  --complete-only:        완료만, 다음 시작 안 함
  --roadmap NAME:         특정 로드맵 지정. 없으면 in_progress/에 태스크가 있는 첫 로드맵 자동 선택.
"""

import argparse
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path


def get_task_metadata(task_path: Path) -> dict:
    content = task_path.read_text(encoding='utf-8')
    meta = {'blocked_by': None, 'phase': None, 'size': None}
    for line in content.split('\n'):
        line = line.strip()
        if line.startswith('- blocked_by:'):
            meta['blocked_by'] = line.split(':', 1)[1].strip()
        elif line.startswith('- phase:'):
            meta['phase'] = line.split(':', 1)[1].strip()
        elif line.startswith('- size:'):
            meta['size'] = line.split(':', 1)[1].strip()
    return meta


def is_unblocked(task_path: Path, completed_dir: Path) -> bool:
    meta = get_task_metadata(task_path)
    if not meta['blocked_by']:
        return True
    return (completed_dir / meta['blocked_by'].strip()).exists()


def find_roadmap_dir(project_root: Path, roadmap: str | None) -> Path | None:
    """로드맵 디렉토리 찾기. 인자로 받은 게 있으면 우선, 없으면 자동 감지."""
    active_dir = project_root / '.claude' / 'tasks' / 'active'
    if not active_dir.exists():
        return None

    if roadmap:
        rd = active_dir / roadmap
        return rd if rd.exists() else None

    candidates = sorted([d for d in active_dir.iterdir() if d.is_dir()])

    # 자동 감지 1: in_progress/에 태스크 있는 로드맵 우선
    for rd in candidates:
        ip = rd / 'in_progress'
        if ip.exists() and any(f.suffix == '.md' for f in ip.iterdir()):
            return rd

    # 자동 감지 2: pending/에 태스크 있는 로드맵
    for rd in candidates:
        pd = rd / 'pending'
        if pd.exists() and any(f.suffix == '.md' for f in pd.iterdir()):
            return rd

    return candidates[0] if candidates else None


def select_next_task(pending_dir: Path, completed_dir: Path) -> Path | None:
    tasks = sorted(pending_dir.glob('*.md'))
    for task in tasks:
        if task.name == '.gitkeep':
            continue
        if is_unblocked(task, completed_dir):
            return task
    return None


def complete_task(roadmap_dir: Path, task_name: str | None = None) -> str | None:
    in_progress = roadmap_dir / 'in_progress'
    completed = roadmap_dir / 'completed'

    if not in_progress.exists():
        print(f"  in_progress/ 없음: {roadmap_dir}")
        return None

    if task_name:
        task_file = in_progress / task_name
        if not task_file.exists():
            print(f"  in_progress/에 태스크 없음: {task_name}")
            return None
    else:
        tasks = [f for f in in_progress.glob('*.md') if f.name != '.gitkeep']
        if not tasks:
            print("  in_progress/에 태스크 없음")
            return None
        task_file = tasks[0]

    completed.mkdir(parents=True, exist_ok=True)
    dest = completed / task_file.name

    content = task_file.read_text(encoding='utf-8')
    if 'completed:' not in content:
        content = content.rstrip() + f"\n\ncompleted: {datetime.now().strftime('%Y-%m-%d')}\n"
        task_file.write_text(content, encoding='utf-8')

    shutil.move(str(task_file), str(dest))
    print(f"  완료: {roadmap_dir.name}/{task_file.name}")
    return task_file.name


def start_next_task(roadmap_dir: Path) -> str | None:
    pending = roadmap_dir / 'pending'
    in_progress = roadmap_dir / 'in_progress'
    completed = roadmap_dir / 'completed'

    if not pending.exists():
        print(f"  pending/ 없음: {roadmap_dir}")
        return None

    current = [f for f in in_progress.glob('*.md') if f.name != '.gitkeep'] if in_progress.exists() else []
    if current:
        print(f"  이미 진행 중: {current[0].name}")
        return None

    next_task = select_next_task(pending, completed if completed.exists() else pending)
    if not next_task:
        print("  pending/에 실행 가능한 태스크 없음")
        return None

    in_progress.mkdir(parents=True, exist_ok=True)
    dest = in_progress / next_task.name
    shutil.move(str(next_task), str(dest))
    print(f"  시작: {roadmap_dir.name}/{next_task.name}")
    return next_task.name


def archive_roadmap(project_root: Path, roadmap_name: str) -> int:
    """완료된 로드맵을 active/ → completed/로 이동 + PLAN.md Phase 헤더에 ✅."""
    active_dir = project_root / '.claude' / 'tasks' / 'active'
    completed_dir = project_root / '.claude' / 'tasks' / 'completed'
    rd = active_dir / roadmap_name

    if not rd.exists():
        print(f"  active/에 로드맵 없음: {roadmap_name}")
        return 1

    pending = [f for f in (rd / 'pending').glob('*.md') if f.name != '.gitkeep'] if (rd / 'pending').exists() else []
    in_progress = [f for f in (rd / 'in_progress').glob('*.md') if f.name != '.gitkeep'] if (rd / 'in_progress').exists() else []

    if pending or in_progress:
        print(f"  미완료 태스크가 있음: pending={len(pending)}, in_progress={len(in_progress)}")
        return 1

    plan = rd / 'PLAN.md'
    if plan.exists():
        content = plan.read_text(encoding='utf-8')
        new_content = re.sub(
            r'^(## Phase \d+:.+?)(?<! ✅)$',
            r'\1 ✅',
            content,
            flags=re.MULTILINE,
        )
        if new_content != content:
            plan.write_text(new_content, encoding='utf-8')
            print(f"  PLAN.md Phase 헤더에 ✅ 추가")

    completed_dir.mkdir(parents=True, exist_ok=True)
    dest = completed_dir / roadmap_name
    if dest.exists():
        print(f"  완료 디렉토리에 이미 존재: {dest}")
        return 1

    shutil.move(str(rd), str(dest))
    print(f"  아카이빙 완료: active/{roadmap_name} → completed/{roadmap_name}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description='태스크 상태 전이 (active/{로드맵}/ 구조)')
    parser.add_argument('project_root', nargs='?', default='.',
                        help='Project root (default: current)')
    parser.add_argument('--roadmap', help='로드맵 이름 (없으면 자동 감지)')
    parser.add_argument('--complete-only', action='store_true',
                        help='완료만, 다음 시작 안 함')
    parser.add_argument('--task', help='완료할 태스크 파일명')
    parser.add_argument('--archive-roadmap', metavar='NAME', dest='archive_roadmap',
                        help='로드맵을 active → completed로 이동 + PLAN.md Phase 헤더에 ✅')
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()

    if args.archive_roadmap:
        return archive_roadmap(project_root, args.archive_roadmap)

    rd = find_roadmap_dir(project_root, args.roadmap)
    if not rd:
        print("  active/ 로드맵 없음")
        return 1

    completed = complete_task(rd, args.task)
    if not args.complete_only and completed:
        started = start_next_task(rd)
        if not started:
            print("\n  모든 태스크가 완료되었거나 blocked 상태입니다.")

    return 0


if __name__ == '__main__':
    sys.exit(main())
