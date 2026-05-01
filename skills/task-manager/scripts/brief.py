#!/usr/bin/env python3
"""task-manager /brief — .claude/tasks 상태 집계 및 브리핑.

Usage:
  python3 brief.py [project-root] [--json]

출력:
  기본: 사람이 읽는 마크다운 형식 브리핑 (LLM이 그대로 사용자에게 전달)
  --json: 구조화된 JSON (LLM이 케이스별 행동 결정에 사용)
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


def collect_state(project_root: Path) -> dict:
    tasks_dir = project_root / '.claude' / 'tasks'
    active_dir = tasks_dir / 'active'

    if not tasks_dir.exists():
        return {'case': 'uninitialized'}

    if not active_dir.exists() or not any(d.is_dir() for d in active_dir.iterdir()):
        return {'case': 'empty', 'roadmaps': [], 'git_log': _git_log(project_root)}

    roadmaps = []
    for rd in sorted([d for d in active_dir.iterdir() if d.is_dir()]):
        plan = rd / 'PLAN.md'
        pending = _list_md(rd / 'pending')
        in_progress = _list_md(rd / 'in_progress')
        completed = _list_md(rd / 'completed')

        # blocked_by (pending만)
        blocked = []
        for t in pending:
            content = t.read_text(encoding='utf-8')
            m = re.search(r'^- blocked_by:\s*(.+)$', content, re.MULTILINE)
            if m:
                blocker = m.group(1).strip()
                blocker_done = (rd / 'completed' / blocker).exists()
                blocked.append({
                    'task': t.name,
                    'blocker': blocker,
                    'unblocked': blocker_done,
                })

        total = len(pending) + len(in_progress) + len(completed)
        progress = (len(completed) / total * 100) if total > 0 else 0

        roadmaps.append({
            'name': rd.name,
            'plan_exists': plan.exists(),
            'pending': len(pending),
            'in_progress': len(in_progress),
            'completed': len(completed),
            'total': total,
            'progress_pct': round(progress, 1),
            'pending_files': [t.name for t in sorted(pending)],
            'in_progress_files': [t.name for t in sorted(in_progress)],
            'blocked': blocked,
            'roadmap_complete': total > 0 and len(pending) == 0 and len(in_progress) == 0,
        })

    case = 'all_complete' if all(r['roadmap_complete'] for r in roadmaps) else 'in_progress'
    return {
        'case': case,
        'roadmaps': roadmaps,
        'git_log': _git_log(project_root),
    }


def _list_md(d: Path) -> list[Path]:
    if not d.exists():
        return []
    return [f for f in d.glob('*.md') if f.name != '.gitkeep']


def _git_log(project_root: Path) -> list[str]:
    try:
        result = subprocess.run(
            ['git', '-C', str(project_root), 'log', '--oneline', '-5'],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0:
            return [line for line in result.stdout.strip().split('\n') if line]
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return []


def render_text(state: dict) -> str:
    case = state['case']
    lines = []

    if case == 'uninitialized':
        lines.append("Case 1: 미초기화 — .claude/tasks/ 없음")
        lines.append("→ python3 ~/.claude/skills/task-manager/scripts/init_project.py <project-root> 실행")
        return '\n'.join(lines)

    if case == 'empty':
        lines.append("Case 2: 활성 로드맵 없음 (active/ 비어있음)")
        lines.append("→ 새 로드맵 시작 (/prd 또는 PLAN 인터뷰)")
        if state.get('git_log'):
            lines.append("\n최근 커밋:")
            for l in state['git_log']:
                lines.append(f"  {l}")
        return '\n'.join(lines)

    lines.append(f"Case: {case}")
    lines.append("")
    for r in state['roadmaps']:
        marker = '✅' if r['roadmap_complete'] else '🔄'
        lines.append(f"{marker} {r['name']} — {r['progress_pct']}% ({r['completed']}/{r['total']})")
        if r['in_progress_files']:
            lines.append(f"  진행 중: {', '.join(r['in_progress_files'])}")
        if r['pending_files']:
            lines.append(f"  대기: {len(r['pending_files'])}건")
        if r['blocked']:
            for b in r['blocked']:
                status = '✓ unblocked' if b['unblocked'] else '✗ blocked'
                lines.append(f"  [{status}] {b['task']} ← blocked_by: {b['blocker']}")
        if not r['plan_exists']:
            lines.append(f"  ⚠️ PLAN.md 없음")
        lines.append("")

    if state['git_log']:
        lines.append("최근 커밋:")
        for l in state['git_log']:
            lines.append(f"  {l}")

    return '\n'.join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description='task-manager /brief — 상태 집계')
    parser.add_argument('project_root', nargs='?', default='.',
                        help='Project root (default: current)')
    parser.add_argument('--json', action='store_true',
                        help='JSON 출력 (LLM 해석용)')
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    state = collect_state(project_root)

    if args.json:
        print(json.dumps(state, ensure_ascii=False, indent=2))
    else:
        print(render_text(state))

    return 0


if __name__ == '__main__':
    sys.exit(main())
