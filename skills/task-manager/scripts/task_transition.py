#!/usr/bin/env python3
"""Manage task transitions using directory-based state."""

import argparse
import re
import shutil
from datetime import datetime
from pathlib import Path


def get_task_metadata(task_path: Path) -> dict:
    """Parse task file metadata (phase, size, blocked_by)."""
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
    """Check if task's dependencies are satisfied."""
    meta = get_task_metadata(task_path)
    if not meta['blocked_by']:
        return True

    blocker_name = meta['blocked_by'].strip()
    return (completed_dir / blocker_name).exists()


def select_next_task(pending_dir: Path, completed_dir: Path) -> Path | None:
    """Select next available task from pending/ (lowest number, unblocked)."""
    tasks = sorted(pending_dir.glob('*.md'))

    for task in tasks:
        if task.name == '.gitkeep':
            continue
        if is_unblocked(task, completed_dir):
            return task

    return None


def complete_task(project_root: Path, task_name: str = None):
    """Move task from in_progress/ to completed/."""
    queue_dir = project_root / '.claude' / 'tasks' / 'queue'
    in_progress_dir = queue_dir / 'in_progress'
    completed_dir = queue_dir / 'completed'

    if task_name:
        task_file = in_progress_dir / task_name
        if not task_file.exists():
            print(f"  in_progress/에 태스크 없음: {task_name}")
            return None
        tasks = [task_file]
    else:
        tasks = [f for f in in_progress_dir.glob('*.md') if f.name != '.gitkeep']

    if not tasks:
        print("  in_progress/에 태스크 없음")
        return None

    task_file = tasks[0]
    dest = completed_dir / task_file.name

    # Add completion date
    content = task_file.read_text(encoding='utf-8')
    if 'completed:' not in content:
        content = content.rstrip() + f"\n\ncompleted: {datetime.now().strftime('%Y-%m-%d')}\n"
        task_file.write_text(content, encoding='utf-8')

    shutil.move(str(task_file), str(dest))
    print(f"  완료: {task_file.name}")
    return task_file.name


def start_next_task(project_root: Path):
    """Move next pending task to in_progress/."""
    queue_dir = project_root / '.claude' / 'tasks' / 'queue'
    pending_dir = queue_dir / 'pending'
    in_progress_dir = queue_dir / 'in_progress'
    completed_dir = queue_dir / 'completed'

    # Check if in_progress/ already has a task
    current = [f for f in in_progress_dir.glob('*.md') if f.name != '.gitkeep']
    if current:
        print(f"  이미 진행 중: {current[0].name}")
        return None

    next_task = select_next_task(pending_dir, completed_dir)
    if not next_task:
        print("  pending/에 실행 가능한 태스크 없음")
        return None

    dest = in_progress_dir / next_task.name
    shutil.move(str(next_task), str(dest))
    print(f"  시작: {next_task.name}")
    return next_task.name


def task_transition(project_root: Path, complete_only: bool = False):
    """Complete current task and optionally start next."""
    claude_dir = project_root / '.claude'

    if not claude_dir.exists():
        print(f"  .claude/ 없음: {project_root}")
        return 1

    completed = complete_task(project_root)

    if complete_only:
        return 0

    if completed:
        started = start_next_task(project_root)
        if not started:
            print("\n  모든 태스크가 완료되었거나 blocked 상태입니다.")

    return 0


def main():
    parser = argparse.ArgumentParser(description='Task transition (directory-based)')
    parser.add_argument('project_root', nargs='?', default='.',
                        help='Project root (default: current)')
    parser.add_argument('--complete-only', action='store_true',
                        help='Only complete, do not start next')
    parser.add_argument('--task', help='Specific task filename to complete')
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()

    if args.task:
        complete_task(project_root, args.task)
    else:
        task_transition(project_root, args.complete_only)

    return 0


if __name__ == '__main__':
    exit(main())
